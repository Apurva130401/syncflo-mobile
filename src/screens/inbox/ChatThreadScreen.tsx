import React, { useEffect, useRef, useState } from 'react';
import {
  View,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Text,
  ScrollView,
  Alert,
} from 'react-native';
import { useConversations } from '../../hooks/useConversations';
import { MessageBubble } from '../../components/inbox/MessageBubble';
import { MessageInput } from '../../components/inbox/MessageInput';
import { LoadingSpinner } from '../../components/common/LoadingSpinner';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { Info, UserCheck } from 'lucide-react-native';

const QUICK_REPLIES = [
  'Hello! How can I help you?',
  'Checking on this, please wait...',
  'Your ticket is resolved.',
  'Could you share your email?',
  'Thank you for contacting Syncflo!',
];

export const ChatThreadScreen = ({ route, navigation }: any) => {
  const { conversationId } = route.params;
  const {
    conversations,
    messages,
    isLoadingMessages,
    selectConversation,
    sendMessage,
    takeoverConversation,
    releaseConversation,
    assignConversation,
  } = useConversations(conversationId);

  const [isSending, setIsSending] = useState(false);
  const flatListRef = useRef<FlatList>(null);
  const activeConversation = conversations.find((c) => c.id === conversationId);

  useEffect(() => {
    selectConversation(conversationId);
    return () => {
      selectConversation(null);
    };
  }, [conversationId]);

  useEffect(() => {
    navigation.setOptions({
      title:
        activeConversation?.contactName ||
        activeConversation?.contactId ||
        'Chat',
      headerRight: () => (
        <View style={styles.headerRightContainer}>
          <TouchableOpacity
            activeOpacity={0.7}
            style={styles.headerBtn}
            onPress={handleAssign}
          >
            <UserCheck size={20} color={colors.primary} />
          </TouchableOpacity>
          <TouchableOpacity
            activeOpacity={0.7}
            style={styles.headerBtn}
            onPress={() =>
              navigation.navigate('ConversationDetail', { conversationId })
            }
          >
            <Info size={20} color={colors.primary} />
          </TouchableOpacity>
        </View>
      ),
    });
  }, [navigation, activeConversation, conversationId]);

  const handleSend = async (text: string) => {
    setIsSending(true);
    try {
      await sendMessage(conversationId, text);
    } catch (e) {
      // Error logged inside service
    } finally {
      setIsSending(false);
    }
  };

  const handleTakeover = () => {
    takeoverConversation(conversationId);
  };

  const handleRelease = () => {
    releaseConversation(conversationId);
  };

  const handleAssign = () => {
    Alert.alert('Assign Chat', 'Choose a team member to handle this chat:', [
      {
        text: 'Unassigned',
        onPress: () => assignConversation(conversationId, null),
      },
      {
        text: 'Me (Agent)',
        onPress: () => assignConversation(conversationId, 'Agent'),
      },
      {
        text: 'Apurva (Owner)',
        onPress: () => assignConversation(conversationId, 'Apurva'),
      },
      { text: 'Cancel', style: 'cancel' },
    ]);
  };

  const handleQuickReplyPress = (reply: string) => {
    handleSend(reply);
  };

  if (isLoadingMessages && messages.length === 0) {
    return <LoadingSpinner fullScreen message="Loading messages..." />;
  }

  return (
    <View style={styles.container}>
      {/* Assignment Status Bar */}
      <View style={styles.assignmentBar}>
        <Text style={styles.assignmentText}>
          Assigned to:{' '}
          <Text style={styles.assignmentValue}>
            {activeConversation?.assignedTo || 'Unassigned'}
          </Text>
        </Text>
        <TouchableOpacity
          activeOpacity={0.7}
          style={styles.reassignBtn}
          onPress={handleAssign}
        >
          <Text style={styles.reassignBtnText}>Assign</Text>
        </TouchableOpacity>
      </View>

      {/* Message Thread */}
      <FlatList
        ref={flatListRef}
        data={messages}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <MessageBubble message={item} />}
        contentContainerStyle={styles.messagesList}
        onContentSizeChange={() =>
          flatListRef.current?.scrollToEnd({ animated: true })
        }
        onLayout={() => flatListRef.current?.scrollToEnd({ animated: true })}
      />

      {/* Quick Replies Row (only shown if not AI controlled for quick agent entry) */}
      {activeConversation?.status !== 'ai' && (
        <View style={styles.quickRepliesWrapper}>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.quickRepliesContainer}
          >
            {QUICK_REPLIES.map((reply, i) => (
              <TouchableOpacity
                key={i}
                activeOpacity={0.8}
                onPress={() => handleQuickReplyPress(reply)}
                style={styles.quickReplyBubble}
              >
                <Text style={styles.quickReplyText}>{reply}</Text>
              </TouchableOpacity>
            ))}
          </ScrollView>
        </View>
      )}

      {/* Message Input Box */}
      <MessageInput
        conversationId={conversationId}
        isAiControlled={activeConversation?.status === 'ai'}
        onSend={handleSend}
        onTakeover={handleTakeover}
        onRelease={handleRelease}
        loading={isSending}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  headerRightContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    marginRight: spacing.md,
  },
  headerBtn: {
    padding: spacing.xs,
    marginLeft: spacing.sm,
  },
  assignmentBar: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.surface,
    paddingHorizontal: spacing.lg,
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderColor: colors.border,
  },
  assignmentText: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
  },
  assignmentValue: {
    color: colors.primary,
    fontWeight: typography.weights.bold,
  },
  reassignBtn: {
    backgroundColor: colors.surfaceLight,
    paddingHorizontal: spacing.md,
    paddingVertical: 4,
    borderRadius: 4,
    borderWidth: 1,
    borderColor: colors.border,
  },
  reassignBtnText: {
    color: colors.text,
    fontSize: 10,
    fontWeight: typography.weights.bold,
  },
  messagesList: {
    paddingVertical: spacing.md,
  },
  quickRepliesWrapper: {
    backgroundColor: colors.surface,
    borderTopWidth: 1,
    borderColor: colors.border,
    paddingVertical: spacing.sm,
  },
  quickRepliesContainer: {
    paddingHorizontal: spacing.lg,
  },
  quickReplyBubble: {
    backgroundColor: colors.surfaceLight,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 16,
    paddingHorizontal: spacing.md,
    paddingVertical: 6,
    marginRight: spacing.sm,
  },
  quickReplyText: {
    color: colors.text,
    fontSize: typography.fontSizes.xs,
  },
});

export default ChatThreadScreen;
