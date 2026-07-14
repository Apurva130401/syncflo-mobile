export interface User {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  role: 'admin' | 'agent' | 'viewer';
  permissions: string[];
  phone?: string;
}

export interface Conversation {
  id: string;
  contactId: string;
  contactName: string;
  status: 'ai' | 'human' | 'resolved';
  lastMessage?: string;
  unreadCount: number;
  assignedTo?: string;
  humanTakeoverStartedAt?: string;
  aiEnabled: boolean;
}

export interface Message {
  id: string;
  conversationId: string;
  content: string;
  senderId?: string;
  isFromUser: boolean;
  sentByAi: boolean;
  createdAt: string;
  status: 'sent' | 'delivered' | 'read' | 'failed';
}

export interface AuthSession {
  user: User;
  accessToken: string;
  refreshToken: string;
  expiresAt?: number;
}

export interface PushNotification {
  id: string;
  title: string;
  body: string;
  data: Record<string, any>;
  createdAt: string;
  read: boolean;
}

export interface TeamMember {
  id: string;
  name: string;
  role: 'admin' | 'agent' | 'viewer';
  isOnline: boolean;
  activeChats: number;
}

export interface BillingInfo {
  plan: string;
  nextBillingDate: string;
  usage: {
    messagesSent: number;
    messagesLimit: number;
    aiConversations: number;
    aiConversationsLimit: number;
  };
  seats: {
    active: number;
    limit: number;
  };
}
