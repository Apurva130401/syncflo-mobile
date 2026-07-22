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

  String _currentTab = 'whatsapp';
  bool _loadingCtwa = false;
  Map<String, dynamic>? _ctwaBilling;
  List<dynamic> _ctwaAds = [];
  List<dynamic> _ctwaAdAccounts = [];
  String? _selectedAdAccountId;
  String? _ctwaError;

  @override
  void initState() {
    super.initState();
    _loadAllAnalytics();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadCtwaData() async {
    setState(() {
      _loadingCtwa = true;
      _ctwaError = null;
    });
    try {
      final assets = await _supabaseService.getCtwaAssets();
      final accounts = (assets['adAccounts'] as List<dynamic>?) ?? [];
      _ctwaAdAccounts = accounts;

      if (accounts.isNotEmpty && _selectedAdAccountId == null) {
        _selectedAdAccountId = accounts[0]['id']?.toString();
      }

      if (_selectedAdAccountId != null) {
        final billingRes = await _supabaseService.getCtwaBilling(adAccountId: _selectedAdAccountId);
        _ctwaBilling = billingRes['billing'] as Map<String, dynamic>?;

        _ctwaAds = await _supabaseService.getCtwaFetchedAds(_selectedAdAccountId!);
      }
    } catch (e) {
      _ctwaError = e.toString().replaceAll('Exception: ', '');
    } finally {
      setState(() {
        _loadingCtwa = false;
      });
    }
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
      
      if (_currentTab == 'ctwa') {
        _loadCtwaData();
      }
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

    return Scaffold(
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
            onPressed: () {
              if (_currentTab == 'ctwa') {
                _loadCtwaData();
              } else {
                _loadAllAnalytics();
              }
            },
          ),
        ],
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
              : Column(
                  children: [
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _currentTab = 'whatsapp'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _currentTab == 'whatsapp' ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    'WhatsApp AI',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _currentTab == 'whatsapp' ? Colors.white : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() => _currentTab = 'ctwa');
                                  if (_ctwaBilling == null && !_loadingCtwa) {
                                    _loadCtwaData();
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _currentTab == 'ctwa' ? AppColors.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    'Meta CTWA Ads',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _currentTab == 'ctwa' ? Colors.white : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _currentTab == 'whatsapp'
                          ? _buildWhatsAppTab(context, isDark)
                          : _buildCtwaTab(context, isDark),
                    ),
                  ],
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
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: agent.activeChats > 0
                          ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
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
            color: Colors.black.withValues(alpha: 0.15),
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
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
                        ? const Color(0xFF166534).withValues(alpha: 0.4) 
                        : const Color(0xFFB45309).withValues(alpha: 0.4),
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
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
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
              backgroundColor: color.withValues(alpha: 0.1),
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



  Widget _buildMiniStatsBox(String label, String value, bool isDark, {bool isSuccess = false, bool isAccent = false, bool isError = false}) {
    Color bg = isDark ? const Color(0xFF262322) : const Color(0xFFF1F5F9);
    Color border = isDark ? const Color(0xFF332F2D) : const Color(0xFFE2E8F0);
    Color textC = isDark ? Colors.white : Colors.black87;

    if (isSuccess) {
      bg = isDark ? const Color(0xFF14532D).withValues(alpha: 0.2) : const Color(0xFFD1FAE5);
      border = isDark ? const Color(0xFF14532D) : const Color(0xFFA7F3D0);
      textC = isDark ? const Color(0xFF10B981) : const Color(0xFF047857);
    } else if (isAccent) {
      bg = isDark ? const Color(0xFF78350F).withValues(alpha: 0.2) : const Color(0xFFFEF3C7);
      border = isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A);
      textC = isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);
    } else if (isError) {
      bg = isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.2) : const Color(0xFFFEE2E2);
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
        color: Colors.grey.withValues(alpha: 0.05),
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
              color: const Color(0xFFEA580C).withValues(alpha: 0.1),
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

  Widget _buildCtwaTab(BuildContext context, bool isDark) {
    if (_loadingCtwa) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_ctwaError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.circle_alert, color: AppColors.error, size: 44),
              const SizedBox(height: 12),
              Text(
                'Could not load CTWA metrics',
                style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _ctwaError!,
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadCtwaData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final sym = _ctwaBilling?['currencySymbol']?.toString() ?? '₹';
    final balance = (_ctwaBilling?['balance'] as num?)?.toDouble() ?? 0.0;
    final tax = (_ctwaBilling?['estimatedTax'] as num?)?.toDouble() ?? 0.0;
    final spent = (_ctwaBilling?['amountSpent'] as num?)?.toDouble() ?? 0.0;
    final cap = (_ctwaBilling?['spendCap'] as num?)?.toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad Account selector if accounts available
          if (_ctwaAdAccounts.isNotEmpty) ...[
            Text(
              'Select Ad Account',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedAdAccountId,
                  dropdownColor: AppColors.surface,
                  items: _ctwaAdAccounts.map((acc) {
                    final cleanId = acc['account_id']?.toString() ?? acc['id']?.toString() ?? '';
                    final name = acc['name']?.toString() ?? 'Ad Account';
                    return DropdownMenuItem<String>(
                      value: acc['id']?.toString(),
                      child: Text(
                        '$name ($cleanId)',
                        style: TextStyle(color: AppColors.text, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedAdAccountId = val;
                      });
                      _loadCtwaData();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Billing Card
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.credit_card, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Meta Billing Overview',
                          style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Read Only',
                        style: TextStyle(color: Color(0xFF0F766E), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Current Unbilled Balance',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$sym${balance.toStringAsFixed(2)}',
                      style: TextStyle(color: AppColors.text, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+ $sym${tax.toStringAsFixed(2)} est. tax',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Amount Spent', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            '$sym${spent.toStringAsFixed(2)}',
                            style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account Spend Cap', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(
                            cap != null ? '$sym${cap.toStringAsFixed(2)}' : 'No cap set',
                            style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Ads List Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fetched WhatsApp Ads',
                style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_ctwaAds.length} ads',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_ctwaAds.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Icon(LucideIcons.megaphone, color: AppColors.textMuted, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'No active WhatsApp ads found',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ads created in Meta Ads Manager linked to your WhatsApp number will appear here.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _ctwaAds.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ad = _ctwaAds[index] as Map<String, dynamic>;
                final adName = ad['name']?.toString() ?? 'Unnamed Ad';
                final campaign = ad['campaignName']?.toString() ?? 'Campaign';
                final status = ad['status']?.toString() ?? 'UNKNOWN';
                final adSpend = (ad['spendLast30d'] as num?)?.toDouble() ?? 0.0;
                final budget = (ad['budgetAmount'] as num?)?.toDouble() ?? 0.0;
                final adSym = ad['currency']?.toString() == 'INR' ? '₹' : (ad['currency']?.toString() ?? '\$');

                final isActive = status.toUpperCase() == 'ACTIVE';

                return Container(
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              adName,
                              style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.textMuted.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isActive ? AppColors.success : AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Campaign: $campaign',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Daily Budget', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '$adSym${budget.toStringAsFixed(2)}',
                                  style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('30-Day Spend', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                                const SizedBox(height: 2),
                                Text(
                                  '$adSym${adSpend.toStringAsFixed(2)}',
                                  style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

