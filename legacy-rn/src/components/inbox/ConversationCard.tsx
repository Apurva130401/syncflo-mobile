import React from 'react';
import { TouchableOpacity, View, Text, StyleSheet } from 'react-native';
import { Conversation } from '../../types';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { formatShortDate } from '../../utils/formatting';
import { StatusBadge } from './StatusBadge';

interface ConversationCardProps {
  conversation: Conversation;
  onPress: () => void;
}

export const ConversationCard: React.FC<ConversationCardProps> = ({
  conversation,
  onPress,
}) => {
  const {
    contactName,
    contactId,
    lastMessage,
    unreadCount,
    status,
    humanTakeoverStartedAt,
  } = conversation;

  const displayName = contactName || contactId;

  return (
    <TouchableOpacity
      activeOpacity={0.7}
      style={[styles.container, unreadCount > 0 && styles.containerUnread]}
      onPress={onPress}
    >
      <View style={styles.header}>
        <Text style={styles.name} numberOfLines={1}>
          {displayName}
        </Text>
        <Text style={styles.time}>{formatShortDate(humanTakeoverStartedAt)}</Text>
      </View>

      <Text
        style={[
          styles.lastMessage,
          unreadCount > 0 && styles.lastMessageUnread,
        ]}
        numberOfLines={2}
      >
        {lastMessage || 'No messages yet'}
      </Text>

      <View style={styles.footer}>
        <StatusBadge status={status} />
        {unreadCount > 0 && (
          <View style={styles.unreadBadge}>
            <Text style={styles.unreadText}>{unreadCount}</Text>
          </View>
        )}
      </View>
    </TouchableOpacity>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.surface,
    padding: spacing.lg,
    borderBottomWidth: 1,
    borderColor: colors.border,
  },
  containerUnread: {
    backgroundColor: '#1E1B18', // slightly warmer highlight
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: spacing.xs,
  },
  name: {
    color: colors.text,
    fontSize: typography.fontSizes.md,
    fontWeight: typography.weights.bold,
    flex: 1,
    marginRight: spacing.sm,
  },
  time: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
  },
  lastMessage: {
    color: colors.textSecondary,
    fontSize: typography.fontSizes.sm,
    lineHeight: 20,
    marginBottom: spacing.md,
  },
  lastMessageUnread: {
    color: colors.text,
    fontWeight: typography.weights.medium,
  },
  footer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  unreadBadge: {
    backgroundColor: colors.primary,
    minWidth: 20,
    height: 20,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
    paddingHorizontal: 6,
  },
  unreadText: {
    color: colors.textInverse,
    fontSize: 10,
    fontWeight: 'bold',
  },
});
export default ConversationCard;
