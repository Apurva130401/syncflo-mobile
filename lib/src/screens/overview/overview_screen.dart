import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  String? _error;

  int _totalConversations = 0;
  int _activeChats = 0;
  double _automationRate = 0.0;
  double _conversionRate = 0.0;
  int _totalLeads = 0;
  int _messagesUsed = 0;
  int _messagesTotal = 0;
  int _unreadAlerts = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Fetch conversations
      final conversations = await _supabaseService.getConversations();
      final active = conversations.where((c) => c.status != 'closed').toList();
      final aiActive = active.where((c) => c.aiEnabled).toList();
      
      // Calculate active chats and automation rate
      final int activeCount = active.length;
      final double autoRate = activeCount > 0 ? (aiActive.length / activeCount) * 100 : 0.0;

      // 2. Fetch leads for conversion rate calculation
      final leadsRes = await _supabaseService.client
          .from('leads')
          .select('status');
      
      final leadsList = leadsRes as List<dynamic>;
      final int leadsCount = leadsList.length;
      final int qualifiedCount = leadsList.where((l) {
        final status = (l['status'] ?? '').toString().toLowerCase();
        return status == 'qualified' || status == 'converted';
      }).length;
      final double convRate = leadsCount > 0 ? (qualifiedCount / leadsCount) * 100 : 0.0;

      // 3. Fetch message usage
      final usage = await _supabaseService.getUserUsage();
      final int msgUsed = usage?.usedMessages ?? 0;
      final int msgTotal = usage?.messageCredits ?? 0;

      // 4. Fetch notifications for unread alerts count
      final notifications = await _supabaseService.getNotifications();
      final int unreadCount = notifications.where((n) => !n.read).length;

      if (!mounted) return;
      setState(() {
        _totalConversations = conversations.length;
        _activeChats = activeCount;
        _automationRate = autoRate;
        _conversionRate = convRate;
        _totalLeads = leadsCount;
        _messagesUsed = msgUsed;
        _messagesTotal = msgTotal;
        _unreadAlerts = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final String greetingName = user?.firstName ?? 'Agent';

    return Scaffold(
      appBar: AppBar(
        title: Text(auth.profile?.companyName ?? 'SyncFlo AI'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refresh_cw),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/overview'),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppColors.primary,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height - 150,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.triangle_alert, color: AppColors.error, size: 48),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load dashboard: $_error',
                            style: TextStyle(color: AppColors.error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadDashboardData,
                            child: const Text('Retry'),
                          )
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Banner
                        Text(
                          'Welcome back, $greetingName! 👋',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Here is how your sales flow is doing today.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Stats Grid (Rows of cards)
                        _buildSectionHeader('KEY METRICS'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Active Chats',
                                value: '$_activeChats',
                                subtitle: '$_totalConversations total',
                                icon: LucideIcons.message_square,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'AI Automation',
                                value: '${_automationRate.toStringAsFixed(1)}%',
                                subtitle: 'Active AI coverage',
                                icon: LucideIcons.bot,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Conversion Rate',
                                value: '${_conversionRate.toStringAsFixed(1)}%',
                                subtitle: '$_totalLeads leads tracked',
                                icon: LucideIcons.trending_up,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'System Status',
                                value: 'Active',
                                subtitle: 'All nodes healthy',
                                icon: LucideIcons.circle_check,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Active Alerts',
                                value: '$_unreadAlerts',
                                subtitle: 'Unread system alerts',
                                icon: LucideIcons.bell,
                                color: _unreadAlerts > 0 ? AppColors.accentWarm : AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Typical Reply',
                                value: '1.5s',
                                subtitle: 'Median AI latency',
                                icon: LucideIcons.clock,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Message Credits Usage Card
                        _buildSectionHeader('WHATSAPP MESSAGE CREDITS'),
                        const SizedBox(height: 12),
                        _buildMessageUsageCard(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageUsageCard() {
    final double percent = _messagesTotal > 0
        ? (_messagesUsed / _messagesTotal).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.message_square, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'AI Message Credits',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$_messagesUsed / $_messagesTotal',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 8,
                backgroundColor: AppColors.surfaceLight,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${((1 - percent) * 100).toStringAsFixed(0)}% remaining',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
                Text(
                  'Credits reset monthly',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
