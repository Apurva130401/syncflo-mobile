import { create } from 'zustand';

interface NotificationState {
  pushToken: string | null;
  pushNotificationsEnabled: boolean;
  notifyOnEscalation: boolean;
  notifyOnMessage: boolean;
  notifyOnTeamUpdates: boolean;
  soundEnabled: boolean;
  hapticsEnabled: boolean;
  unreadNotificationsCount: number;
  inAppNotifications: any[];

  setPushToken: (token: string | null) => void;
  setPushNotificationsEnabled: (enabled: boolean) => void;
  setNotifyOnEscalation: (enabled: boolean) => void;
  setNotifyOnMessage: (enabled: boolean) => void;
  setNotifyOnTeamUpdates: (enabled: boolean) => void;
  setSoundEnabled: (enabled: boolean) => void;
  setHapticsEnabled: (enabled: boolean) => void;
  addInAppNotification: (notification: any) => void;
  clearNotifications: () => void;
}

export const useNotificationStore = create<NotificationState>((set) => ({
  pushToken: null,
  pushNotificationsEnabled: true,
  notifyOnEscalation: true,
  notifyOnMessage: true,
  notifyOnTeamUpdates: true,
  soundEnabled: true,
  hapticsEnabled: true,
  unreadNotificationsCount: 0,
  inAppNotifications: [],

  setPushToken: (token) => set({ pushToken: token }),
  setPushNotificationsEnabled: (enabled) =>
    set({ pushNotificationsEnabled: enabled }),
  setNotifyOnEscalation: (enabled) => set({ notifyOnEscalation: enabled }),
  setNotifyOnMessage: (enabled) => set({ notifyOnMessage: enabled }),
  setNotifyOnTeamUpdates: (enabled) => set({ notifyOnTeamUpdates: enabled }),
  setSoundEnabled: (enabled) => set({ soundEnabled: enabled }),
  setHapticsEnabled: (enabled) => set({ hapticsEnabled: enabled }),
  addInAppNotification: (notification) =>
    set((state) => ({
      inAppNotifications: [notification, ...state.inAppNotifications],
      unreadNotificationsCount: state.unreadNotificationsCount + 1,
    })),
  clearNotifications: () =>
    set({ inAppNotifications: [], unreadNotificationsCount: 0 }),
}));
export default useNotificationStore;
