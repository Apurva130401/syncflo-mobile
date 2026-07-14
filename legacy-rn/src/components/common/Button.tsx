import React from 'react';
import {
  TouchableOpacity,
  Text,
  ActivityIndicator,
  StyleSheet,
  ViewStyle,
  TextStyle,
} from 'react-native';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';

interface ButtonProps {
  title: string;
  onPress: () => void;
  variant?: 'primary' | 'secondary' | 'outline' | 'text' | 'danger';
  size?: 'small' | 'medium' | 'large';
  loading?: boolean;
  disabled?: boolean;
  style?: ViewStyle;
  textStyle?: TextStyle;
}

export const Button: React.FC<ButtonProps> = ({
  title,
  onPress,
  variant = 'primary',
  size = 'medium',
  loading = false,
  disabled = false,
  style,
  textStyle,
}) => {
  const getButtonStyles = () => {
    const base = styles.button;
    const variantStyles = styles[variant];
    const sizeStyles = styles[size];
    const stateStyles = disabled || loading ? styles.disabled : {};
    return [base, variantStyles, sizeStyles, stateStyles, style];
  };

  const getTextStyles = () => {
    const base = styles.text;
    const variantText = styles[`${variant}Text` as keyof typeof styles] || {};
    const sizeText = styles[`${size}Text` as keyof typeof styles] || {};
    return [base, variantText, sizeText, textStyle];
  };

  return (
    <TouchableOpacity
      activeOpacity={0.75}
      onPress={onPress}
      disabled={disabled || loading}
      style={getButtonStyles()}
    >
      {loading ? (
        <ActivityIndicator
          color={
            variant === 'primary' || variant === 'danger'
              ? colors.textInverse
              : colors.primary
          }
        />
      ) : (
        <Text style={getTextStyles()}>{title}</Text>
      )}
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  button: {
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  primary: {
    backgroundColor: colors.primary,
  },
  secondary: {
    backgroundColor: colors.surfaceLight,
  },
  outline: {
    backgroundColor: 'transparent',
    borderWidth: 1.5,
    borderColor: colors.primary,
  },
  text: {
    backgroundColor: 'transparent',
  },
  danger: {
    backgroundColor: colors.error,
  },
  disabled: {
    opacity: 0.5,
  },
  small: {
    paddingVertical: spacing.xs,
    paddingHorizontal: spacing.md,
  },
  medium: {
    paddingVertical: spacing.sm + 2,
    paddingHorizontal: spacing.lg,
  },
  large: {
    paddingVertical: spacing.md,
    paddingHorizontal: spacing.xl,
  },
  textStyle: {
    fontSize: typography.fontSizes.md,
    fontWeight: typography.weights.semibold,
  },
  primaryText: {
    color: colors.textInverse,
    fontWeight: typography.weights.bold,
  },
  secondaryText: {
    color: colors.text,
  },
  outlineText: {
    color: colors.primary,
    fontWeight: typography.weights.bold,
  },
  textText: {
    color: colors.primary,
  },
  dangerText: {
    color: colors.text,
    fontWeight: typography.weights.bold,
  },
  smallText: {
    fontSize: typography.fontSizes.sm,
  },
  mediumText: {
    fontSize: typography.fontSizes.md,
  },
  largeText: {
    fontSize: typography.fontSizes.lg,
  },
});
export default Button;
