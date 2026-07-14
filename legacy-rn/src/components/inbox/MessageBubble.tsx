import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { Message } from '../../types';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { formatTime } from '../../utils/formatting';

interface MessageBubbleProps {
  message: Message;
}

export const MessageBubble: React.FC<MessageBubbleProps> = ({ message }) => {
  const { content, isFromUser, sentByAi, createdAt, senderId } = message;

  const isSystem = senderId === 'system';

  if (isSystem) {
    return (
      <View style={styles.systemContainer}>
        <Text style={styles.systemText}>{content}</Text>
      </View>
    );
  }

  const isCustomer = isFromUser;
  const isAgent = !isFromUser && !sentByAi;

  const getBubbleStyle = () => {
    if (isCustomer) return [styles.bubble, styles.customerBubble];
    if (isAgent) return [styles.bubble, styles.agentBubble];
    return [styles.bubble, styles.aiBubble]; // AI message
  };

  const getAlignStyle = () => {
    if (isAgent) return styles.alignRight;
    return styles.alignLeft;
  };

  const getTextStyle = () => {
    if (isAgent) return styles.agentText;
    return styles.text;
  };

  const renderReadReceipt = () => {
    if (!isAgent) return null;
    const isRead = message.status === 'read';
    const isDelivered = message.status === 'delivered' || isRead;
    const color = isRead ? colors.success : 'rgba(18, 17, 16, 0.4)';
    const marks = isDelivered ? '✓✓' : '✓';
    return <Text style={[styles.receipt, { color }]}>{marks}</Text>;
  };

  return (
    <View style={[styles.messageRow, getAlignStyle()]}>
      <View style={getBubbleStyle()}>
        {!isFromUser && (
          <Text style={styles.senderName}>{sentByAi ? 'AI Assistant' : 'Agent'}</Text>
        )}
        <Text style={getTextStyle()}>{content}</Text>
        <View style={styles.footerRow}>
          <Text style={[styles.time, isAgent && styles.agentTime]}>
            {formatTime(createdAt)}
          </Text>
          {renderReadReceipt()}
        </View>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  messageRow: {
    flexDirection: 'row',
    marginVertical: spacing.xs,
    paddingHorizontal: spacing.md,
  },
  alignLeft: {
    justifyContent: 'flex-start',
  },
  alignRight: {
    justifyContent: 'flex-end',
  },
  bubble: {
    borderRadius: 16,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    maxWidth: '75%',
  },
  customerBubble: {
    backgroundColor: colors.surface,
    borderBottomLeftRadius: 4,
    borderWidth: 1,
    borderColor: colors.border,
  },
  agentBubble: {
    backgroundColor: colors.primary,
    borderBottomRightRadius: 4,
  },
  aiBubble: {
    backgroundColor: 'rgba(16, 185, 129, 0.08)',
    borderColor: 'rgba(16, 185, 129, 0.4)',
    borderWidth: 1,
    borderBottomLeftRadius: 4,
  },
  senderName: {
    fontSize: 10,
    fontWeight: 'bold',
    color: colors.primaryLight,
    marginBottom: 2,
  },
  text: {
    color: colors.text,
    fontSize: typography.fontSizes.md,
    lineHeight: 22,
  },
  agentText: {
    color: colors.textInverse,
    fontSize: typography.fontSizes.md,
    lineHeight: 22,
  },
  time: {
    color: colors.textMuted,
    fontSize: 9,
  },
  agentTime: {
    color: 'rgba(18, 17, 16, 0.6)',
  },
  footerRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'flex-end',
    marginTop: 4,
  },
  receipt: {
    fontSize: 10,
    marginLeft: 4,
    fontWeight: 'bold',
  },
  systemContainer: {
    alignItems: 'center',
    justifyContent: 'center',
    marginVertical: spacing.md,
    paddingHorizontal: spacing.xl,
  },
  systemText: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
    textAlign: 'center',
    backgroundColor: colors.surface,
    paddingVertical: spacing.xs,
    paddingHorizontal: spacing.md,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: colors.border,
  },
});
export default MessageBubble;
