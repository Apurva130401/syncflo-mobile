import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';

// Only set notification handler on native platforms — crashes on web
if (Platform.OS !== 'web') {
  Notifications.setNotificationHandler({
    handleNotification: async () => ({
      shouldShowAlert: true,
      shouldPlaySound: true,
      shouldSetBadge: true,
      shouldShowBanner: true,
      shouldShowList: true,
    }),
  });
}

// Stub subscription for web so removeListener calls don't throw
const noopSub = { remove: () => {} };

export const notificationsService = {
  async registerForPushNotificationsAsync(): Promise<string | null> {
    if (Platform.OS === 'web') return null;

    try {
      const { status: existingStatus } = await Notifications.getPermissionsAsync();
      let finalStatus = existingStatus;

      if (existingStatus !== 'granted') {
        const { status } = await Notifications.requestPermissionsAsync();
        finalStatus = status;
      }

      if (finalStatus !== 'granted') {
        console.warn('Push notification permission not granted.');
        return null;
      }

      const tokenData = await Notifications.getExpoPushTokenAsync();
      return tokenData.data;
    } catch (error) {
      console.warn('Error registering for push notifications:', error);
      return null;
    }
  },

  addNotificationReceivedListener(callback: (notification: Notifications.Notification) => void) {
    if (Platform.OS === 'web') return noopSub;
    return Notifications.addNotificationReceivedListener(callback);
  },

  addNotificationResponseReceivedListener(callback: (response: Notifications.NotificationResponse) => void) {
    if (Platform.OS === 'web') return noopSub;
    return Notifications.addNotificationResponseReceivedListener(callback);
  },
};
