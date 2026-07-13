import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  SafeAreaView,
  KeyboardAvoidingView,
  Platform,
  ScrollView,
  Alert,
} from 'react-native';
import { useForm, Controller } from 'react-hook-form';
import { useAuth } from '../../hooks/useAuth';
import { Input } from '../../components/common/Input';
import { Button } from '../../components/common/Button';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { emailRules, passwordRules, firstNameRules, lastNameRules } from '../../utils/validation';
import { Zap } from 'lucide-react-native';

export const SignupScreen = ({ navigation }: any) => {
  const { signup, isLoading, error } = useAuth();
  const [success, setSuccess] = useState(false);

  const { control, handleSubmit, getValues } = useForm({
    defaultValues: {
      firstName: '',
      lastName: '',
      email: '',
      password: '',
      confirmPassword: '',
    },
  });

  const onSubmit = async (data: any) => {
    if (data.password !== data.confirmPassword) {
      Alert.alert('Error', 'Passwords do not match');
      return;
    }
    try {
      await signup(data.email, data.password, data.firstName, data.lastName);
      setSuccess(true);
      Alert.alert(
        'Sign Up Complete',
        'Verification link sent! Please check your email to complete registration.',
        [{ text: 'Sign In', onPress: () => navigation.navigate('Login') }]
      );
    } catch (e) {
      // Error handled by store state
    }
  };

  return (
    <SafeAreaView style={styles.container}>
      <KeyboardAvoidingView
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        style={styles.keyboardView}
      >
        <ScrollView contentContainerStyle={styles.scrollContent}>
          <View style={styles.header}>
            <Zap size={40} color={colors.primary} />
            <Text style={styles.title}>Create Account</Text>
            <Text style={styles.subtitle}>Join your team on Syncflo</Text>
          </View>

          {error && <Text style={styles.errorText}>{error}</Text>}

          <View style={styles.form}>
            <Controller
              control={control}
              name="firstName"
              rules={firstNameRules}
              render={({ field: { onChange, value }, fieldState: { error } }) => (
                <Input
                  label="First Name"
                  placeholder="John"
                  autoCapitalize="words"
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
                  placeholder="Doe"
                  autoCapitalize="words"
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
                  placeholder="name@company.com"
                  keyboardType="email-address"
                  autoCapitalize="none"
                  value={value}
                  onChangeText={onChange}
                  error={error?.message}
                />
              )}
            />

            <Controller
              control={control}
              name="password"
              rules={passwordRules}
              render={({ field: { onChange, value }, fieldState: { error } }) => (
                <Input
                  label="Password"
                  placeholder="Min. 6 characters"
                  secureTextEntry
                  autoCapitalize="none"
                  value={value}
                  onChangeText={onChange}
                  error={error?.message}
                />
              )}
            />

            <Controller
              control={control}
              name="confirmPassword"
              rules={{
                required: 'Please confirm your password',
                validate: (val) => val === getValues('password') || 'Passwords do not match',
              }}
              render={({ field: { onChange, value }, fieldState: { error } }) => (
                <Input
                  label="Confirm Password"
                  placeholder="Re-enter password"
                  secureTextEntry
                  autoCapitalize="none"
                  value={value}
                  onChangeText={onChange}
                  error={error?.message}
                />
              )}
            />

            <Button
              title="Sign Up"
              onPress={handleSubmit(onSubmit)}
              loading={isLoading}
              style={styles.button}
            />

            <View style={styles.footer}>
              <Text style={styles.footerText}>Already have an account? </Text>
              <TouchableOpacity onPress={() => navigation.navigate('Login')}>
                <Text style={styles.link}>Sign In</Text>
              </TouchableOpacity>
            </View>
          </View>
        </ScrollView>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  keyboardView: {
    flex: 1,
  },
  scrollContent: {
    flexGrow: 1,
    justifyContent: 'center',
    padding: spacing.xl,
  },
  header: {
    alignItems: 'center',
    marginBottom: spacing.xxl,
  },
  title: {
    color: colors.text,
    fontSize: typography.fontSizes.xxl,
    fontWeight: typography.weights.bold,
    marginTop: spacing.md,
  },
  subtitle: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.sm,
    marginTop: spacing.xs,
  },
  form: {
    width: '100%',
  },
  errorText: {
    color: colors.error,
    fontSize: typography.fontSizes.sm,
    textAlign: 'center',
    marginBottom: spacing.md,
    fontWeight: typography.weights.medium,
  },
  button: {
    marginTop: spacing.md,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    marginTop: spacing.xl,
  },
  footerText: {
    color: colors.textSecondary,
    fontSize: typography.fontSizes.sm,
  },
  link: {
    color: colors.primary,
    fontWeight: typography.weights.bold,
    fontSize: typography.fontSizes.sm,
  },
});
export default SignupScreen;
