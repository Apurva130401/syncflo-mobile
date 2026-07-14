import { useEffect, useState, useRef } from 'react';
import { Platform } from 'react-native';
import { useAuthStore } from '../store/authStore';
import { useNotificationStore } from '../store/notificationStore';
import { notificationsService } from '../services/notifications';
import { pushDeviceTokensService } from '../services/push-device-tokens';

export const usePushNotifications = () => {
  const user = useAuthStore((state) => state.user);
  const [isReady, setIsReady] = useState(false);
  const [lastNotification, setLastNotification] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);

  const tokenRef = useRef<string | null>(null);
  const prevUserRef = useRef<any>(null);

  useEffect(() => {
    if (Platform.OS === 'web') return; // push not supported on web

    const registerPush = async () => {
      try {
        const token = await notificationsService.registerForPushNotificationsAsync();
        if (token) {
          tokenRef.current = token;
          useNotificationStore.getState().setPushToken(token);

          if (user) {
            await pushDeviceTokensService.registerDeviceToken(
              token,
              Platform.OS === 'ios' ? 'ios' : 'android'
            );
          }
          setIsReady(true);
        } else {
          setError('Permission not granted or failed to fetch push token.');
        }
      } catch (err: any) {
        setError(err.message || 'Error configuring push notifications');
      }
    };

    registerPush();

    const receivedSub = notificationsService.addNotificationReceivedListener(
      (notification) => {
        setLastNotification(notification);
        useNotificationStore.getState().addInAppNotification(notification);
      }
    );

    const responseSub =
      notificationsService.addNotificationResponseReceivedListener((response) => {
        setLastNotification(response.notification);
      });

    return () => {
      receivedSub.remove();
      responseSub.remove();
    };
  }, []);

  useEffect(() => {
    const handleAuthChange = async () => {
      const token = tokenRef.current;
      if (!token) return;

      if (user && !prevUserRef.current) {
        try {
          await pushDeviceTokensService.registerDeviceToken(
            token,
            Platform.OS === 'ios' ? 'ios' : 'android'
          );
        } catch (err: any) {
          setError(err.message || 'Failed to register device token on login');
        }
      } else if (!user && prevUserRef.current) {
        try {
          await pushDeviceTokensService.unregisterDeviceToken(token);
        } catch (err: any) {
          setError(err.message || 'Failed to unregister device token on logout');
        }
      }

      prevUserRef.current = user;
    };

    handleAuthChange();
  }, [user]);

  return {
    isReady,
    lastNotification,
    error,
  };
};
export default usePushNotifications;
