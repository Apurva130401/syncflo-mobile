import React from 'react';
import { View, Text, StyleSheet, ScrollView, Alert } from 'react-native';
import { useConversations } from '../../hooks/useConversations';
import { Button } from '../../components/common/Button';
import { StatusBadge } from '../../components/inbox/StatusBadge';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { formatCurrency } from '../../utils/formatting';
import {
  User,
  Phone,
  DollarSign,
  MapPin,
  Home,
  Award,
} from 'lucide-react-native';

export const ConversationDetailScreen = ({ route, navigation }: any) => {
  const { conversationId } = route.params;
  const { conversations, resolveConversation, takeoverConversation } =
    useConversations();

  const conversation = conversations.find((c) => c.id === conversationId);

  const handleResolve = () => {
    Alert.alert(
      'Resolve Conversation',
      'Are you sure you want to mark this conversation as resolved?',
      [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Resolve',
          onPress: async () => {
            await resolveConversation(conversationId);
            Alert.alert('Success', 'Conversation marked as resolved.');
            navigation.navigate('ConversationList');
          },
        },
      ]
    );
  };

  if (!conversation) {
    return (
      <View style={styles.errorContainer}>
        <Text style={styles.errorText}>Conversation not found</Text>
      </View>
    );
  }

  // Simulated Lead Data (aligned with real estate mode capabilities)
  const leadData = {
    budget_min: 5000000,
    budget_max: 12000000,
    preferred_city: 'Mumbai',
    preferred_locality: 'Andheri West',
    preferred_bhk: '2 BHK',
    status: 'qualified',
    lead_score: 85,
    notes: 'Looking for a flat near the metro. Active WhatsApp responder.',
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Contact Details</Text>
        <View style={styles.infoRow}>
          <User size={16} color={colors.primary} style={styles.icon} />
          <Text style={styles.label}>Name:</Text>
          <Text style={styles.value}>
            {conversation.contactName || 'Unknown User'}
          </Text>
        </View>
        <View style={styles.infoRow}>
          <Phone size={16} color={colors.primary} style={styles.icon} />
          <Text style={styles.label}>WhatsApp:</Text>
          <Text style={styles.value}>{conversation.contactId}</Text>
        </View>
        <View style={styles.infoRow}>
          <Award size={16} color={colors.primary} style={styles.icon} />
          <Text style={styles.label}>Inbox Mode:</Text>
          <StatusBadge status={conversation.status} style={styles.badge} />
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Lead Analysis</Text>
        <View style={styles.infoRow}>
          <DollarSign size={16} color={colors.accent} style={styles.icon} />
          <Text style={styles.label}>Budget:</Text>
          <Text style={styles.value}>
            {leadData.budget_min && leadData.budget_max
              ? `${formatCurrency(leadData.budget_min)} - ${formatCurrency(leadData.budget_max)}`
              : 'Not set'}
          </Text>
        </View>
        <View style={styles.infoRow}>
          <MapPin size={16} color={colors.accent} style={styles.icon} />
          <Text style={styles.label}>Location:</Text>
          <Text style={styles.value}>
            {leadData.preferred_locality}, {leadData.preferred_city}
          </Text>
        </View>
        <View style={styles.infoRow}>
          <Home size={16} color={colors.accent} style={styles.icon} />
          <Text style={styles.label}>BHK Pref:</Text>
          <Text style={styles.value}>{leadData.preferred_bhk}</Text>
        </View>
        <View style={styles.infoRow}>
          <Award size={16} color={colors.accent} style={styles.icon} />
          <Text style={styles.label}>Lead Score:</Text>
          <Text style={[styles.value, styles.scoreValue]}>
            {leadData.lead_score}/100
          </Text>
        </View>
        {leadData.notes && (
          <View style={styles.notesContainer}>
            <Text style={styles.notesLabel}>Assistant Notes:</Text>
            <Text style={styles.notesValue}>{leadData.notes}</Text>
          </View>
        )}
      </View>

      <View style={styles.actions}>
        {conversation.status === 'ai' && (
          <Button
            title="Take Over Control"
            onPress={() => takeoverConversation(conversationId)}
            variant="primary"
            style={styles.actionBtn}
          />
        )}
        {conversation.status !== 'resolved' && (
          <Button
            title="Close / Resolve Conversation"
            onPress={handleResolve}
            variant="danger"
            style={styles.actionBtn}
          />
        )}
      </View>
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
  section: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 12,
    padding: spacing.lg,
    marginBottom: spacing.lg,
  },
  sectionTitle: {
    color: colors.primary,
    fontSize: typography.fontSizes.md,
    fontWeight: typography.weights.bold,
    marginBottom: spacing.md,
    textTransform: 'uppercase',
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  icon: {
    marginRight: spacing.sm,
  },
  label: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.weights.medium,
    width: 90,
  },
  value: {
    color: colors.text,
    fontSize: typography.fontSizes.sm,
    flex: 1,
  },
  scoreValue: {
    color: colors.accent,
    fontWeight: 'bold',
  },
  badge: {
    alignSelf: 'auto',
  },
  notesContainer: {
    borderTopWidth: 1,
    borderColor: colors.border,
    paddingTop: spacing.sm,
    marginTop: spacing.sm,
  },
  notesLabel: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.bold,
    marginBottom: 4,
  },
  notesValue: {
    color: colors.textSecondary,
    fontSize: typography.fontSizes.sm,
    lineHeight: 20,
  },
  actions: {
    marginTop: spacing.md,
  },
  actionBtn: {
    marginBottom: spacing.md,
  },
  errorContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.background,
  },
  errorText: {
    color: colors.error,
    fontSize: typography.fontSizes.md,
    fontWeight: 'bold',
  },
});
export default ConversationDetailScreen;
