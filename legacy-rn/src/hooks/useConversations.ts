import { useEffect } from 'react';
import { useConversationStore } from '../store/conversationStore';
import { conversationsService } from '../services/conversations';
import { supabase } from '../services/supabase';
import { apiClient } from '../services/api';
import { Message } from '../types';

export const useConversations = (activeConversationId?: string | null) => {
  const store = useConversationStore();

  const fetchConversations = async () => {
    useConversationStore.setState({ isLoadingConversations: true });
    try {
      const data = await conversationsService.getConversations();
      store.setConversations(data);
    } catch (err) {
      console.warn('Failed to fetch conversations:', err);
    } finally {
      useConversationStore.setState({ isLoadingConversations: false });
    }
  };

  const fetchMessages = async (conversationId: string) => {
    useConversationStore.setState({ isLoadingMessages: true });
    try {
      const data = await conversationsService.getConversationMessages(
        conversationId
      );
      useConversationStore.setState({ messages: data });
    } catch (err) {
      console.warn('Failed to fetch messages:', err);
    } finally {
      useConversationStore.setState({ isLoadingMessages: false });
    }
  };

  const selectConversation = (conversationId: string | null) => {
    if (!conversationId) {
      store.selectConversation(null);
      useConversationStore.setState({ messages: [] });
      return;
    }
    const conv =
      store.conversations.find((c) => c.id === conversationId) || null;
    store.selectConversation(conv);
    if (conv) {
      fetchMessages(conversationId);
    }
  };

  const sendMessage = async (conversationId: string, text: string) => {
    try {
      const newMessage = await conversationsService.sendMessage(
        conversationId,
        text
      );
      store.addMessage(newMessage);
    } catch (err) {
      console.error('Failed to send message:', err);
      throw err;
    }
  };

  const takeoverConversation = async (conversationId: string) => {
    try {
      await conversationsService.takeoverConversation(conversationId);
      store.updateConversationStatus(conversationId, 'human');
    } catch (err) {
      console.error('Failed to takeover conversation:', err);
    }
  };

  const releaseConversation = async (conversationId: string) => {
    try {
      await conversationsService.resumeAI(conversationId);
      store.updateConversationStatus(conversationId, 'ai');
    } catch (err) {
      console.error('Failed to release conversation:', err);
    }
  };

  const resolveConversation = async (conversationId: string) => {
    try {
      await apiClient.patch(`/conversations/${conversationId}`, {
        status: 'resolved',
      });
      store.updateConversationStatus(conversationId, 'resolved');
    } catch (err) {
      try {
        await supabase
          .from('conversations')
          .update({ status: 'resolved' })
          .eq('id', conversationId);
        store.updateConversationStatus(conversationId, 'resolved');
      } catch (dbErr) {
        console.error('Failed to resolve conversation:', dbErr);
      }
    }
  };

  const assignConversation = async (
    conversationId: string,
    userId: string | null
  ) => {
    try {
      if (userId) {
        await conversationsService.assignConversation(conversationId, userId);
      }
      store.assignConversation(conversationId, userId);
    } catch (err) {
      console.error('Failed to assign conversation:', err);
    }
  };

  useEffect(() => {
    if (!activeConversationId) return;

    const channel = supabase
      .channel(`room-${activeConversationId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `conversation_id=eq.${activeConversationId}`,
        },
        (payload) => {
          const raw = payload.new as any;
          const msg: Message = {
            id: raw.id,
            conversationId: raw.conversation_id,
            content: raw.content || raw.text || '',
            senderId: raw.sender_id || '',
            isFromUser: raw.is_from_user ?? raw.sender_type === 'customer',
            sentByAi: raw.sent_by_ai ?? raw.sender_type === 'ai',
            createdAt: raw.created_at,
            status: raw.status || 'sent',
          };
          store.addMessage(msg);
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [activeConversationId]);

  useEffect(() => {
    const channel = supabase
      .channel('conversations-list')
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: 'conversations',
        },
        () => {
          fetchConversations();
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, []);

  return {
    conversations: store.conversations,
    selectedConversation: store.selectedConversation,
    messages: store.messages,
    isLoadingConversations: store.isLoadingConversations,
    isLoadingMessages: store.isLoadingMessages,
    fetchConversations,
    fetchMessages,
    selectConversation,
    sendMessage,
    takeoverConversation,
    releaseConversation,
    resolveConversation,
    assignConversation,
  };
};
export default useConversations;
