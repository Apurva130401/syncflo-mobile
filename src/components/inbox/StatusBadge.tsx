import React from 'react';
import { View, Text, StyleSheet, ViewStyle, TextStyle } from 'react-native';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';

interface StatusBadgeProps {
  status: 'ai' | 'human' | 'resolved';
  style?: ViewStyle;
}

export const StatusBadge: React.FC<StatusBadgeProps> = ({ status, style }) => {
  const getBadgeStyle = () => {
    switch (status) {
      case 'ai':
        return [styles.badge, styles.aiBadge, style];
      case 'human':
        return [styles.badge, styles.humanBadge, style];
      case 'resolved':
        return [styles.badge, styles.resolvedBadge, style];
      default:
        return [styles.badge, style];
    }
  };

  const getTextStyle = () => {
    switch (status) {
      case 'ai':
        return styles.aiText;
      case 'human':
        return styles.humanText;
      case 'resolved':
        return styles.resolvedText;
      default:
        return styles.text;
    }
  };

  const getLabel = () => {
    switch (status) {
      case 'ai':
        return 'AI Assistant';
      case 'human':
        return 'Human Agent';
      case 'resolved':
        return 'Resolved';
      default:
        return status;
    }
  };

  return (
    <View style={getBadgeStyle()}>
      <Text style={getTextStyle()}>{getLabel()}</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  badge: {
    paddingHorizontal: spacing.sm,
    paddingVertical: 2,
    borderRadius: 4,
    alignSelf: 'flex-start',
  },
  aiBadge: {
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(16, 185, 129, 0.3)',
  },
  humanBadge: {
    backgroundColor: 'rgba(245, 158, 11, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(245, 158, 11, 0.3)',
  },
  resolvedBadge: {
    backgroundColor: 'rgba(156, 163, 175, 0.15)',
    borderWidth: 1,
    borderColor: 'rgba(156, 163, 175, 0.3)',
  },
  text: {
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.semibold,
  },
  aiText: {
    color: colors.success,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.bold,
  },
  humanText: {
    color: colors.accent,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.bold,
  },
  resolvedText: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.semibold,
  },
});
export default StatusBadge;
