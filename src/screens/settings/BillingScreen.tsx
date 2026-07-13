import React from 'react';
import { View, Text, StyleSheet, ScrollView } from 'react-native';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { CreditCard, Award, ArrowUpRight } from 'lucide-react-native';

export const BillingScreen = () => {
  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      <View style={styles.planCard}>
        <View style={styles.planHeader}>
          <Award size={24} color={colors.primary} />
          <Text style={styles.planTitle}>Growth Suite</Text>
        </View>
        <Text style={styles.planPrice}>$99 / month</Text>
        <Text style={styles.planStatus}>Active (Renews Aug 11, 2026)</Text>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Usage this Month</Text>
        
        <View style={styles.usageRow}>
          <View style={styles.usageLeft}>
            <Text style={styles.usageTitle}>WhatsApp API Messages</Text>
            <Text style={styles.usageDetail}>4,284 of 10,000 sent</Text>
          </View>
          <Text style={styles.usagePercent}>42%</Text>
        </View>
        <View style={styles.progressBar}>
          <View style={[styles.progressFill, { width: '42%' }]} />
        </View>

        <View style={styles.usageRow}>
          <View style={styles.usageLeft}>
            <Text style={styles.usageTitle}>AI Assistant Conversations</Text>
            <Text style={styles.usageDetail}>358 of 1,000</Text>
          </View>
          <Text style={styles.usagePercent}>35%</Text>
        </View>
        <View style={styles.progressBar}>
          <View style={[styles.progressFill, { width: '35%' }]} />
        </View>
      </View>

      <View style={styles.paymentSection}>
        <Text style={styles.paymentTitle}>Payment Method</Text>
        <View style={styles.cardInfo}>
          <CreditCard size={20} color={colors.textSecondary} style={styles.paymentIcon} />
          <Text style={styles.cardText}>Visa ending in 4242</Text>
        </View>
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
  planCard: {
    backgroundColor: colors.surface,
    borderColor: colors.primary,
    borderWidth: 1.5,
    borderRadius: 12,
    padding: spacing.lg,
    marginBottom: spacing.lg,
  },
  planHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: spacing.sm,
  },
  planTitle: {
    color: colors.text,
    fontSize: typography.fontSizes.lg,
    fontWeight: typography.weights.bold,
    marginLeft: spacing.sm,
  },
  planPrice: {
    color: colors.primary,
    fontSize: typography.fontSizes.xxl,
    fontWeight: typography.weights.bold,
    marginBottom: spacing.xs,
  },
  planStatus: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
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
    marginBottom: spacing.lg,
  },
  usageRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'flex-end',
    marginBottom: spacing.xs,
  },
  usageLeft: {
    flex: 1,
  },
  usageTitle: {
    color: colors.text,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.weights.semibold,
    marginBottom: 2,
  },
  usageDetail: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
  },
  usagePercent: {
    color: colors.primary,
    fontSize: typography.fontSizes.sm,
    fontWeight: 'bold',
  },
  progressBar: {
    height: 6,
    backgroundColor: colors.border,
    borderRadius: 3,
    marginBottom: spacing.lg,
    overflow: 'hidden',
  },
  progressFill: {
    height: '100%',
    backgroundColor: colors.primary,
    borderRadius: 3,
  },
  paymentSection: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 12,
    padding: spacing.lg,
  },
  paymentTitle: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.bold,
    marginBottom: spacing.sm,
    textTransform: 'uppercase',
  },
  cardInfo: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  paymentIcon: {
    marginRight: spacing.sm,
  },
  cardText: {
    color: colors.text,
    fontSize: typography.fontSizes.sm,
  },
});
export default BillingScreen;
