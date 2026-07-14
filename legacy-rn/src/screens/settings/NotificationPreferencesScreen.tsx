import React from 'react';
import { View, Text, StyleSheet, Switch, ScrollView } from 'react-native';
import { useNotifications } from '../../hooks/useNotifications';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';

export const NotificationPreferencesScreen = () => {
  const {
    pushNotificationsEnabled,
    notifyOnEscalation,
    notifyOnMessage,
    notifyOnTeamUpdates,
    soundEnabled,
    hapticsEnabled,
    setPushNotificationsEnabled,
    setNotifyOnEscalation,
    setNotifyOnMessage,
    setNotifyOnTeamUpdates,
    setSoundEnabled,
    setHapticsEnabled,
  } = useNotifications();

  const renderToggle = (
    label: string,
    sub: string,
    val: boolean,
    onValChange: (v: boolean) => void
  ) => (
    <View style={styles.row}>
      <View style={styles.rowLeft}>
        <Text style={styles.title}>{label}</Text>
        <Text style={styles.subtitle}>{sub}</Text>
      </View>
      <Switch
        value={val}
        onValueChange={onValChange}
        trackColor={{ false: colors.border, true: colors.primary }}
        thumbColor={colors.text}
      />
    </View>
  );

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <Text style={styles.sectionHeader}>GENERAL SETTINGS</Text>
      <View style={styles.section}>
        {renderToggle(
          'Push Notifications',
          'Enable or disable push notifications entirely',
          pushNotificationsEnabled,
          setPushNotificationsEnabled
        )}
      </View>

      <Text style={styles.sectionHeader}>NOTIFY ON</Text>
      <View style={styles.section}>
        {renderToggle(
          'New Escalation',
          'Get alerted when a bot hands over a conversation',
          notifyOnEscalation,
          setNotifyOnEscalation
        )}
        {renderToggle(
          'New Message',
          'Get alerted when customer replies inside your chats',
          notifyOnMessage,
          setNotifyOnMessage
        )}
        {renderToggle(
          'Team Updates',
          'Get alerted when teammates assign chats or change status',
          notifyOnTeamUpdates,
          setNotifyOnTeamUpdates
        )}
      </View>

      <Text style={styles.sectionHeader}>ALERTS SYSTEM</Text>
      <View style={styles.section}>
        {renderToggle(
          'Sound Enabled',
          'Play alerts sound on incoming notifications',
          soundEnabled,
          setSoundEnabled
        )}
        {renderToggle(
          'Haptics Feedback',
          'Vibrate device on incoming notifications',
          hapticsEnabled,
          setHapticsEnabled
        )}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    paddingBottom: spacing.xl,
  },
  sectionHeader: {
    color: colors.primary,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.bold,
    marginTop: spacing.lg,
    marginHorizontal: spacing.lg,
    marginBottom: spacing.xs,
    letterSpacing: 1,
  },
  section: {
    backgroundColor: colors.surface,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: colors.border,
    paddingHorizontal: spacing.lg,
  },
  row: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing.md,
    borderBottomWidth: 1,
    borderColor: colors.border,
  },
  rowLeft: {
    flex: 1,
    marginRight: spacing.md,
  },
  title: {
    color: colors.text,
    fontSize: typography.fontSizes.md,
    fontWeight: typography.weights.bold,
    marginBottom: 2,
  },
  subtitle: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
  },
});

export default NotificationPreferencesScreen;
