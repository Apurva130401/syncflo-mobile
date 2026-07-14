import React, { useState } from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { useForm, Controller } from 'react-hook-form';
import { useAuth } from '../../hooks/useAuth';
import { useAuthStore } from '../../store/authStore';
import { Input } from '../../components/common/Input';
import { Button } from '../../components/common/Button';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { firstNameRules, lastNameRules, emailRules } from '../../utils/validation';
import { supabase } from '../../services/supabase';
import { apiClient } from '../../services/api';

export const ProfileScreen = ({ navigation }: any) => {
  const { user } = useAuth();
  const [saving, setSaving] = useState(false);

  const { control, handleSubmit } = useForm({
    defaultValues: {
      firstName: user?.firstName || '',
      lastName: user?.lastName || '',
      email: user?.email || '',
      phone: user?.phone || '',
    },
  });

  const onSubmit = async (data: any) => {
    setSaving(true);
    try {
      try {
        await apiClient.patch('/users/profile', {
          firstName: data.firstName,
          lastName: data.lastName,
          phone: data.phone,
        });
      } catch {
        const { error: authErr } = await supabase.auth.updateUser({
          data: {
            full_name: `${data.firstName} ${data.lastName}`.trim(),
            phone: data.phone,
          },
        });
        if (authErr) throw authErr;
      }

      if (user) {
        useAuthStore.getState().setUser({
          ...user,
          firstName: data.firstName,
          lastName: data.lastName,
          phone: data.phone,
        });
      }

      Alert.alert(
        'Profile Updated',
        'Your profile details have been updated successfully.'
      );
      navigation.goBack();
    } catch (err: any) {
      Alert.alert('Error', err.message || 'Failed to update profile');
    } finally {
      setSaving(false);
    }
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Avatar display section */}
      <View style={styles.avatarContainer}>
        <View style={styles.avatar}>
          <Text style={styles.avatarText}>
            {user?.firstName ? user.firstName.charAt(0).toUpperCase() : 'U'}
          </Text>
        </View>
        <Text style={styles.avatarLabel}>Tap to change avatar (unsupported)</Text>
      </View>

      <Controller
        control={control}
        name="firstName"
        rules={firstNameRules}
        render={({ field: { onChange, value }, fieldState: { error } }) => (
          <Input
            label="First Name"
            value={value}
            onChangeText={onChange}
            error={error?.message}
          />
        )}
      />

      <Controller
        control={control}
        name="lastName"
        rules={lastNameRules}
        render={({ field: { onChange, value }, fieldState: { error } }) => (
          <Input
            label="Last Name"
            value={value}
            onChangeText={onChange}
            error={error?.message}
          />
        )}
      />

      <Controller
        control={control}
        name="email"
        rules={emailRules}
        render={({ field: { onChange, value }, fieldState: { error } }) => (
          <Input
            label="Email Address"
            value={value}
            onChangeText={onChange}
            editable={false}
            error={error?.message}
          />
        )}
      />

      <Controller
        control={control}
        name="phone"
        render={({ field: { onChange, value }, fieldState: { error } }) => (
          <Input
            label="Phone Number"
            placeholder="+1234567890"
            keyboardType="phone-pad"
            value={value}
            onChangeText={onChange}
            error={error?.message}
          />
        )}
      />

      <Button
        title="Save Profile"
        onPress={handleSubmit(onSubmit)}
        loading={saving}
        style={styles.btn}
      />
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  content: {
    padding: spacing.lg,
  },
  avatarContainer: {
    alignItems: 'center',
    marginBottom: spacing.xl,
  },
  avatar: {
    width: 90,
    height: 90,
    borderRadius: 45,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: spacing.sm,
  },
  avatarText: {
    color: colors.textInverse,
    fontSize: typography.fontSizes.xxl,
    fontWeight: typography.weights.bold,
  },
  avatarLabel: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
  },
  btn: {
    marginTop: spacing.md,
  },
});

export default ProfileScreen;
