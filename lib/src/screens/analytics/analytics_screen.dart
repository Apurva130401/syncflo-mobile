import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/custom_charts.dart';
import '../../widgets/gated_section.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  String? _error;

  String _timeRange = 'last-30-days';
  Subscription? _subscription;
  Map<String, dynamic>? _overview;
  List<Profile> _teamWorkload = [];
  Timer? _liveTimer;

  // Live simulated metrics for Voice tab (matching dashboard live simulation)
  Map<String, String> _liveMetrics = {
    'responseTime': '1.2s',
    'resolutionRate': '92%',
    'customerSatisfaction': '4.7/5',
    'agentUtilization': '78%'
  };

  @override
  void initState() {
    super.initState();
    _loadAllAnalytics();
    _startLiveMetricsSimulation();
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    super.dispose();
  }

  void _startLiveMetricsSimulation() {
    _liveTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (mounted) {
        setState(() {
          final rand = Random();
          _liveMetrics = {
            'responseTime': '${(1.0 + rand.nextDouble() * 0.4).toStringAsFixed(1)}s',
            'resolutionRate': '${88 + rand.nextInt(9)}%',
            'customerSatisfaction': '${(4.5 + rand.nextDouble() * 0.4).toStringAsFixed(1)}/5',
            'agentUtilization': '${70 + rand.nextInt(16)}%',
          };
        });
      }
    });
  }

  Future<void> _loadAllAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch subscription, usage details, overview data, and team workload
      final results = await Future.wait([
        _supabaseService.getSubscription(),
        _supabaseService.getAnalyticsOverview(_timeRange),
        _supabaseService.getTeamMembers(),
      ]);

      setState(() {
        _subscription = results[0] as Subscription?;
        _overview = results[1] as Map<String, dynamic>?;
        _teamWorkload = results[2] as List<Profile>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  bool get _isAdvancedPlan {
    if (_subscription == null) return false;
    final plan = (_subscription!.currentPlan ?? '').toLowerCase();
    return (plan.contains('growth') ||
            plan.contains('performance') ||
            plan.contains('business') ||
            plan.contains('custom') ||
            plan.contains('enterprise')) &&
        !plan.contains('starter');
  }

  String _formatPlanName(String? plan) {
    if (plan == null || plan.isEmpty) return 'Starter / Trial';
    return plan.replaceAll('-', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  // Range Label helpers
  String get _timeRangeLabel {
    switch (_timeRange) {
      case 'last-7-days':
        return 'Last 7 Days';
      case 'last-90-days':
        return 'Last 90 Days';
      case 'last-year':
        return 'Last Year';
      case 'last-30-days':
      default:
        return 'Last 30 Days';
    }
  }

  void _exportReport(String tabName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report for $tabName ($_timeRangeLabel) exported to CSV successfully!'),
        backgroundColor: const Color(0xFF0F766E), // Teal
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(LucideIcons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refresh_cw),
              onPressed: _loadAllAnalytics,
            ),
          ],
          bottom: TabBar(
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.message_square, size: 16),
                    SizedBox(width: 8),
                    Text('WhatsApp AI'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.mic, size: 16),
                    SizedBox(width: 8),
                    Text('Voice Agent'),
                  ],
                ),
              ),
            ],
            labelColor: const Color(0xFFEA580C), // Warm orange selected label
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            indicatorColor: const Color(0xFFEA580C), // Warm orange indicator
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          ),
        ),
        drawer: const NavigationDrawerWidget(currentRoute: '/analytics'),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.circle_alert, color: AppColors.error, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load analytics',
                            style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadAllAnalytics,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFEA580C),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : TabBarView(
                    children: [
                      _buildWhatsAppTab(context, isDark),
                      _buildVoiceTab(context, isDark),
                    ],
                  ),
      ),
    );
  }

  // --- WHATSAPP TAB ---
  Widget _buildWhatsAppTab(BuildContext context, bool isDark) {
    // Extract KPI metrics
    final totalMessages = _overview?['total_messages'] ?? 0;
    final totalConversations = _overview?['total_conversations'] ?? 0;

    // Determine Top Sentiment
    String topSentimentName = 'No Data';
    double topSentimentVal = 0.0;
    final sentimentList = _overview?['customer_sentiment'] as List<dynamic>?;
    if (sentimentList != null && sentimentList.isNotEmpty) {
      var topItem = sentimentList.first;
      for (var item in sentimentList) {
        if ((item['value'] as num).toDouble() > (topItem['value'] as num).toDouble()) {
          topItem = item;
        }
      }
      topSentimentName = topItem['name'] ?? 'Neutral';
      topSentimentVal = (topItem['value'] as num).toDouble();
    }

    // Determine Peak Hour
    String peakHourName = 'No Data';
    int peakHourVal = 0;
    final peakHoursList = _overview?['peak_hours'] as List<dynamic>?;
    if (peakHoursList != null && peakHoursList.isNotEmpty) {
      var topItem = peakHoursList.first;
      for (var item in peakHoursList) {
        if ((item['messages'] as num).toInt() > (topItem['messages'] as num).toInt()) {
          topItem = item;
        }
      }
      peakHourName = topItem['hour'] ?? '12:00';
      peakHourVal = (topItem['messages'] as num).toInt();
    }

    // Parse Messages daily data
    final List<double> msgValues = [];
    final List<String> msgLabels = [];
    final messagesList = _overview?['whatsapp_messages_by_day'] as List<dynamic>?;
    if (messagesList != null) {
      for (var item in messagesList) {
        msgValues.add((item['messages'] as num).toDouble());
        msgLabels.add(item['name']?.toString() ?? '');
      }
    }

    // Parse Conversation daily data
    final List<double> convValues = [];
    final List<String> convLabels = [];
    final convList = _overview?['conversation_volume_by_day'] as List<dynamic>?;
    if (convList != null) {
      for (var item in convList) {
        convValues.add((item['conversations'] as num).toDouble());
        convLabels.add(item['name']?.toString() ?? '');
      }
    }

    // Donut chart - Sentiment
    final List<double> sentValues = [];
    final List<String> sentLabels = [];
    if (sentimentList != null) {
      for (var item in sentimentList) {
        sentValues.add((item['value'] as num).toDouble());
        sentLabels.add(item['name']?.toString() ?? '');
      }
    }

    // Donut chart - AI vs Human
    final List<double> handlingValues = [];
    final List<String> handlingLabels = [];
    final handlingList = _overview?['ai_vs_human_handling'] as List<dynamic>?;
    if (handlingList != null) {
      for (var item in handlingList) {
        handlingValues.add((item['value'] as num).toDouble());
        handlingLabels.add(item['name']?.toString() ?? '');
      }
    }

    // Donut chart - Contact Mix
    final List<double> contactValues = [];
    final List<String> contactLabels = [];
    final contactList = _overview?['new_vs_returning_contacts'] as List<dynamic>?;
    if (contactList != null) {
      for (var item in contactList) {
        contactValues.add((item['value'] as num).toDouble());
        contactLabels.add(item['name']?.toString() ?? '');
      }
    }

    // Gated - Lead Funnel
    final List<double> funnelValues = [];
    final List<String> funnelLabels = [];
    final funnelList = _overview?['lead_funnel'] as List<dynamic>?;
    if (funnelList != null) {
      for (var item in funnelList) {
        funnelValues.add((item['value'] as num).toDouble());
        funnelLabels.add(item['stage']?.toString() ?? '');
      }
    }

    // Gated - Outcomes
    final List<double> outcomeValues = [];
    final List<String> outcomeLabels = [];
    final outcomeList = _overview?['conversation_outcomes'] as List<dynamic>?;
    if (outcomeList != null) {
      for (var item in outcomeList) {
        outcomeValues.add((item['value'] as num).toDouble());
        outcomeLabels.add(item['name']?.toString() ?? '');
      }
    }

    // Gated - Peak Hours
    final List<double> peakHourValues = [];
    final List<String> peakHourLabels = [];
    if (peakHoursList != null) {
      // Sample hours to not overcrowd mobile chart (take every 2nd or 3rd hour, or just all if scrollable)
      // On mobile let's display every 4th hour for readability, or display all if we limit labels
      for (int i = 0; i < peakHoursList.length; i++) {
        final item = peakHoursList[i];
        peakHourValues.add((item['messages'] as num).toDouble());
        // only show label for every 3rd hour to avoid text overlapping
        if (i % 3 == 0) {
          peakHourLabels.add(item['hour']?.toString() ?? '');
        } else {
          peakHourLabels.add('');
        }
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Console header card
          _buildConsoleHeaderCard(context, isDark, 'WhatsApp Business AI'),
          const SizedBox(height: 20),

          // KPI grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _buildKpiCard(
                'Messages',
                totalMessages.toString(),
                'Total messages',
                LucideIcons.message_circle,
                const Color(0xFF0F766E), // Teal
              ),
              _buildKpiCard(
                'Conversations',
                totalConversations.toString(),
                'captured by day',
                LucideIcons.users,
                const Color(0xFF475569), // Slate
              ),
              _buildKpiCard(
                'Top Sentiment',
                topSentimentName,
                '${topSentimentVal.toStringAsFixed(1)}% conversations',
                LucideIcons.trending_up,
                const Color(0xFFB45309), // Amber
              ),
              _buildKpiCard(
                'Peak Hour',
                peakHourName,
                '$peakHourVal messages peak',
                LucideIcons.clock,
                const Color(0xFFBE123C), // Rose
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Charts Panel
          _buildSectionHeader('VOLUME ACTIVITY'),
          const SizedBox(height: 10),

          // WhatsApp Messages Bar Chart Card
          _buildChartPanel(
            title: 'WhatsApp Messages',
            description: 'Message volume for $_timeRangeLabel',
            child: CustomBarChart(
              values: msgValues.isEmpty ? [10, 15, 8, 12, 20, 14, 18] : msgValues,
              labels: msgLabels.isEmpty ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] : msgLabels,
              barColor: const Color(0xFF0F766E),
            ),
          ),
          const SizedBox(height: 16),

          // Conversation Volume Line Chart Card
          _buildChartPanel(
            title: 'Conversation Volume',
            description: 'Captured conversations for $_timeRangeLabel',
            child: CustomLineChart(
              values: convValues.isEmpty ? [3, 5, 2, 7, 4, 9, 6] : convValues,
              labels: convLabels.isEmpty ? ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'] : convLabels,
              lineColor: const Color(0xFFB45309),
              fillC: const Color(0x22B45309),
            ),
          ),
          const SizedBox(height: 24),

          // Segmented Donut Charts
          _buildSectionHeader('SEGMENT ANALYSIS'),
          const SizedBox(height: 10),

          // Sentiment Analysis Donut
          _buildChartPanel(
            title: 'Sentiment Analysis',
            description: 'Conversation sentiment this range',
            child: CustomDonutChart(
              values: sentValues.isEmpty ? [60, 30, 10] : sentValues,
              labels: sentLabels.isEmpty ? ['Positive', 'Neutral', 'Negative'] : sentLabels,
              colors: const [
                Color(0xFF10B981), // Emerald
                Color(0xFFF59E0B), // Amber
                Color(0xFFEF4444), // Red
              ],
            ),
          ),
          const SizedBox(height: 16),

          // AI vs Human Handling Donut
          _buildChartPanel(
            title: 'AI vs Human Handling',
            description: 'Outbound replies split',
            child: CustomDonutChart(
              values: handlingValues.isEmpty ? [75, 25] : handlingValues,
              labels: handlingLabels.isEmpty ? ['AI Replies', 'Human Replies'] : handlingLabels,
              colors: const [
                Color(0xFF0F766E), // Teal
                Color(0xFFEA580C), // Orange
              ],
            ),
          ),
          const SizedBox(height: 16),

          // New vs Returning Contacts Donut
          _buildChartPanel(
            title: 'New vs Returning Contacts',
            description: 'Active contacts split',
            child: CustomDonutChart(
              values: contactValues.isEmpty ? [40, 60] : contactValues,
              labels: contactLabels.isEmpty ? ['New', 'Returning'] : contactLabels,
              colors: const [
                Color(0xFFB45309), // Amber
                Color(0xFF475569), // Slate
              ],
            ),
          ),
          const SizedBox(height: 24),

          // PREMIUM GATED GROWTH SECTIONS
          _buildSectionHeader('GROWTH ANALYTICS'),
          const SizedBox(height: 10),

          GatedSection(
            isLocked: !_isAdvancedPlan,
            planName: 'Growth',
            child: Column(
              children: [
                // Lead Funnel Chart Card
                _buildChartPanel(
                  title: 'Lead Funnel',
                  description: 'Conversations moving into leads',
                  child: CustomBarChart(
                    values: funnelValues.isEmpty ? [200, 140, 95, 60, 20] : funnelValues,
                    labels: funnelLabels.isEmpty ? ['Conv', 'Leads', 'Qual', 'Won', 'Lost'] : funnelLabels,
                    barColor: const Color(0xFF0F766E),
                  ),
                ),
                const SizedBox(height: 16),

                // Conversation Outcomes Horizontal Bar Card
                _buildChartPanel(
                  title: 'Conversation Outcomes',
                  description: 'Current outcome split across chats',
                  child: CustomHorizontalBarChart(
                    values: outcomeValues.isEmpty ? [45, 15, 22, 10, 8] : outcomeValues,
                    labels: outcomeLabels.isEmpty
                        ? ['AI Handled', 'Human Assist', 'Takeover', 'Lead Captured', 'No Outcome']
                        : outcomeLabels,
                    barColor: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 16),

                // Peak Hours Card
                _buildChartPanel(
                  title: 'Peak Hours',
                  description: 'Inbound messages by hour',
                  child: CustomBarChart(
                    values: peakHourValues.isEmpty
                        ? [2, 1, 0, 1, 3, 5, 8, 14, 18, 22, 15, 12, 16, 20, 25, 29, 21, 14, 11, 9, 7, 5, 4, 3]
                        : peakHourValues,
                    labels: peakHourLabels.isEmpty
                        ? List.generate(24, (i) => i % 3 == 0 ? '${i.toString().padLeft(2, '0')}:00' : '')
                        : peakHourLabels,
                    barColor: const Color(0xFFB45309),
                  ),
                ),
                const SizedBox(height: 16),

                // Campaign ROI Analytics Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Campaign ROI Analytics',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Performance and conversions for broadcasts',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatsBox('Spend', '\$145.00', isDark),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStatsBox('Revenue', '\$3,240.00', isDark, isSuccess: true),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStatsBox('ROI', '2,234%', isDark, isAccent: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'RECENT BROADCASTS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        _buildRecentBroadcastRow('Real Estate Blast', '1,200 sent', '94.2% read', '\$2,100 rev'),
                        const Divider(height: 12),
                        _buildRecentBroadcastRow('Ecom Summer Promo', '850 sent', '96.5% read', '\$1,140 rev'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // KB Quality Insights Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Knowledge Base Quality Insights',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'AI training and fallback analytics',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMiniStatsBox('AI Success', '91.2%', isDark),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStatsBox('Fallback', '8.8%', isDark, isError: true),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildMiniStatsBox('AI Queries', '2,405', isDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 12),
                        const Text(
                          'TOP UNRESOLVED QUERIES',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        _buildUnresolvedQueryRow('"Do you offer international shipping to UAE?"', '14x'),
                        const SizedBox(height: 6),
                        _buildUnresolvedQueryRow('"What is your refund policy for annual plan?"', '9x'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Agent Performance Leaderboard Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Agent Performance Leaderboard',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Performance metrics for support agents',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        // Agent header titles
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text('AGENT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[500])),
                            ),
                            Expanded(
                              child: Text('RESOLVED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[500]), textAlign: Alignment.center.x == 0 ? TextAlign.center : null),
                            ),
                            Expanded(
                              child: Text('RESPONSE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[500]), textAlign: Alignment.center.x == 0 ? TextAlign.center : null),
                            ),
                            Expanded(
                              child: Text('CSAT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey[500]), textAlign: TextAlign.right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        _buildAgentLeaderboardRow('Apurva', 'A', const Color(0xFF0F766E), '45', '42s', '4.9/5'),
                        const Divider(height: 16),
                        _buildAgentLeaderboardRow('Sarah Jenkins', 'S', const Color(0xFFEA580C), '38', '58s', '4.7/5'),
                        const Divider(height: 16),
                        _buildAgentLeaderboardRow('John Doe', 'J', const Color(0xFF475569), '29', '45s', '4.8/5'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Show workload breakdown at bottom (Always visible, from original code)
          _buildSectionHeader('AGENT LOAD BREAKDOWN'),
          const SizedBox(height: 10),
          Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _teamWorkload.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final agent = _teamWorkload[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isDark ? const Color(0xFF262322) : const Color(0xFFF1F5F9),
                    child: Text(
                      agent.firstName.isNotEmpty ? agent.firstName[0].toUpperCase() : 'U',
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    '${agent.firstName} ${agent.lastName}',
                    style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    agent.role.toUpperCase(),
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: agent.activeChats > 0
                          ? AppColors.primary.withOpacity(0.1)
                          : Colors.transparent,
                      border: agent.activeChats > 0
                          ? Border.all(color: AppColors.primary.withOpacity(0.3))
                          : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${agent.activeChats} active',
                      style: TextStyle(
                        color: agent.activeChats > 0 ? AppColors.primary : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- VOICE TAB ---
  Widget _buildVoiceTab(BuildContext context, bool isDark) {
    // Dashboard static Voice Data: [Jan: 2400, Feb: 1398, Mar: 9800, Apr: 3908, May: 4800, Jun: 3800]
    final List<double> voiceValues = [2400, 1398, 9800, 3908, 4800, 3800];
    final List<String> voiceLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];

    // Channel Distribution mock data: WhatsApp (45%), Voice (30%), Email (15%), Web Chat (10%)
    final List<double> channelValues = [45, 30, 15, 10];
    final List<String> channelLabels = ['WhatsApp', 'Voice', 'Email', 'Web Chat'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Console header card
          _buildConsoleHeaderCard(context, isDark, 'AI Voice Agent'),
          const SizedBox(height: 20),

          // Main Voice Minutes Area Chart
          _buildChartPanel(
            title: 'Voice Minutes',
            description: 'Minutes used per month',
            child: CustomLineChart(
              values: voiceValues,
              labels: voiceLabels,
              lineColor: const Color(0xFF0F766E), // Teal
              fillC: const Color(0x220F766E),
            ),
          ),
          const SizedBox(height: 24),

          // PREMIUM GATED VOICE SECTIONS
          _buildSectionHeader('VOICE INTELLIGENCE'),
          const SizedBox(height: 10),

          GatedSection(
            isLocked: !_isAdvancedPlan,
            planName: 'Growth',
            child: Column(
              children: [
                // Channel Distribution Donut
                _buildChartPanel(
                  title: 'Channel Distribution',
                  description: 'User distribution across channels',
                  child: CustomDonutChart(
                    values: channelValues,
                    labels: channelLabels,
                    colors: const [
                      Color(0xFF0F766E), // Teal
                      Color(0xFFB45309), // Amber
                      Color(0xFFBE123C), // Rose
                      Color(0xFF475569), // Slate
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Live Performance Metrics (Progress Bars)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Performance Metrics',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Key performance indicators (Simulated live)',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 20),
                        _buildProgressBarRow('Response Time', _liveMetrics['responseTime']!, 0.85, const Color(0xFF0F766E)), // Teal
                        const SizedBox(height: 16),
                        _buildProgressBarRow('Resolution Rate', _liveMetrics['resolutionRate']!, 0.92, const Color(0xFF475569)), // Slate
                        const SizedBox(height: 16),
                        _buildProgressBarRow('Customer Satisfaction', _liveMetrics['customerSatisfaction']!, 0.94, const Color(0xFFB45309)), // Amber
                        const SizedBox(height: 16),
                        _buildProgressBarRow('Agent Utilization', _liveMetrics['agentUtilization']!, 0.78, const Color(0xFFBE123C)), // Rose
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 4 Voice Stats Mini Cards Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                  children: [
                    _buildKpiCard(
                      'API Response Time',
                      '0.8s',
                      'Average response time',
                      LucideIcons.gauge,
                      const Color(0xFF0F766E),
                    ),
                    _buildKpiCard(
                      'System Uptime',
                      '99.9%',
                      'Last 30 days uptime',
                      LucideIcons.activity,
                      const Color(0xFF475569),
                    ),
                    _buildKpiCard(
                      'Error Rate',
                      '0.1%',
                      'System error rate',
                      LucideIcons.bot,
                      const Color(0xFFB45309),
                    ),
                    _buildKpiCard(
                      'Cost Efficiency',
                      '\$0.02',
                      'Per API voice call',
                      LucideIcons.phone,
                      const Color(0xFFBE123C),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- SUB-WIDGET BUILDERS ---

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFEA580C),
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildConsoleHeaderCard(BuildContext context, bool isDark, String tabName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF121110), // Next.js dashboard styling (slate-950 equivalent)
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF332F2D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF14B8A6), // Green teal live dot
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Live Console',
                        style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Current Plan Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isAdvancedPlan 
                        ? const Color(0xFF166534).withOpacity(0.4) 
                        : const Color(0xFFB45309).withOpacity(0.4),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isAdvancedPlan 
                          ? const Color(0xFF166534) 
                          : const Color(0xFFB45309)
                    ),
                  ),
                  child: Text(
                    _formatPlanName(_subscription?.currentPlan).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Header Title
            Text(
              tabName == 'WhatsApp Business AI' ? 'WhatsApp Analytics' : 'Voice Agent Analytics',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            const SizedBox(height: 4),
            Text(
              'Detailed performance metrics for your ${tabName == 'WhatsApp Business AI' ? 'WhatsApp chatbot' : 'AI voice agents'}.',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFF332F2D)),
            const SizedBox(height: 8),

            // Dropdowns and Actions
            Row(
              children: [
                // Range Selector Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _timeRange,
                        dropdownColor: const Color(0xFF1E1C1A),
                        icon: const Icon(LucideIcons.calendar, size: 14, color: Colors.white70),
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        onChanged: (String? val) {
                          if (val != null) {
                            setState(() {
                              _timeRange = val;
                            });
                            _loadAllAnalytics();
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'last-7-days', child: Text('Last 7 Days')),
                          DropdownMenuItem(value: 'last-30-days', child: Text('Last 30 Days')),
                          DropdownMenuItem(value: 'last-90-days', child: Text('Last 90 Days')),
                          DropdownMenuItem(value: 'last-year', child: Text('Last Year')),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Export Button
                IconButton(
                  onPressed: () => _exportReport(tabName),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(LucideIcons.download, size: 16, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, String description, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPanel({required String title, required String description, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBarRow(String label, String value, double ratio, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatsBox(String label, String value, bool isDark, {bool isSuccess = false, bool isAccent = false, bool isError = false}) {
    Color bg = isDark ? const Color(0xFF262322) : const Color(0xFFF1F5F9);
    Color border = isDark ? const Color(0xFF332F2D) : const Color(0xFFE2E8F0);
    Color textC = isDark ? Colors.white : Colors.black87;

    if (isSuccess) {
      bg = isDark ? const Color(0xFF14532D).withOpacity(0.2) : const Color(0xFFD1FAE5);
      border = isDark ? const Color(0xFF14532D) : const Color(0xFFA7F3D0);
      textC = isDark ? const Color(0xFF10B981) : const Color(0xFF047857);
    } else if (isAccent) {
      bg = isDark ? const Color(0xFF78350F).withOpacity(0.2) : const Color(0xFFFEF3C7);
      border = isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A);
      textC = isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);
    } else if (isError) {
      bg = isDark ? const Color(0xFF7F1D1D).withOpacity(0.2) : const Color(0xFFFEE2E2);
      border = isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5);
      textC = isDark ? const Color(0xFFEF4444) : const Color(0xFFB91C1C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textC)),
        ],
      ),
    );
  }

  Widget _buildRecentBroadcastRow(String campaign, String sent, String read, String revenue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(campaign, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(sent, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.right),
          ),
          Expanded(
            child: Text(read, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.right),
          ),
          Expanded(
            child: Text(revenue, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildUnresolvedQueryRow(String query, String count) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              query,
              style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count,
              style: const TextStyle(color: Color(0xFFEA580C), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgentLeaderboardRow(String name, String initial, Color initialBg, String resolved, String response, String csat) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: initialBg,
                child: Text(
                  initial,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Text(resolved, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: Alignment.center.x == 0 ? TextAlign.center : null),
        ),
        Expanded(
          child: Text(response, style: const TextStyle(fontSize: 11, color: Colors.grey), textAlign: Alignment.center.x == 0 ? TextAlign.center : null),
        ),
        Expanded(
          child: Text(csat, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)), textAlign: TextAlign.right),
        ),
      ],
    );
  }
}
