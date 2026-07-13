import React from 'react';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import {
  AppTabParamList,
  InboxStackParamList,
  SettingsStackParamList,
} from './types';
import { colors } from '../theme/colors';
import {
  MessageSquare,
  BarChart2,
  Users,
  Settings,
  HelpCircle,
} from 'lucide-react-native';

// Inbox Screen Imports
import ConversationListScreen from '../screens/inbox/ConversationListScreen';
import ChatThreadScreen from '../screens/inbox/ChatThreadScreen';
import ConversationDetailScreen from '../screens/inbox/ConversationDetailScreen';

// Settings Screen Imports
import SettingsHomeScreen from '../screens/settings/SettingsHomeScreen';
import ProfileScreen from '../screens/settings/ProfileScreen';
import NotificationPreferencesScreen from '../screens/settings/NotificationPreferencesScreen';
import BillingScreen from '../screens/settings/BillingScreen';

// Other Screen Imports
import AnalyticsScreen from '../screens/analytics/AnalyticsScreen';
import TeamScreen from '../screens/team/TeamScreen';
import SupportScreen from '../screens/support/SupportScreen';

const Tab = createBottomTabNavigator<AppTabParamList>();
const InboxStack = createNativeStackNavigator<InboxStackParamList>();
const SettingsStack = createNativeStackNavigator<SettingsStackParamList>();

const screenOptions = {
  headerStyle: { backgroundColor: colors.background },
  headerTintColor: colors.text,
  headerShadowVisible: false,
  contentStyle: { backgroundColor: colors.background },
};

const InboxNavigator = () => (
  <InboxStack.Navigator screenOptions={screenOptions}>
    <InboxStack.Screen
      name="ConversationList"
      component={ConversationListScreen}
      options={{ title: 'Syncflo Chats' }}
    />
    <InboxStack.Screen
      name="ChatThread"
      component={ChatThreadScreen}
      options={{ title: 'Chat' }}
    />
    <InboxStack.Screen
      name="ConversationDetail"
      component={ConversationDetailScreen}
      options={{ title: 'Conversation Info' }}
    />
  </InboxStack.Navigator>
);

const SettingsNavigator = () => (
  <SettingsStack.Navigator screenOptions={screenOptions}>
    <SettingsStack.Screen
      name="SettingsHome"
      component={SettingsHomeScreen}
      options={{ title: 'Settings' }}
    />
    <SettingsStack.Screen
      name="Profile"
      component={ProfileScreen}
      options={{ title: 'Profile' }}
    />
    <SettingsStack.Screen
      name="NotificationPreferences"
      component={NotificationPreferencesScreen}
      options={{ title: 'Notification Settings' }}
    />
    <SettingsStack.Screen
      name="Billing"
      component={BillingScreen}
      options={{ title: 'Billing & Usage' }}
    />
  </SettingsStack.Navigator>
);

export const AppNavigator = () => {
  return (
    <Tab.Navigator
      screenOptions={{
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.textMuted,
        tabBarStyle: {
          backgroundColor: colors.surface,
          borderTopColor: colors.border,
          height: 60,
          paddingBottom: 8,
          paddingTop: 8,
        },
        headerStyle: { backgroundColor: colors.background },
        headerTintColor: colors.text,
        headerShadowVisible: false,
      }}
    >
      <Tab.Screen
        name="Inbox"
        component={InboxNavigator}
        options={{
          headerShown: false,
          tabBarIcon: ({ color, size }) => (
            <MessageSquare size={size} color={color} />
          ),
        }}
      />
      <Tab.Screen
        name="Analytics"
        component={AnalyticsScreen}
        options={{
          tabBarIcon: ({ color, size }) => (
            <BarChart2 size={size} color={color} />
          ),
        }}
      />
      <Tab.Screen
        name="Team"
        component={TeamScreen}
        options={{
          tabBarIcon: ({ color, size }) => <Users size={size} color={color} />,
        }}
      />
      <Tab.Screen
        name="Support"
        component={SupportScreen}
        options={{
          tabBarIcon: ({ color, size }) => (
            <HelpCircle size={size} color={color} />
          ),
        }}
      />
      <Tab.Screen
        name="Settings"
        component={SettingsNavigator}
        options={{
          headerShown: false,
          tabBarIcon: ({ color, size }) => (
            <Settings size={size} color={color} />
          ),
        }}
      />
    </Tab.Navigator>
  );
};
export default AppNavigator;
