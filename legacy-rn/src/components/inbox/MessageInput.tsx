import React, { useState } from 'react';
import {
  View,
  TextInput,
  TouchableOpacity,
  StyleSheet,
  Text,
  ActivityIndicator,
} from 'react-native';
import { Send, ZapOff, Play } from 'lucide-react-native';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';

interface MessageInputProps {
  conversationId: string;
  isAiControlled: boolean;
  onSend: (text: string) => void;
  onTakeover: () => void;
  onRelease: () => void;
  loading?: boolean;
}

export const MessageInput: React.FC<MessageInputProps> = ({
  conversationId,
  isAiControlled,
  onSend,
  onTakeover,
  onRelease,
  loading = false,
}) => {
  const [text, setText] = useState('');

  const handleSend = () => {
    if (!text.trim()) return;
    onSend(text.trim());
    setText('');
  };

  return (
    <View style={styles.container}>
      {isAiControlled ? (
        <View style={styles.aiBanner}>
          <Text style={styles.aiBannerText}>
            AI Assistant is replying.
          </Text>
          <TouchableOpacity
            activeOpacity={0.8}
            style={styles.takeoverBtn}
            onPress={onTakeover}
          >
            <ZapOff size={12} color={colors.textInverse} style={styles.btnIcon} />
            <Text style={styles.takeoverBtnText}>Take Over</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <View style={styles.humanBanner}>
          <Text style={styles.humanBannerText}>
            You have control of this chat.
          </Text>
          <TouchableOpacity
            activeOpacity={0.8}
            style={styles.releaseBtn}
            onPress={onRelease}
          >
            <Play size={12} color={colors.success} style={styles.btnIcon} />
            <Text style={styles.releaseBtnText}>Resume AI</Text>
          </TouchableOpacity>
        </View>
      )}

      <View style={styles.inputContainer}>
        <TextInput
          placeholder={
            isAiControlled
              ? 'Send to take over and reply...'
              : 'Type a message...'
          }
          placeholderTextColor={colors.textMuted}
          style={styles.input}
          value={text}
          onChangeText={setText}
          multiline
        />
        <TouchableOpacity
          disabled={!text.trim() || loading}
          style={[
            styles.sendButton,
            (!text.trim() || loading) && styles.sendButtonDisabled,
          ]}
          onPress={handleSend}
        >
          {loading ? (
            <ActivityIndicator size="small" color={colors.textInverse} />
          ) : (
            <Send
              size={16}
              color={text.trim() ? colors.textInverse : colors.textMuted}
            />
          )}
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    backgroundColor: colors.surface,
    borderTopWidth: 1,
    borderColor: colors.border,
    paddingBottom: spacing.sm,
  },
  aiBanner: {
    backgroundColor: 'rgba(16, 185, 129, 0.12)',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    borderColor: 'rgba(16, 185, 129, 0.25)',
    borderBottomWidth: 1,
  },
  aiBannerText: {
    color: colors.success,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.medium,
  },
  humanBanner: {
    backgroundColor: 'rgba(245, 158, 11, 0.12)',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    borderColor: 'rgba(245, 158, 11, 0.25)',
    borderBottomWidth: 1,
  },
  humanBannerText: {
    color: colors.accent,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.medium,
  },
  takeoverBtn: {
    backgroundColor: colors.primary,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.md,
    paddingVertical: 6,
    borderRadius: 6,
  },
  takeoverBtnText: {
    color: colors.textInverse,
    fontSize: 11,
    fontWeight: 'bold',
  },
  releaseBtn: {
    backgroundColor: 'rgba(16, 185, 129, 0.15)',
    borderColor: 'rgba(16, 185, 129, 0.4)',
    borderWidth: 1,
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.md,
    paddingVertical: 5,
    borderRadius: 6,
  },
  releaseBtnText: {
    color: colors.success,
    fontSize: 11,
    fontWeight: 'bold',
  },
  btnIcon: {
    marginRight: 4,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: spacing.lg,
    paddingTop: spacing.sm,
  },
  input: {
    flex: 1,
    backgroundColor: colors.background,
    color: colors.text,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 20,
    paddingHorizontal: spacing.lg,
    paddingVertical: 8,
    marginRight: spacing.sm,
    fontSize: typography.fontSizes.md,
    maxHeight: 100,
  },
  sendButton: {
    backgroundColor: colors.primary,
    width: 36,
    height: 36,
    borderRadius: 18,
    alignItems: 'center',
    justifyContent: 'center',
  },
  sendButtonDisabled: {
    backgroundColor: colors.border,
  },
});
export default MessageInput;
