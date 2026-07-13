import { NavigatorScreenParams } from '@react-navigation/native';

export type AuthStackParamList = {
  Splash: undefined;
  Login: undefined;
  Signup: undefined;
};

export type InboxStackParamList = {
  ConversationList: undefined;
  ChatThread: { conversationId: string };
  ConversationDetail: { conversationId: string };
};

export type SettingsStackParamList = {
  SettingsHome: undefined;
  Profile: undefined;
  NotificationPreferences: undefined;
  Billing: undefined;
};

export type AppTabParamList = {
  Inbox: NavigatorScreenParams<InboxStackParamList>;
  Analytics: undefined;
  Team: undefined;
  Settings: NavigatorScreenParams<SettingsStackParamList>;
  Support: undefined;
};

export type RootStackParamList = {
  Auth: NavigatorScreenParams<AuthStackParamList>;
  App: NavigatorScreenParams<AppTabParamList>;
};
