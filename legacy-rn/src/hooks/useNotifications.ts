import { useEffect } from 'react';
import { useNotificationStore } from '../store/notificationStore';
import { notificationsService } from '../services/notifications';

export const useNotifications = () => {
  const store = useNotificationStore();

  useEffect(() => {
    const receivedSub = notificationsService.addNotificationReceivedListener(
      (notification) => {
        store.addInAppNotification(notification);
      }
    );

    const responseSub =
      notificationsService.addNotificationResponseReceivedListener((response) => {
        console.log('User interacted with notification:', response);
      });

    return () => {
      receivedSub.remove();
      responseSub.remove();
    };
  }, []);

  return {
    pushToken: store.pushToken,
    pushNotificationsEnabled: store.pushNotificationsEnabled,
    notifyOnEscalation: store.notifyOnEscalation,
    notifyOnMessage: store.notifyOnMessage,
    notifyOnTeamUpdates: store.notifyOnTeamUpdates,
    soundEnabled: store.soundEnabled,
    hapticsEnabled: store.hapticsEnabled,
    unreadNotificationsCount: store.unreadNotificationsCount,
    inAppNotifications: store.inAppNotifications,
    setPushNotificationsEnabled: store.setPushNotificationsEnabled,
    setNotifyOnEscalation: store.setNotifyOnEscalation,
    setNotifyOnMessage: store.setNotifyOnMessage,
    setNotifyOnTeamUpdates: store.setNotifyOnTeamUpdates,
    setSoundEnabled: store.setSoundEnabled,
    setHapticsEnabled: store.setHapticsEnabled,
    clearNotifications: store.clearNotifications,
  };
};
export default useNotifications;
