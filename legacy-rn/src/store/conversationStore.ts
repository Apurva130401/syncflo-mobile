import { create } from 'zustand';
import { Conversation, Message } from '../types';

interface ConversationState {
  conversations: Conversation[];
  selectedConversation: Conversation | null;
  messages: Message[];
  isLoadingConversations: boolean;
  isLoadingMessages: boolean;

  setConversations: (conversations: Conversation[]) => void;
  selectConversation: (conversation: Conversation | null) => void;
  addMessage: (message: Message) => void;
  updateConversationStatus: (
    conversationId: string,
    status: Conversation['status']
  ) => void;
  assignConversation: (conversationId: string, userId: string | null) => void;
}

export const useConversationStore = create<ConversationState>((set) => ({
  conversations: [],
  selectedConversation: null,
  messages: [],
  isLoadingConversations: false,
  isLoadingMessages: false,

  setConversations: (conversations) => set({ conversations }),
  selectConversation: (conversation) =>
    set({ selectedConversation: conversation, messages: [] }),
  addMessage: (message) =>
    set((state) => {
      const messages =
        state.selectedConversation &&
        state.selectedConversation.id === message.conversationId
          ? [...state.messages, message]
          : state.messages;

      const conversations = state.conversations.map((c) =>
        c.id === message.conversationId
          ? {
              ...c,
              lastMessage: message.content,
              humanTakeoverStartedAt: message.createdAt,
              unreadCount:
                state.selectedConversation &&
                state.selectedConversation.id === message.conversationId
                  ? c.unreadCount
                  : c.unreadCount + 1,
            }
          : c
      );

      return { messages, conversations };
    }),

  updateConversationStatus: (conversationId, status) =>
    set((state) => {
      const conversations = state.conversations.map((c) =>
        c.id === conversationId ? { ...c, status } : c
      );
      const selectedConversation =
        state.selectedConversation &&
        state.selectedConversation.id === conversationId
          ? { ...state.selectedConversation, status }
          : state.selectedConversation;

      return { conversations, selectedConversation };
    }),

  assignConversation: (conversationId, userId) =>
    set((state) => {
      const conversations = state.conversations.map((c) =>
        c.id === conversationId ? { ...c, assignedTo: userId || undefined } : c
      );
      const selectedConversation =
        state.selectedConversation &&
        state.selectedConversation.id === conversationId
          ? { ...state.selectedConversation, assignedTo: userId || undefined }
          : state.selectedConversation;

      return { conversations, selectedConversation };
    }),
}));
export default useConversationStore;
