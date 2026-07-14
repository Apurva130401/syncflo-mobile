import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ScrollView, ActivityIndicator } from 'react-native';
import { useAuth } from '../../hooks/useAuth';
import { apiClient } from '../../services/api';
import { colors } from '../../theme/colors';
import { spacing } from '../../theme/spacing';
import { typography } from '../../theme/typography';
import { MessageSquare, Clock, ArrowUpRight, BarChart2 } from 'lucide-react-native';

export const AnalyticsScreen = () => {
  const { user } = useAuth();
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState<any>({
    totalConversationsToday: 0,
    resolvedEscalatedRatio: '0/0',
    avgResponseTime: '0s',
    volumeTrend: [],
    agentBreakdown: [],
  });

  useEffect(() => {
    const loadAnalytics = async () => {
      try {
        const response = await apiClient.get('/analytics');
        setData(response.data);
      } catch (err) {
        // Fallback mock data
        setData({
          totalConversationsToday: 124,
          resolvedEscalatedRatio: '92/32',
          avgResponseTime: '2.4s',
          volumeTrend: [
            { day: 'Mon', count: 42 },
            { day: 'Tue', count: 58 },
            { day: 'Wed', count: 64 },
            { day: 'Thu', count: 48 },
            { day: 'Fri', count: 72 },
            { day: 'Sat', count: 35 },
            { day: 'Sun', count: 28 },
          ],
          agentBreakdown: [
            { name: 'Apurva (Owner)', chats: 45, avgTime: '1.8s' },
            { name: 'Jane Smith (Agent)', chats: 35, avgTime: '3.1s' },
            { name: 'Bob Johnson (Agent)', chats: 44, avgTime: '2.3s' },
          ],
        });
      } finally {
        setLoading(false);
      }
    };
    loadAnalytics();
  }, []);

  if (loading) {
    return (
      <View style={styles.loaderContainer}>
        <ActivityIndicator size="large" color={colors.primary} />
        <Text style={styles.loaderText}>Loading analytics dashboard...</Text>
      </View>
    );
  }

  const volumeCounts = data.volumeTrend.map((d: any) => d.count);
  const maxVolume = volumeCounts.length > 0 ? Math.max(...volumeCounts) : 0;

  return (
    <ScrollView style={styles.container} contentContainerStyle={styles.content}>
      {/* KPI Cards */}
      <View style={styles.grid}>
        <View style={styles.card}>
          <MessageSquare size={20} color={colors.primary} />
          <Text style={styles.cardVal}>{data.totalConversationsToday}</Text>
          <Text style={styles.cardLabel}>Chats Today</Text>
        </View>

        <View style={styles.card}>
          <ArrowUpRight size={20} color={colors.accent} />
          <Text style={styles.cardVal}>{data.resolvedEscalatedRatio}</Text>
          <Text style={styles.cardLabel}>Closed / Escalated</Text>
        </View>
      </View>

      <View style={[styles.grid, { marginBottom: spacing.lg }]}>
        <View style={styles.card}>
          <Clock size={20} color={colors.success} />
          <Text style={styles.cardVal}>{data.avgResponseTime}</Text>
          <Text style={styles.cardLabel}>Avg Response Time</Text>
        </View>
      </View>

      {/* Bar Chart Section */}
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Volume Trend (Last 7 Days)</Text>
        <View style={styles.chartContainer}>
          {data.volumeTrend.map((item: any, i: number) => {
            const barHeight = maxVolume > 0 ? (item.count / maxVolume) * 100 : 0;
            return (
              <View key={i} style={styles.chartCol}>
                <View style={styles.barWrapper}>
                  <View style={[styles.chartBar, { height: `${barHeight}%` }]} />
                </View>
                <Text style={styles.chartDay}>{item.day}</Text>
                <Text style={styles.chartCount}>{item.count}</Text>
              </View>
            );
          })}
        </View>
      </View>

      {/* Owner/Admin Breakdown Section */}
      {user?.role === 'admin' && (
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Agent Performance</Text>
          {data.agentBreakdown.map((agent: any, i: number) => (
            <View key={i} style={styles.agentRow}>
              <View style={styles.agentInfo}>
                <Text style={styles.agentName}>{agent.name}</Text>
                <Text style={styles.agentDetail}>Avg Speed: {agent.avgTime}</Text>
              </View>
              <View style={styles.agentBadge}>
                <Text style={styles.agentBadgeText}>{agent.chats} chats</Text>
              </View>
            </View>
          ))}
        </View>
      )}
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
  loaderContainer: {
    flex: 1,
    backgroundColor: colors.background,
    alignItems: 'center',
    justifyContent: 'center',
  },
  loaderText: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.sm,
    marginTop: spacing.md,
  },
  grid: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: spacing.md,
  },
  card: {
    backgroundColor: colors.surface,
    borderColor: colors.border,
    borderWidth: 1,
    borderRadius: 12,
    padding: spacing.lg,
    flex: 1,
    marginHorizontal: spacing.xs,
  },
  cardVal: {
    color: colors.text,
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.weights.bold,
    marginTop: spacing.sm,
  },
  cardLabel: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
    marginTop: 2,
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
    fontSize: typography.fontSizes.xs,
    fontWeight: typography.weights.bold,
    marginBottom: spacing.lg,
    textTransform: 'uppercase',
    letterSpacing: 1,
  },
  chartContainer: {
    flexDirection: 'row',
    height: 160,
    alignItems: 'flex-end',
    justifyContent: 'space-between',
    paddingTop: spacing.lg,
  },
  chartCol: {
    alignItems: 'center',
    flex: 1,
  },
  barWrapper: {
    height: 100,
    width: 14,
    backgroundColor: colors.surfaceLight,
    borderRadius: 7,
    justifyContent: 'flex-end',
  },
  chartBar: {
    width: '100%',
    backgroundColor: colors.primary,
    borderRadius: 7,
  },
  chartDay: {
    color: colors.textMuted,
    fontSize: 9,
    marginTop: 6,
    fontWeight: typography.weights.medium,
  },
  chartCount: {
    color: colors.primary,
    fontSize: 10,
    fontWeight: typography.weights.bold,
    marginTop: 2,
  },
  agentRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingVertical: spacing.sm,
    borderBottomWidth: 1,
    borderColor: colors.border,
  },
  agentInfo: {
    flex: 1,
  },
  agentName: {
    color: colors.text,
    fontSize: typography.fontSizes.sm,
    fontWeight: typography.weights.bold,
  },
  agentDetail: {
    color: colors.textMuted,
    fontSize: typography.fontSizes.xs,
    marginTop: 2,
  },
  agentBadge: {
    backgroundColor: 'rgba(255, 140, 0, 0.12)',
    borderColor: 'rgba(255, 140, 0, 0.25)',
    borderWidth: 1,
    paddingHorizontal: spacing.sm,
    paddingVertical: 3,
    borderRadius: 8,
  },
  agentBadgeText: {
    color: colors.primary,
    fontSize: 10,
    fontWeight: 'bold',
  },
});

export default AnalyticsScreen;
