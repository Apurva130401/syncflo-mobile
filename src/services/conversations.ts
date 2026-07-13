import { apiClient } from './api';
import { supabase } from './supabase';
import { Conversation, Message } from '../types';

export const conversationsService = {
  async getConversations(filters?: {
    status?: string;
    integrationId?: string;
  }): Promise<Conversation[]> {
    try {
      const response = await apiClient.get('/conversations', { params: filters });
      return response.data.conversations || response.data;
    } catch (apiErr) {
      let query = supabase.from('conversations').select('*');

      if (filters?.status) {
        query = query.eq('status', filters.status);
      }

      const { data, error } = await query;
      if (error) throw error;

      return (data || []).map((c: any) => ({
        id: c.id,
        contactId: c.contact_id || c.contactId || '',
        contactName: c.contact_name || c.contactName || '',
        status: c.status || 'ai',
        lastMessage: c.last_message || c.lastMessage || '',
        unreadCount: c.unread_count || c.unreadCount || 0,
        assignedTo: c.assigned_to || c.assignedTo || '',
        humanTakeoverStartedAt:
          c.human_takeover_started_at || c.humanTakeoverStartedAt || '',
        aiEnabled:
          c.ai_enabled !== undefined
            ? c.ai_enabled
            : c.aiEnabled !== undefined
            ? c.aiEnabled
            : true,
      }));
    }
  },

  async getConversationMessages(
    conversationId: string,
    limit?: number,
    before?: string
  ): Promise<Message[]> {
    try {
      const response = await apiClient.get(
        `/conversations/${conversationId}/messages`,
        {
          params: { limit, before },
        }
      );
      return response.data.messages || response.data;
    } catch (apiErr) {
      let query = supabase
        .from('messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: true });

      if (limit) {
        query = query.limit(limit);
      }

      const { data, error } = await query;
      if (error) throw error;

      return (data || []).map((m: any) => ({
        id: m.id,
        conversationId: m.conversation_id || m.conversationId || '',
        content: m.content || m.text || '',
        senderId: m.sender_id || m.senderId || '',
        isFromUser:
          m.is_from_user !== undefined
            ? m.is_from_user
            : m.isFromUser !== undefined
            ? m.isFromUser
            : m.sender_type === 'customer',
        sentByAi:
          m.sent_by_ai !== undefined
            ? m.sent_by_ai
            : m.sentByAi !== undefined
            ? m.sentByAi
            : m.sender_type === 'ai',
        createdAt: m.created_at || m.createdAt || '',
        status: m.status || 'sent',
      }));
    }
  },

  async sendMessage(conversationId: string, message: string): Promise<Message> {
    try {
      const response = await apiClient.post('/whatsapp/send', {
        conversationId,
        message,
      });
      return response.data.message || response.data;
    } catch (apiErr) {
      const { data: userData } = await supabase.auth.getUser();
      const senderId = userData.user?.id || 'agent';

      const mockMsg = {
        conversation_id: conversationId,
        content: message,
        sender_id: senderId,
        is_from_user: false,
        sent_by_ai: false,
        created_at: new Date().toISOString(),
        status: 'sent',
      };

      const { data, error } = await supabase
        .from('messages')
        .insert(mockMsg)
        .select()
        .single();

      if (error) throw error;

      await supabase
        .from('conversations')
        .update({
          last_message: message,
          human_takeover_started_at: new Date().toISOString(),
          status: 'human',
          ai_enabled: false,
        })
        .eq('id', conversationId);

      return {
        id: data.id,
        conversationId: data.conversation_id,
        content: data.content,
        senderId: data.sender_id,
        isFromUser: data.is_from_user,
        sentByAi: data.sent_by_ai,
        createdAt: data.created_at,
        status: data.status,
      };
    }
  },

  async takeoverConversation(conversationId: string): Promise<Conversation> {
    try {
      const response = await apiClient.post('/whatsapp/takeover', {
        conversationId,
        status: 'escalated',
      });
      return response.data.conversation || response.data;
    } catch (apiErr) {
      const { data, error } = await supabase
        .from('conversations')
        .update({
          status: 'human',
          ai_enabled: false,
          human_takeover_started_at: new Date().toISOString(),
        })
        .eq('id', conversationId)
        .select()
        .single();

      if (error) throw error;

      return {
        id: data.id,
        contactId: data.contact_id || data.contactId || '',
        contactName: data.contact_name || data.contactName || '',
        status: data.status,
        lastMessage: data.last_message || data.lastMessage || '',
        unreadCount: data.unread_count || data.unreadCount || 0,
        assignedTo: data.assigned_to || data.assignedTo || '',
        humanTakeoverStartedAt:
          data.human_takeover_started_at || data.humanTakeoverStartedAt || '',
        aiEnabled:
          data.ai_enabled !== undefined
            ? data.ai_enabled
            : data.aiEnabled !== undefined
            ? data.aiEnabled
            : false,
      };
    }
  },

  async resumeAI(conversationId: string): Promise<Conversation> {
    try {
      const response = await apiClient.post('/whatsapp/takeover', {
        conversationId,
        status: 'active',
      });
      return response.data.conversation || response.data;
    } catch (apiErr) {
      const { data, error } = await supabase
        .from('conversations')
        .update({
          status: 'ai',
          ai_enabled: true,
        })
        .eq('id', conversationId)
        .select()
        .single();

      if (error) throw error;

      return {
        id: data.id,
        contactId: data.contact_id || data.contactId || '',
        contactName: data.contact_name || data.contactName || '',
        status: data.status,
        lastMessage: data.last_message || data.lastMessage || '',
        unreadCount: data.unread_count || data.unreadCount || 0,
        assignedTo: data.assigned_to || data.assignedTo || '',
        humanTakeoverStartedAt:
          data.human_takeover_started_at || data.humanTakeoverStartedAt || '',
        aiEnabled:
          data.ai_enabled !== undefined
            ? data.ai_enabled
            : data.aiEnabled !== undefined
            ? data.aiEnabled
            : true,
      };
    }
  },

  async assignConversation(
    conversationId: string,
    userId: string
  ): Promise<Conversation> {
    try {
      const response = await apiClient.patch(`/conversations/${conversationId}`, {
        assignedTo: userId,
      });
      return response.data.conversation || response.data;
    } catch (apiErr) {
      const { data, error } = await supabase
        .from('conversations')
        .update({
          assigned_to: userId,
        })
        .eq('id', conversationId)
        .select()
        .single();

      if (error) throw error;

      return {
        id: data.id,
        contactId: data.contact_id || data.contactId || '',
        contactName: data.contact_name || data.contactName || '',
        status: data.status,
        lastMessage: data.last_message || data.lastMessage || '',
        unreadCount: data.unread_count || data.unreadCount || 0,
        assignedTo: data.assigned_to || data.assignedTo || '',
        humanTakeoverStartedAt:
          data.human_takeover_started_at || data.humanTakeoverStartedAt || '',
        aiEnabled:
          data.ai_enabled !== undefined
            ? data.ai_enabled
            : data.aiEnabled !== undefined
            ? data.aiEnabled
            : true,
      };
    }
  },
};
export default conversationsService;
