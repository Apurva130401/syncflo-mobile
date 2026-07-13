import React, { useEffect } from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { colors } from '../../theme/colors';
import { typography } from '../../theme/typography';
import { useAuthStore } from '../../store/authStore';
import { Zap } from 'lucide-react-native';

export const SplashScreen = ({ navigation }: any) => {
  const user = useAuthStore((state) => state.user);

  useEffect(() => {
    if (!navigation) return;
    const timer = setTimeout(() => {
      if (!user) {
        navigation.navigate('Login');
      }
    }, 1500);

    return () => clearTimeout(timer);
  }, [user, navigation]);

  return (
    <View style={styles.container}>
      <View style={styles.logoContainer}>
        <Zap size={64} color={colors.primary} />
        <Text style={styles.title}>Syncflo</Text>
        <Text style={styles.subtitle}>WhatsApp Business AI Companion</Text>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  logoContainer: {
    alignItems: 'center',
  },
  title: {
    color: colors.text,
    fontSize: typography.fontSizes.xxxl,
    fontWeight: typography.weights.bold,
    marginTop: 16,
    letterSpacing: 1,
  },
  subtitle: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.sm,
    marginTop: 8,
  },
});
export default SplashScreen;
