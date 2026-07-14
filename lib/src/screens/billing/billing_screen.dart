import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  Subscription? _subscription;
  UserUsage? _usage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBilling();
  }

  Future<void> _loadBilling() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _supabaseService.getSubscription(),
        _supabaseService.getUserUsage(),
      ]);
      setState(() {
        _subscription = results[0] as Subscription?;
        _usage = results[1] as UserUsage?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _launchPortal() async {
    final url = Uri.parse('https://dashboard.syncflo.xyz/dashboard/billing');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open portal link.')),
        );
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '—';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return dateStr.length >= 10 ? dateStr.substring(0, 10) : dateStr;
    }
  }

  String _formatPlanName(String? plan) {
    if (plan == null || plan.isEmpty) return 'No Plan';
    return plan.replaceAll('-', ' ').split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'trial':
        return AppColors.accent;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing & Usage'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refresh_cw),
            onPressed: _loadBilling,
          ),
        ],
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/billing'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.triangle_alert, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load billing data',
                          style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _loadBilling, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _subscription == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.credit_card, color: AppColors.textMuted, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            'No subscription found',
                            style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Visit the web dashboard to set up your plan.',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(onPressed: _launchPortal, child: const Text('Open Dashboard')),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Plan Header Card
                          Card(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              side: BorderSide(color: AppColors.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 24,
                                        backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                        child: Icon(LucideIcons.credit_card, color: AppColors.primary, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'CURRENT PLAN',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _formatPlanName(_subscription!.currentPlan),
                                              style: TextStyle(
                                                color: AppColors.text,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(_subscription!.subscriptionStatus).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _statusColor(_subscription!.subscriptionStatus).withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          _subscription!.subscriptionStatus.toUpperCase(),
                                          style: TextStyle(
                                            color: _statusColor(_subscription!.subscriptionStatus),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 8),
                                  // Subscription details row
                                  _buildDetailRow('Billing Cycle', (_subscription!.billingCycle ?? '—').toUpperCase()),
                                  _buildDetailRow('Start Date', _formatDate(_subscription!.subscriptionStartDate)),
                                  _buildDetailRow('End Date', _formatDate(_subscription!.subscriptionEndDate)),
                                  if (_subscription!.trialEndDate != null)
                                    _buildDetailRow('Trial Ends', _formatDate(_subscription!.trialEndDate)),
                                  if (_subscription!.cancelAtPeriodEnd)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(LucideIcons.triangle_alert, size: 14, color: AppColors.error),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Subscription will cancel at end of billing period',
                                                style: TextStyle(color: AppColors.error, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Usage section
                          if (_usage != null) ...[
                            Text(
                              'USAGE METRICS',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Message credits usage
                            _buildUsageCard(
                              'Message Credits',
                              _usage!.usedMessages,
                              _usage!.messageCredits,
                              LucideIcons.message_square,
                            ),
                            const SizedBox(height: 12),
                            // Voice minutes usage
                            if (_usage!.minuteCredits > 0)
                              _buildUsageCard(
                                'Voice Minutes',
                                _usage!.usedVoice,
                                _usage!.minuteCredits,
                                LucideIcons.phone,
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'Period: ${_formatDate(_usage!.periodStart)} — ${_formatDate(_usage!.periodEnd)}',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ] else ...[
                            Text(
                              'USAGE METRICS',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Icon(LucideIcons.info, color: AppColors.textMuted, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Usage data is not yet available for this billing period.',
                                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          // WhatsApp & Voice product statuses
                          const SizedBox(height: 24),
                          Text(
                            'PRODUCT STATUS',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  _buildProductRow(
                                    'WhatsApp',
                                    _subscription!.whatsappSubscriptionStatus ?? 'inactive',
                                    LucideIcons.message_circle,
                                  ),
                                  const Divider(),
                                  _buildProductRow(
                                    'Voice',
                                    _subscription!.voiceSubscriptionStatus ?? 'inactive',
                                    LucideIcons.phone,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _launchPortal,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surfaceLight,
                                foregroundColor: AppColors.text,
                                side: BorderSide(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Manage Subscription'),
                                  const SizedBox(width: 8),
                                  Icon(LucideIcons.external_link, size: 16, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Text(value, style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildUsageCard(String title, int used, int total, IconData icon) {
    final double ratio = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final Color barColor = ratio > 0.9
        ? AppColors.error
        : ratio > 0.7
            ? AppColors.accent
            : AppColors.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: barColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '$used / $total',
                  style: TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(ratio * 100).toStringAsFixed(1)}% used',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductRow(String name, String status, IconData icon) {
    final isActive = status == 'active';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isActive ? AppColors.success : AppColors.textMuted),
          const SizedBox(width: 12),
          Text(name, style: TextStyle(color: AppColors.text, fontSize: 14)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (isActive ? AppColors.success : AppColors.textMuted).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                color: isActive ? AppColors.success : AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
