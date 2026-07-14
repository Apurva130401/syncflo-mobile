import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ScrollView } from 'react-native';
import { useAuth } from '../../hooks/useAuth';
import { Button } from '../../components/common/Button';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { User, Bell, CreditCard, ChevronRight } from 'lucide-react-native';

export const SettingsHomeScreen = ({ navigation }: any) => {
  const { user, logout } = useAuth();

  const handleSignOut = () => {
    logout();
  };

  const renderOption = (icon: any, label: string, onPress: () => void) => (
    <TouchableOpacity
      activeOpacity={0.7}
      style={styles.option}
      onPress={onPress}
    >
      <View style={styles.optionLeft}>
        {icon}
        <Text style={styles.optionLabel}>{label}</Text>
      </View>
      <ChevronRight size={16} color={colors.textMuted} />
    </TouchableOpacity>
  );

  return (
    <ScrollView style={styles.container}>
      <View style={styles.profileSection}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>
            {user?.firstName ? user.firstName.charAt(0).toUpperCase() : 'U'}
          </Text>
        </View>
        <Text style={styles.profileName}>
          {user ? `${user.firstName} ${user.lastName}` : 'Syncflo Agent'}
        </Text>
        <Text style={styles.profileEmail}>{user?.email || ''}</Text>
        <View style={styles.roleBadge}>
          <Text style={styles.roleText}>
            {user?.role?.toUpperCase() || 'AGENT'}
          </Text>
        </View>
      </View>

      <View style={styles.optionsSection}>
        {renderOption(
          <User size={18} color={colors.primary} />,
          'Edit Profile',
          () => navigation.navigate('Profile')
        )}
        {renderOption(
          <Bell size={18} color={colors.primary} />,
          'Notifications',
          () => navigation.navigate('NotificationPreferences')
        )}
        {renderOption(
          <CreditCard size={18} color={colors.primary} />,
          'Billing & Subscription',
          () => navigation.navigate('Billing')
        )}
      </View>

      <View style={styles.logoutSection}>
        <Button
          title="Sign Out"
          onPress={handleSignOut}
          variant="danger"
          style={styles.logoutBtn}
        />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  profileSection: {
    alignItems: 'center',
    paddingVertical: spacing.xxl,
    borderBottomWidth: 1,
    borderColor: colors.border,
    backgroundColor: colors.surface,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.md,
  },
  avatarText: {
    color: colors.textInverse,
    fontSize: typography.fontSizes.xxl,
    fontWeight: typography.weights.bold,
  },
  profileName: {
    color: colors.text,
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.weights.bold,
    marginBottom: 4,
  },
  profileEmail: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.sm,
    marginBottom: spacing.md,
  },
  roleBadge: {
    backgroundColor: 'rgba(245, 158, 11, 0.15)',
    borderColor: 'rgba(245, 158, 11, 0.3)',
    borderWidth: 1,
    paddingHorizontal: spacing.md,
    paddingVertical: 4,
    borderRadius: 12,
  },
  roleText: {
    color: colors.accent,
    fontSize: 10,
    fontWeight: 'bold',
  },
  optionsSection: {
    marginTop: spacing.lg,
    backgroundColor: colors.surface,
    borderTopWidth: 1,
    borderBottomWidth: 1,
    borderColor: colors.border,
  },
  option: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing.lg,
    paddingHorizontal: spacing.lg,
    borderBottomWidth: 1,
    borderColor: colors.border,
  },
  optionLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  optionLabel: {
    color: colors.text,
    fontSize: typography.fontSizes.md,
    fontWeight: typography.weights.medium,
    marginLeft: spacing.md,
  },
  logoutSection: {
    padding: spacing.lg,
    marginTop: spacing.xl,
  },
  logoutBtn: {
    width: '100%',
  },
});
export default SettingsHomeScreen;
