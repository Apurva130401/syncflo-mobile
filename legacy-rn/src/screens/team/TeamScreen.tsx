import React from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  Alert,
  TouchableOpacity,
} from 'react-native';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { Button } from '../../components/common/Button';
import { MessageSquare } from 'lucide-react-native';

export const TeamScreen = ({ navigation }: any) => {
  const teamMembers = [
    {
      id: '1',
      name: 'Apurva',
      email: 'apurva@syncflo.ai',
      role: 'admin',
      online: true,
      activeChats: 3,
    },
    {
      id: '2',
      name: 'Jane Smith',
      email: 'jane@syncflo.ai',
      role: 'agent',
      online: true,
      activeChats: 5,
    },
    {
      id: '3',
      name: 'Bob Johnson',
      email: 'bob@syncflo.ai',
      role: 'viewer',
      online: false,
      activeChats: 0,
    },
  ];

  const handleInvite = () => {
    Alert.prompt(
      'Invite Member',
      "Enter the email address of the team member you'd like to invite:",
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Send Invite',
          onPress: (email?: string) =>
            Alert.alert('Invitation Sent', `Invite email sent to ${email}`),
        },
      ]
    );
  };

  const handleMemberPress = (member: any) => {
    navigation.navigate('Inbox', {
      screen: 'ConversationList',
      params: { assignedToFilter: member.name },
    });
  };

  return (
    <View style={styles.container}>
      <FlatList
        data={teamMembers}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => (
          <TouchableOpacity
            activeOpacity={0.8}
            onPress={() => handleMemberPress(item)}
            style={styles.memberCard}
          >
            <View style={styles.avatar}>
              <Text style={styles.avatarText}>
                {item.name.charAt(0).toUpperCase()}
              </Text>
              {item.online && <View style={styles.onlineDot} />}
            </View>
            <View style={styles.info}>
              <Text style={styles.name}>{item.name}</Text>
              <Text style={styles.email}>{item.email}</Text>
              <View style={styles.chatsCountRow}>
                <MessageSquare size={12} color={colors.textMuted} style={styles.chatIcon} />
                <Text style={styles.chatsCountText}>
                  {item.activeChats} active chats
                </Text>
              </View>
            </View>
            <View style={styles.roleBadge}>
              <Text style={styles.roleText}>{item.role.toUpperCase()}</Text>
            </View>
          </TouchableOpacity>
        )}
        ListFooterComponent={
          <View style={styles.inviteContainer}>
            <Button title="Invite Team Member" onPress={handleInvite} />
          </View>
        }
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
    padding: spacing.lg,
  },
  memberCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 8,
    padding: spacing.md,
    marginBottom: spacing.md,
  },
  avatar: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: colors.surfaceLight,
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
  },
  avatarText: {
    color: colors.text,
    fontSize: typography.fontSizes.md,
    fontWeight: 'bold',
  },
  onlineDot: {
    position: 'absolute',
    bottom: 0,
    right: 0,
    width: 12,
    height: 12,
    borderRadius: 6,
    backgroundColor: colors.success,
    borderWidth: 2,
    borderColor: colors.surface,
  },
  info: {
    flex: 1,
    marginLeft: spacing.md,
  },
  name: {
    color: colors.text,
    fontSize: typography.fontSizes.sm + 2,
    fontWeight: typography.weights.bold,
  },
  email: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
  },
  chatsCountRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 4,
  },
  chatIcon: {
    marginRight: 4,
  },
  chatsCountText: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
  },
  roleBadge: {
    backgroundColor: 'rgba(245, 158, 11, 0.12)',
    borderColor: 'rgba(245, 158, 11, 0.25)',
    borderWidth: 1,
    paddingHorizontal: spacing.sm,
    paddingVertical: 3,
    borderRadius: 8,
  },
  roleText: {
    color: colors.accent,
    fontSize: 9,
    fontWeight: 'bold',
  },
  inviteContainer: {
    marginTop: spacing.lg,
  },
});

export default TeamScreen;
