import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Alert,
  Linking,
  TouchableOpacity,
} from 'react-native';
import { useForm, Controller } from 'react-hook-form';
import { useAuth } from '../../hooks/useAuth';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { Button } from '../../components/common/Button';
import { Input } from '../../components/common/Input';
import { emailRules } from '../../utils/validation';
import {
  HelpCircle,
  ExternalLink,
  BookOpen,
  AlertCircle,
  CheckCircle,
} from 'lucide-react-native';

const FAQS = [
  {
    q: 'How do I take over from AI?',
    a: "Tap the 'Take Over' banner at the bottom of any active chat room. Automated auto-replies will immediately pause so you can respond manually.",
  },
  {
    q: 'Why am I not receiving push notifications?',
    a: "Check that notifications permission is allowed in your OS Settings, and push notifications are toggled 'Enabled' under the App settings tab.",
  },
  {
    q: 'Where do I add new WhatsApp numbers?',
    a: 'WhatsApp integrations and Meta Business profile connections must be authorized from the desktop dashboard.',
  },
];

export const SupportScreen = () => {
  const { user } = useAuth();
  const [activeFaq, setActiveFaq] = useState<number | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const { control, handleSubmit, reset } = useForm({
    defaultValues: {
      email: user?.email || '',
      message: '',
    },
  });

  const onSubmit = async (data: any) => {
    setSubmitting(true);
    // Mock API support ticket dispatch
    setTimeout(() => {
      setSubmitting(false);
      Alert.alert(
        'Support Ticket Opened',
        'Thank you! We have received your request. An operations coordinator will email you shortly.'
      );
      reset({ email: user?.email || '', message: '' });
    }, 1500);
  };

  const handleOpenDocs = () => {
    Linking.openURL('https://docs.syncflo.xyz').catch(() => {
      Alert.alert('Error', 'Failed to open web page.');
    });
  };

  const renderFaq = (faq: typeof FAQS[0], index: number) => {
    const isExpanded = activeFaq === index;
    return (
      <TouchableOpacity
        key={index}
        activeOpacity={0.8}
        onPress={() => setActiveFaq(isExpanded ? null : index)}
        style={styles.faqCard}
      >
        <Text style={styles.faqQuestion}>{faq.q}</Text>
        {isExpanded && <Text style={styles.faqAnswer}>{faq.a}</Text>}
      </TouchableOpacity>
    );
  };

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* Service Status Banner */}
      <View style={styles.statusCard}>
        <CheckCircle size={18} color={colors.success} style={styles.statusIcon} />
        <View style={styles.statusInfo}>
          <Text style={styles.statusTitle}>All Systems Operational</Text>
          <Text style={styles.statusSubtitle}>Meta Cloud API latency: 180ms</Text>
        </View>
      </View>

      {/* Docs Link Card */}
      <TouchableOpacity
        activeOpacity={0.8}
        onPress={handleOpenDocs}
        style={styles.docsCard}
      >
        <View style={styles.docsCardLeft}>
          <BookOpen size={22} color={colors.primary} style={styles.docsIcon} />
          <View>
            <Text style={styles.docsTitle}>Documentation Portal</Text>
            <Text style={styles.docsSubtitle}>Read onboarding guides</Text>
          </View>
        </View>
        <ExternalLink size={16} color={colors.textMuted} />
      </TouchableOpacity>

      {/* FAQs Header */}
      <Text style={styles.sectionTitle}>Frequently Asked Questions</Text>
      <View style={styles.faqSection}>{FAQS.map(renderFaq)}</View>

      {/* Form Header */}
      <Text style={styles.sectionTitle}>Contact Operations Support</Text>
      <View style={styles.formSection}>
        <Controller
          control={control}
          name="email"
          rules={emailRules}
          render={({ field: { onChange, value }, fieldState: { error } }) => (
            <Input
              label="Contact Email"
              keyboardType="email-address"
              autoCapitalize="none"
              value={value}
              onChangeText={onChange}
              error={error?.message}
            />
          )}
        />

        <Controller
          control={control}
          name="message"
          rules={{ required: 'Please enter details of your issue' }}
          render={({ field: { onChange, value }, fieldState: { error } }) => (
            <Input
              label="Issue Description"
              placeholder="What seems to be the problem?"
              multiline
              numberOfLines={4}
              value={value}
              onChangeText={onChange}
              error={error?.message}
            />
          )}
        />

        <Button
          title="Submit Support Request"
          onPress={handleSubmit(onSubmit)}
          loading={submitting}
          style={styles.btn}
        />
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
    paddingBottom: spacing.xxl,
  },
  statusCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(16, 185, 129, 0.12)',
    borderColor: 'rgba(16, 185, 129, 0.25)',
    borderWidth: 1,
    borderRadius: 12,
    padding: spacing.md,
    marginBottom: spacing.lg,
  },
  statusIcon: {
    marginRight: spacing.md,
  },
  statusInfo: {
    flex: 1,
  },
  statusTitle: {
    color: colors.success,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.weights.bold,
  },
  statusSubtitle: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
    marginTop: 2,
  },
  docsCard: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 12,
    padding: spacing.md,
    marginBottom: spacing.xl,
  },
  docsCardLeft: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  docsIcon: {
    marginRight: spacing.md,
  },
  docsTitle: {
    color: colors.text,
    fontSize: typography.fontSizes.sm + 2,
    fontWeight: typography.weights.bold,
  },
  docsSubtitle: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
    marginTop: 2,
  },
  sectionTitle: {
    color: colors.primary,
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.bold,
    marginBottom: spacing.sm,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  faqSection: {
    marginBottom: spacing.xl,
  },
  faqCard: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 8,
    padding: spacing.md,
    marginBottom: spacing.sm,
  },
  faqQuestion: {
    color: colors.text,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.weights.bold,
  },
  faqAnswer: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.sm,
    lineHeight: 20,
    marginTop: spacing.sm,
  },
  formSection: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 12,
    padding: spacing.lg,
  },
  btn: {
    marginTop: spacing.md,
  },
});

export default SupportScreen;
