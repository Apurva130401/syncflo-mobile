import { Conversation, Message, User } from './index';

export interface LoginResponse {
  user: User;
  session: {
    access_token: string;
    refresh_token: string;
    expires_at?: number;
  };
}

export interface GetConversationsResponse {
  conversations: Conversation[];
}

export interface GetMessagesResponse {
  messages: Message[];
}

export interface TakeoverResponse {
  success: boolean;
  conversation: Conversation;
}

export interface SendMessageRequest {
  text: string;
}

export interface RegisterTokenRequest {
  token: string;
  platform: 'ios' | 'android';
}

export interface UpdatePreferencesRequest {
  push_enabled: boolean;
  marketing_emails: boolean;
  alert_on_handoff: boolean;
}
