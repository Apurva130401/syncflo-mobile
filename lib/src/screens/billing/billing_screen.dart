import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

const _siteUrl = 'https://dashboard.syncflo.xyz';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final SupabaseService _service = SupabaseService();
  bool _loading = true;
  BillingSummary? _summary;
  UserUsage? _usage;
  String? _error;
  bool _showAllInvoices = false;

  // Show everything up to this many; beyond it, collapse the older ones behind a button.
  static const _invoicePreview = 8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _service.getBillingSummary(),
        // Usage is a nice-to-have: a failure here must not hide the plan.
        _service.getUserUsage().then<UserUsage?>((u) => u).catchError((_) => null),
      ]);
      if (!mounted) return;
      setState(() {
        _summary = results[0] as BillingSummary;
        _usage = results[1] as UserUsage?;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _open(String path) async {
    final ok = await launchUrl(Uri.parse('$_siteUrl$path'), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the link.')));
    }
  }

  // ---------------------------------------------------------------------------
  // Formatting
  // ---------------------------------------------------------------------------

  DateTime? _date(String? iso) => iso == null || iso.isEmpty ? null : DateTime.tryParse(iso)?.toLocal();

  String? _fmt(String? iso) {
    final d = _date(iso);
    return d == null ? null : DateFormat('MMM d, yyyy').format(d);
  }

  String _money(double value, String? currency) {
    final inr = currency?.toUpperCase() == 'INR';
    final whole = value == value.roundToDouble();
    return NumberFormat.currency(
      locale: inr ? 'en_IN' : 'en_US',
      symbol: inr ? '₹' : '\$',
      decimalDigits: whole ? 0 : 2,
    ).format(value);
  }

  String _planName(String? id) {
    if (id == null || id.isEmpty) return 'No plan';
    const names = {
      'whatsapp-starter': 'Starter',
      'whatsapp-growth': 'Growth',
      'whatsapp-custom': 'Custom',
      'whatsapp-business': 'Growth',
      'whatsapp-enterprise': 'Custom',
      'whatsapp-trial': 'Free trial',
    };
    if (names.containsKey(id)) return names[id]!;
    final bare = id.replaceFirst(RegExp(r'^(whatsapp|voice|suite)-'), '').replaceAll('-', ' ');
    return bare.isEmpty ? id : bare[0].toUpperCase() + bare.substring(1);
  }

  String _product(String? id) {
    if (id == null) return 'SyncFlo AI';
    if (id.startsWith('voice-')) return 'AI Voice Agent';
    if (id.startsWith('suite-')) return 'Full AI Business Suite';
    return 'WhatsApp AI';
  }

  String? _cycle(String? c) {
    if (c == null) return null;
    final v = c.toLowerCase();
    if (v.contains('year') || v == 'annual') return 'yearly';
    if (v.contains('day')) return 'daily';
    if (v.contains('month')) return 'monthly';
    return null;
  }

  String _daysText(DateTime end) {
    final days = end.difference(DateTime.now()).inHours ~/ 24;
    if (end.isBefore(DateTime.now())) return '';
    if (days <= 0) return 'today';
    if (days == 1) return 'tomorrow';
    return 'in $days days';
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

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
          IconButton(icon: Icon(LucideIcons.refresh_cw, size: 20), onPressed: _load),
        ],
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/billing'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _load(silent: true),
                  child: _buildContent(),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'We couldn’t load your billing',
                style: TextStyle(color: AppColors.text, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
              ),
              const SizedBox(height: 12),
              Text(
                'Nothing has changed with your plan or payments. $_error',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.45),
              ),
              const SizedBox(height: 24),
              _solidButton('Try again', _load),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    final sub = summary.sub;

    final end = _date(sub?.endDate);
    var status = sub?.status;
    // An "active" row whose paid period is over is really expired (same rule as the web page).
    if (status == 'active' && end != null && end.isBefore(DateTime.now())) status = 'expired';

    final hasPlan = status == 'active' || status == 'past_due';
    final failed = status == 'past_due';
    final cancelling = hasPlan && sub!.cancelAtPeriodEnd && status == 'active';
    final planId = sub?.planId ?? sub?.currentPlan;
    final onTrial = status == 'trial' && planId == 'whatsapp-trial';
    final cycle = _cycle(sub?.billingCycle) ?? 'monthly';

    final paid = summary.payments.where((p) => p.isPaid).toList();
    final lastPaid = paid.isEmpty ? null : paid.first;
    final method = summary.methods.isEmpty
        ? null
        : summary.methods.firstWhere((m) => m.isDefault, orElse: () => summary.methods.first);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _page([
          if (failed)
            _notice(
              lead: 'Your last payment didn’t go through.',
              rest: 'Update your payment method to keep your plan running.',
              color: AppColors.error,
              action: 'Fix payment',
              onAction: () => _open('/dashboard/billing'),
            ),
          if (cancelling)
            _notice(
              lead: 'Your plan ends on ${_fmt(sub.endDate) ?? 'the renewal date'}.',
              rest: 'It won’t renew. You keep everything until then.',
              color: AppColors.warning,
              action: 'Keep my plan',
              onAction: () => _open('/dashboard/billing'),
            ),
          if (hasPlan && sub!.scheduledPlanId != null)
            _notice(
              lead: sub.scheduledPlanId == planId ? 'Billing switch scheduled.' : 'Plan change scheduled.',
              rest: sub.scheduledPlanId == planId
                  ? 'You’ll be billed ${sub.scheduledBillingCycle ?? 'on a new cycle'} from ${_fmt(sub.scheduledChangeAt) ?? 'your next renewal'}.'
                  : 'You move to ${sub.scheduledPlanName ?? 'your new plan'} on ${_fmt(sub.scheduledChangeAt) ?? 'your next renewal'}.',
              color: AppColors.warning,
              action: 'Manage plans',
              onAction: () => _open('/plans'),
            ),
        ]),
        if (hasPlan) _planField(sub!, planId, cycle, end, lastPaid, cancelling, failed) else _noPlanField(status, onTrial, end),
        _page([
          if (_usage != null) _usageSection(_usage!),
          if (hasPlan) _nextPayment(lastPaid, end, cancelling, failed, method),
          _methodsSection(summary.methods),
          _invoicesSection(summary.payments, paid),
          _help(),
        ]),
      ],
    );
  }

  /// Centres content in a readable column on wide screens, with the same side margins everywhere.
  Widget _page(List<Widget> children) {
    final visible = children;
    if (visible.isEmpty) return const SizedBox.shrink();
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: visible),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // The plan: one field of the brand colour, the biggest thing on the screen
  // ---------------------------------------------------------------------------

  Widget _planField(
    BillingSub sub,
    String? planId,
    String cycle,
    DateTime? end,
    BillingPayment? lastPaid,
    bool cancelling,
    bool failed,
  ) {
    final ink = AppColors.textInverse;
    final soft = ink.withValues(alpha: 0.78);

    double? elapsed;
    if (end != null) {
      final start = cycle == 'yearly'
          ? DateTime(end.year - 1, end.month, end.day)
          : cycle == 'daily'
              ? end.subtract(const Duration(days: 1))
              : DateTime(end.year, end.month - 1, end.day);
      final total = end.difference(start).inSeconds;
      if (total > 0) elapsed = (DateTime.now().difference(start).inSeconds / total).clamp(0.0, 1.0);
    }
    final countdown = end == null ? '' : _daysText(end);

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _planName(planId),
                  style: TextStyle(color: ink, fontSize: 52, fontWeight: FontWeight.w800, height: 1.0, letterSpacing: -1.8),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your ${_product(planId)} plan, billed $cycle',
                  style: TextStyle(color: soft, fontSize: 16, height: 1.4),
                ),
                if (lastPaid != null) ...[
                  const SizedBox(height: 24),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _money(lastPaid.amount, lastPaid.currency),
                          style: TextStyle(color: ink, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                        ),
                        TextSpan(
                          text: cycle == 'yearly' ? ' a year' : ' a month',
                          style: TextStyle(color: soft, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
                if (end != null) ...[
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${cancelling ? 'Ends' : failed ? 'Was due' : 'Renews'} ${_fmt(sub.endDate)}',
                          style: TextStyle(color: ink, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (countdown.isNotEmpty) Text(countdown, style: TextStyle(color: soft, fontSize: 16)),
                    ],
                  ),
                  if (elapsed != null) ...[
                    const SizedBox(height: 10),
                    _bar(elapsed, fill: ink, track: ink.withValues(alpha: 0.25)),
                  ],
                ],
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _fieldButton('Change plan', () => _open('/plans'), fill: ink, label: AppColors.primary),
                    _fieldButton('Manage billing', () => _open('/dashboard/billing'), fill: ink.withValues(alpha: 0.18), label: ink),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _noPlanField(String? status, bool onTrial, DateTime? end) {
    final title = onTrial
        ? 'You’re on the free trial'
        : status == 'expired' || status == 'cancelled'
            ? 'Your plan has ended'
            : 'You don’t have an active plan';
    final body = onTrial
        ? 'No card needed. Your trial runs until ${_fmt(end?.toIso8601String()) ?? 'the end of the trial'}. Pick a plan any time to keep your WhatsApp AI running after that.'
        : status == 'expired' || status == 'cancelled'
            ? 'Pick a plan to switch your WhatsApp AI back on. Your past invoices are below.'
            : 'Pick a plan to switch on your WhatsApp AI. Your invoices show up here after your first payment.';
    final ink = AppColors.textInverse;

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: ink, fontSize: 36, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -1.2),
                ),
                const SizedBox(height: 14),
                Text(body, style: TextStyle(color: ink.withValues(alpha: 0.85), fontSize: 16, height: 1.5)),
                const SizedBox(height: 24),
                _fieldButton('See plans', () => _open('/plans'), fill: ink, label: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sections
  // ---------------------------------------------------------------------------

  Widget _heading(String text) => Padding(
        padding: const EdgeInsets.only(top: 44, bottom: 14),
        child: Text(
          text,
          style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15),
        ),
      );

  Widget _usageSection(UserUsage u) {
    final resets = _fmt(u.periodEnd);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('This month'),
        _meter(
          used: u.usedMessages,
          total: u.messageCredits,
          unit: 'AI messages',
        ),
        if (u.minuteCredits > 0) ...[
          const SizedBox(height: 28),
          _meter(used: u.usedVoice, total: u.minuteCredits, unit: 'voice minutes'),
        ],
        if (resets != null) ...[
          const SizedBox(height: 16),
          Text('Credits reset on $resets.', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        ],
      ],
    );
  }

  Widget _meter({required int used, required int total, required String unit}) {
    final ratio = total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0;
    final fill = ratio > 0.9
        ? AppColors.error
        : ratio > 0.7
            ? AppColors.accent
            : AppColors.primary;
    final nf = NumberFormat.decimalPattern();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: nf.format(used),
                style: TextStyle(color: AppColors.text, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.4, height: 1.0),
              ),
              TextSpan(
                text: '  of ${nf.format(total)} $unit',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _bar(ratio, fill: fill, track: AppColors.surfaceLight),
      ],
    );
  }

  Widget _nextPayment(BillingPayment? lastPaid, DateTime? end, bool cancelling, bool failed, BillingMethod? method) {
    final amount = cancelling
        ? 'None'
        : lastPaid != null
            ? _money(lastPaid.amount, lastPaid.currency)
            : '—';
    final when = _fmt(end?.toIso8601String()) ?? 'your renewal date';
    final sentence = cancelling
        ? 'Your plan stops on $when.'
        : failed
            ? 'Was due on $when. It’s charged again once your payment method is fixed.'
            : 'On $when${method != null ? ', from your ${method.label}' : ''}.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(failed ? 'Payment due' : 'Next payment'),
        Container(
          width: double.infinity,
          color: AppColors.surfaceLight,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                amount,
                style: TextStyle(color: AppColors.text, fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.2, height: 1.0),
              ),
              const SizedBox(height: 10),
              Text(sentence, style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _methodsSection(List<BillingMethod> methods) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Payment method'),
        if (methods.isEmpty)
          Text(
            'Your card or UPI shows up here after your next successful payment.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.45),
          )
        else
          for (final m in methods)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(m.label, style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    [if (m.isDefault) 'Used for renewals', if (m.detail != null) m.detail!].join(' · '),
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Widget _invoicesSection(List<BillingPayment> payments, List<BillingPayment> paid) {
    final shown = _showAllInvoices ? payments : payments.take(_invoicePreview).toList();
    final totals = <String, double>{};
    for (final p in paid) {
      final c = (p.currency ?? 'USD').toUpperCase();
      totals[c] = (totals[c] ?? 0) + p.amount;
    }
    final totalText = totals.entries.map((e) => _money(e.value, e.key)).join(' + ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Invoices'),
        if (payments.isEmpty)
          Text(
            'No invoices yet. They appear here after each payment.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.45),
          )
        else ...[
          if (paid.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                '${paid.length} paid · $totalText in total',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
          for (final p in shown) _invoiceRow(p),
          if (payments.length > _invoicePreview)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), foregroundColor: AppColors.primary),
                onPressed: () => setState(() => _showAllInvoices = !_showAllInvoices),
                child: Text(
                  _showAllInvoices ? 'Show fewer' : 'Show all ${payments.length} invoices',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _invoiceRow(BillingPayment p) {
    final cycle = _cycle(p.billingCycle);
    final ok = p.isPaid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_fmt(p.createdAt) ?? '—', style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(
                  '${_planName(p.planName)}${cycle != null ? ' · $cycle' : ''}',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _money(p.amount, p.currency),
                style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 3),
              Text(
                ok ? 'Paid' : 'Pending',
                style: TextStyle(color: ok ? AppColors.success : AppColors.warning, fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _help() {
    return Padding(
      padding: const EdgeInsets.only(top: 36, bottom: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Something on a charge doesn’t look right? Contact support and quote the invoice date.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 6),
          TextButton(
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10), foregroundColor: AppColors.primary),
            onPressed: () => _open('/dashboard/support'),
            child: const Text('Contact support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Small pieces
  // ---------------------------------------------------------------------------

  /// A sentence on a flat tinted field. No icon, no border.
  Widget _notice({
    required String lead,
    required String rest,
    required Color color,
    required String action,
    required VoidCallback onAction,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(18),
      color: color.withValues(alpha: 0.14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$lead ', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800)),
                TextSpan(text: rest, style: TextStyle(color: AppColors.text)),
              ],
            ),
            style: const TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onAction,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(action, style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w800, decoration: TextDecoration.underline)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bar(double value, {required Color fill, required Color track}) {
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, c) => Stack(
          children: [
            Container(width: c.maxWidth, color: track),
            Container(width: c.maxWidth * value, color: fill),
          ],
        ),
      ),
    );
  }

  /// A filled button for use on the brand-colour field. Square corners, no border, no shadow.
  Widget _fieldButton(String text, VoidCallback onTap, {required Color fill, required Color label}) {
    return Material(
      color: fill,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            child: Text(text, style: TextStyle(color: label, fontSize: 16, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _solidButton(String text, VoidCallback onTap) {
    return _fieldButton(text, onTap, fill: AppColors.primary, label: AppColors.textInverse);
  }
}
