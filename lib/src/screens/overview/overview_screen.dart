import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/app_router.dart';
import '../../core/auth_provider.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final SupabaseService _service = SupabaseService();

  bool _loading = true;
  String? _error;

  int _openChats = 0;
  int _waiting = 0; // chats the AI handed over to a human
  int _unread = 0;
  int _used = 0;
  int _total = 0;
  String? _periodEnd;
  CallTotals? _calls; // null when AI Calling isn't available for this account
  int _liveCalls = 0;

  // The slower analytics request fills in after the first paint.
  OverviewStats? _stats;
  bool _statsFailed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait([
        _service.getConversations(),
        _service.getUserUsage().then<UserUsage?>((u) => u).catchError((_) => null),
        _service.getNotifications().then<List<AppNotification>>((n) => n).catchError((_) => <AppNotification>[]),
        _service
            .getAiCalls(limit: 20)
            .then<({List<CallRecord> calls, CallTotals thisMonth})?>((r) => r)
            .catchError((_) => null),
      ]);

      final conversations = results[0] as List<Conversation>;
      final usage = results[1] as UserUsage?;
      final notifications = results[2] as List<AppNotification>;
      final calls = results[3] as ({List<CallRecord> calls, CallTotals thisMonth})?;

      final open = conversations.where((c) => c.status != 'closed' && c.status != 'archived').toList();

      if (!mounted) return;
      setState(() {
        _openChats = open.length;
        _waiting = open.where((c) => c.status == 'escalated').length;
        _unread = notifications.where((n) => !n.read).length;
        _used = usage?.usedMessages ?? 0;
        _total = usage?.messageCredits ?? 0;
        _periodEnd = usage?.periodEnd;
        _calls = calls?.thisMonth;
        _liveCalls = calls?.calls.where((c) => c.isLive).length ?? 0;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
      return;
    }

    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _service.getOverviewStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _statsFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statsFailed = true);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

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
          IconButton(icon: const Icon(LucideIcons.refresh_cw, size: 20), onPressed: _load),
        ],
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/overview'),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _load(silent: true),
                  child: _buildContent(_greetingName(auth)),
                ),
    );
  }

  String? _greetingName(AuthProvider auth) {
    final fromAuth = auth.user?.firstName.trim() ?? '';
    if (fromAuth.isNotEmpty) return fromAuth;
    return _stats?.firstName;
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
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
                'We couldn’t load your overview',
                style: TextStyle(color: AppColors.text, fontSize: 26, fontWeight: FontWeight.w800, height: 1.1),
              ),
              const SizedBox(height: 12),
              Text(
                'Nothing has changed with your chats. $_error',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.45),
              ),
              const SizedBox(height: 24),
              _button('Try again', _load, fill: AppColors.primary, label: AppColors.textInverse),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(String? name) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        _hero(name),
        _column([
          _heading('How the AI is doing'),
          _stats_(),
          _heading('Message credits'),
          _credits(),
          _heading('Worth a look'),
          _linkRow(
            title: _unread == 0 ? 'No unread notifications' : '$_unread unread notification${_unread == 1 ? '' : 's'}',
            body: 'Handoffs, assignments and system messages.',
            route: '/notifications',
            emphasised: _unread > 0,
          ),
          if (_calls != null)
            _linkRow(
              title: _liveCalls > 0
                  ? '$_liveCalls AI call${_liveCalls == 1 ? '' : 's'} live now'
                  : '${_calls!.calls} AI call${_calls!.calls == 1 ? '' : 's'} this month',
              body: '${_calls!.minutes.toStringAsFixed(1)} minutes of conversation.',
              route: '/calls',
              emphasised: _liveCalls > 0,
            ),
          _linkRow(
            title: 'Billing and plan',
            body: 'Your plan, next payment and invoices.',
            route: '/billing',
          ),
          const SizedBox(height: 48),
        ]),
      ],
    );
  }

  /// Readable column, same side margins everywhere, centred on wide screens.
  Widget _column(List<Widget> children) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // The first screen: what needs a human right now
  // ---------------------------------------------------------------------------

  Widget _hero(String? name) {
    final ink = AppColors.textInverse;
    final soft = ink.withValues(alpha: 0.8);
    final headline = _waiting == 0
        ? 'Nothing is waiting for you'
        : _waiting == 1
            ? '1 chat needs a human'
            : '$_waiting chats need a human';
    final body = _waiting == 0
        ? 'The AI is handling all $_openChats open chat${_openChats == 1 ? '' : 's'}.'
        : 'The AI handed ${_waiting == 1 ? 'it' : 'them'} over. ${_waiting == 1 ? 'A customer is' : 'Customers are'} waiting for a reply.';

    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name == null ? _greeting() : '${_greeting()}, $name',
                  style: TextStyle(color: soft, fontSize: 17, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 14),
                Text(
                  headline,
                  style: TextStyle(color: ink, fontSize: 46, fontWeight: FontWeight.w800, height: 1.0, letterSpacing: -1.6),
                ),
                const SizedBox(height: 14),
                Text(body, style: TextStyle(color: soft, fontSize: 17, height: 1.45)),
                const SizedBox(height: 26),
                _button('Open inbox', () => AppRouter.openRoute('/inbox'), fill: ink, label: AppColors.primary),
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
        padding: const EdgeInsets.only(top: 44, bottom: 18),
        child: Text(
          text,
          style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.15),
        ),
      );

  String _pct(double? v) => v == null ? '—' : '${v.toStringAsFixed(v == v.roundToDouble() ? 0 : 1)}%';

  Widget _stats_() {
    final s = _stats;
    final loadingStats = s == null && !_statsFailed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _figure(
          loadingStats ? '…' : _pct(s?.automationRate),
          'of replies were sent by the AI, not by your team.',
        ),
        const SizedBox(height: 30),
        _figure(
          loadingStats
              ? '…'
              : s?.avgResponseSeconds == null
                  ? '—'
                  : '${s!.avgResponseSeconds!.toStringAsFixed(1)}s',
          'typical time to reply to a customer.',
        ),
        const SizedBox(height: 30),
        _figure(
          loadingStats ? '…' : _pct(s?.conversionRate),
          s == null || s.activeLeads == 0
              ? 'of leads turned into customers.'
              : 'of your ${NumberFormat.decimalPattern().format(s.activeLeads)} leads turned into customers.',
        ),
        if (_statsFailed)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              'These figures could not be loaded just now. Pull down to try again.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
            ),
          ),
      ],
    );
  }

  Widget _figure(String value, String sentence) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(color: AppColors.text, fontSize: 52, fontWeight: FontWeight.w800, letterSpacing: -1.8, height: 1.0),
        ),
        const SizedBox(height: 6),
        Text(sentence, style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.4)),
      ],
    );
  }

  Widget _credits() {
    final ratio = _total > 0 ? (_used / _total).clamp(0.0, 1.0) : 0.0;
    final fill = ratio > 0.9
        ? AppColors.error
        : ratio > 0.7
            ? AppColors.accent
            : AppColors.primary;
    final nf = NumberFormat.decimalPattern();
    final resets = _periodEnd == null ? null : DateTime.tryParse(_periodEnd!)?.toLocal();

    if (_total == 0) {
      return Text(
        'Credit usage is not available for this billing period yet.',
        style: TextStyle(color: AppColors.textSecondary, fontSize: 16, height: 1.45),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: nf.format(_used),
                style: TextStyle(color: AppColors.text, fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.4, height: 1.0),
              ),
              TextSpan(
                text: '  of ${nf.format(_total)} AI messages',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 8,
          child: LayoutBuilder(
            builder: (context, c) => Stack(
              children: [
                Container(width: c.maxWidth, color: AppColors.surfaceLight),
                Container(width: c.maxWidth * ratio, color: fill),
              ],
            ),
          ),
        ),
        if (resets != null) ...[
          const SizedBox(height: 12),
          Text(
            'Credits reset on ${DateFormat('MMM d, yyyy').format(resets)}.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ],
      ],
    );
  }

  /// A tappable line: what it is, a sentence, and an arrow. No card, no border.
  Widget _linkRow({
    required String title,
    required String body,
    required String route,
    bool emphasised = false,
  }) {
    return InkWell(
      onTap: () => AppRouter.openRoute(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: emphasised ? AppColors.primary : AppColors.text,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(body, style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            ),
            Icon(LucideIcons.chevron_right, size: 22, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  /// Filled button, square corners, no border and no shadow.
  Widget _button(String text, VoidCallback onTap, {required Color fill, required Color label}) {
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
}
