import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../widgets/navigation_drawer.dart';

class CtwaScreen extends StatefulWidget {
  const CtwaScreen({super.key});

  @override
  State<CtwaScreen> createState() => _CtwaScreenState();
}

class _CtwaScreenState extends State<CtwaScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  bool _loadingCtwa = false;
  Map<String, dynamic>? _ctwaBilling;
  List<dynamic> _ctwaAds = [];
  List<dynamic> _ctwaAdAccounts = [];
  String? _selectedAdAccountId;
  String? _ctwaError;

  @override
  void initState() {
    super.initState();
    _loadCtwaData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meta CTWA'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refresh_cw),
            onPressed: _loadCtwaData,
          ),
        ],
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/ctwa'),
      body: _loadingCtwa
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _ctwaError != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.circle_alert, color: AppColors.error, size: 48),
            const SizedBox(height: 16),
            Text(
              'Could not load CTWA data',
              style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _ctwaError!,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadCtwaData,
              icon: const Icon(LucideIcons.refresh_cw, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final sym = _ctwaBilling?['currencySymbol']?.toString() ?? '₹';
    final balance = (_ctwaBilling?['balance'] as num?)?.toDouble() ?? 0.0;
    final tax = (_ctwaBilling?['estimatedTax'] as num?)?.toDouble() ?? 0.0;
    final spent = (_ctwaBilling?['amountSpent'] as num?)?.toDouble() ?? 0.0;
    final cap = (_ctwaBilling?['spendCap'] as num?)?.toDouble();

    // Compute aggregate analytics from ads list
    double totalImpressions = 0;
    double totalClicks = 0;
    double totalSpend = 0;
    int activeAds = 0;
    for (final ad in _ctwaAds) {
      final adMap = ad as Map<String, dynamic>;
      totalImpressions += (adMap['impressions'] as num?)?.toDouble() ?? 0.0;
      totalClicks += (adMap['clicks'] as num?)?.toDouble() ?? 0.0;
      totalSpend += (adMap['spendLast30d'] as num?)?.toDouble() ?? 0.0;
      if ((adMap['status']?.toString() ?? '').toUpperCase() == 'ACTIVE') activeAds++;
    }
    final avgCtr = totalImpressions > 0 ? (totalClicks / totalImpressions * 100) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ad Account Selector
          if (_ctwaAdAccounts.isNotEmpty) ...[
            Text(
              'Ad Account',
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
                      setState(() => _selectedAdAccountId = val);
                      _loadCtwaData();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // --- ANALYTICS SECTION ---
          _buildSectionHeader('CAMPAIGN ANALYTICS'),
          const SizedBox(height: 10),

          // KPI Summary Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _buildKpiCard(
                'Active Ads',
                '$activeAds',
                '${_ctwaAds.length} total ads',
                LucideIcons.megaphone,
                const Color(0xFF0F766E),
              ),
              _buildKpiCard(
                '30-Day Spend',
                '$sym${totalSpend.toStringAsFixed(2)}',
                'Across all ads',
                LucideIcons.credit_card,
                const Color(0xFFEA580C),
              ),
              _buildKpiCard(
                'Impressions',
                totalImpressions > 0 ? _formatNumber(totalImpressions) : '—',
                'Total ad impressions',
                LucideIcons.eye,
                const Color(0xFF475569),
              ),
              _buildKpiCard(
                'Avg. CTR',
                totalImpressions > 0 ? '${avgCtr.toStringAsFixed(2)}%' : '—',
                '${totalClicks > 0 ? _formatNumber(totalClicks) : "—"} total clicks',
                LucideIcons.trending_up,
                const Color(0xFFB45309),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- BILLING SECTION ---
          _buildSectionHeader('META BILLING'),
          const SizedBox(height: 10),
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
                          'Billing Overview',
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

          // --- ADS LIST SECTION ---
          _buildSectionHeader('AD PERFORMANCE'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WhatsApp Ads',
                style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_ctwaAds.length} ads',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),

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
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ad = _ctwaAds[index] as Map<String, dynamic>;
                final adName = ad['name']?.toString() ?? 'Unnamed Ad';
                final campaign = ad['campaignName']?.toString() ?? 'Campaign';
                final status = ad['status']?.toString() ?? 'UNKNOWN';
                final adSpend = (ad['spendLast30d'] as num?)?.toDouble() ?? 0.0;
                final budget = (ad['budgetAmount'] as num?)?.toDouble() ?? 0.0;
                final adSym = ad['currency']?.toString() == 'INR' ? '₹' : (ad['currency']?.toString() ?? '\$');

                final impressions = (ad['impressions'] as num?)?.toDouble();
                final clicks = (ad['clicks'] as num?)?.toDouble();
                final reach = (ad['reach'] as num?)?.toDouble();
                final ctr = (impressions != null && impressions > 0 && clicks != null)
                    ? (clicks / impressions * 100)
                    : null;

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
                      // Ad header row
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
                      const Divider(height: 1),
                      const SizedBox(height: 12),

                      // Analytics grid
                      Row(
                        children: [
                          _buildAdStatCell('Daily Budget', '$adSym${budget.toStringAsFixed(2)}'),
                          _buildAdStatCell('30-Day Spend', '$adSym${adSpend.toStringAsFixed(2)}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildAdStatCell(
                            'Impressions',
                            impressions != null ? _formatNumber(impressions) : '—',
                          ),
                          _buildAdStatCell(
                            'Clicks',
                            clicks != null ? _formatNumber(clicks) : '—',
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildAdStatCell(
                            'CTR',
                            ctr != null ? '${ctr.toStringAsFixed(2)}%' : '—',
                          ),
                          _buildAdStatCell(
                            'Reach',
                            reach != null ? _formatNumber(reach) : '—',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

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

  Widget _buildAdStatCell(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(color: AppColors.text, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toInt().toString();
  }
}
