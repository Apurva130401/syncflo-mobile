import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../core/realtime_alerts_service.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';

/// WhatsApp AI calls: live status, this month's totals, history with summary and transcript.
/// Setup (enable calling, voice, prompt) stays on the web dashboard.
class CallsScreen extends StatefulWidget {
  const CallsScreen({super.key});

  @override
  State<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends State<CallsScreen> {
  final SupabaseService _service = SupabaseService();
  Timer? _refreshTimer;

  List<CallRecord> _calls = [];
  List<CallingNumber> _numbers = [];
  CallTotals _month = const CallTotals();
  bool _loading = true;
  bool _notAvailable = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    // Keep live calls fresh while the screen is open.
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _load(silent: true));
    // Realtime: the dashboard pushes call changes (owner account), so refresh right away.
    RealtimeAlertsService().callsChanged.addListener(_onCallsChanged);
  }

  void _onCallsChanged() {
    if (mounted) _load(silent: true);
  }

  @override
  void dispose() {
    RealtimeAlertsService().callsChanged.removeListener(_onCallsChanged);
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) setState(() => _loading = true);
    try {
      final result = await _service.getAiCalls(limit: 50);
      List<CallingNumber> numbers = _numbers;
      try {
        numbers = await _service.getCallingNumbers();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _calls = result.calls;
        _month = result.thisMonth;
        _numbers = numbers;
        _loading = false;
        _error = null;
        _notAvailable = false;
      });
    } on CallingApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notAvailable = e.notAvailable;
        if (!silent || _calls.isEmpty) _error = e.notAvailable ? null : e.message;
      });
      if (e.notAvailable) _refreshTimer?.cancel();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!silent || _calls.isEmpty) _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Calls'),
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
      drawer: const NavigationDrawerWidget(currentRoute: '/calls'),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _calls.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_notAvailable) {
      return _message(
        LucideIcons.phone_off,
        'AI Calling is not enabled yet',
        'AI Calling is in beta. Ask SyncFlo to enable it for your account, then set it up from the web dashboard.',
      );
    }
    if (_error != null && _calls.isEmpty) {
      return _message(LucideIcons.triangle_alert, 'Could not load calls', _error!, retry: true);
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummary(),
          if (_numbers.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildNumbers(),
          ],
          const SizedBox(height: 20),
          Text(
            'RECENT CALLS',
            style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          if (_calls.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(LucideIcons.phone, size: 44, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('No calls yet', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'Calls answered or placed by your AI will show up here.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            for (final c in _calls) _buildCallTile(c),
        ],
      ),
    );
  }

  Widget _message(IconData icon, String title, String body, {bool retry = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title,
                style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(body, style: TextStyle(color: AppColors.textMuted, fontSize: 14), textAlign: TextAlign.center),
            if (retry) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummary() {
    final live = _calls.where((c) => c.isLive).length;
    Widget stat(String label, String value, IconData icon) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(value, style: TextStyle(color: AppColors.text, fontSize: 22, fontWeight: FontWeight.bold)),
                Text(label, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
        );

    return Row(
      children: [
        stat('Calls this month', '${_month.calls}', LucideIcons.phone),
        const SizedBox(width: 12),
        stat('Minutes this month', _month.minutes.toStringAsFixed(1), LucideIcons.clock),
        const SizedBox(width: 12),
        stat('Live now', '$live', LucideIcons.radio),
      ],
    );
  }

  Widget _buildNumbers() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final n in _numbers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (n.callingEnabled && n.callingStatus == 'connected' ? AppColors.success : AppColors.textMuted)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${n.label}: ${n.callingEnabled ? (n.callingStatus == 'connected' ? 'Calling on' : n.callingStatus.replaceAll('_', ' ')) : 'Calling off'}',
              style: TextStyle(
                color: n.callingEnabled && n.callingStatus == 'connected' ? AppColors.success : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  ({String label, Color color}) _statusStyle(CallRecord c) {
    switch (c.status) {
      case 'ringing':
        return (label: 'Ringing', color: AppColors.warning);
      case 'in_progress':
        return (label: 'Live', color: AppColors.success);
      case 'completed':
        return (label: 'Completed', color: AppColors.textMuted);
      case 'no_answer':
        return (label: 'No answer', color: AppColors.warning);
      case 'rejected':
        return (label: 'Rejected', color: AppColors.error);
      default:
        return (label: 'Failed', color: AppColors.error);
    }
  }

  String _duration(CallRecord c) {
    final s = c.durationSeconds;
    if (s == null || s <= 0) return '';
    final m = s ~/ 60;
    return m > 0 ? '${m}m ${s % 60}s' : '${s}s';
  }

  String _when(CallRecord c) {
    final t = DateTime.tryParse(c.startedAt ?? c.createdAt)?.toLocal();
    return t == null ? '' : DateFormat('MMM d, h:mm a').format(t);
  }

  Widget _buildCallTile(CallRecord c) {
    final style = _statusStyle(c);
    final duration = _duration(c);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => _showDetails(c),
        leading: CircleAvatar(
          backgroundColor: style.color.withValues(alpha: 0.12),
          child: Icon(
            c.isInbound ? LucideIcons.phone_incoming : LucideIcons.phone_outgoing,
            color: style.color,
            size: 18,
          ),
        ),
        title: Text(
          c.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              c.isInbound ? 'Inbound' : 'Outbound',
              if (duration.isNotEmpty) duration,
              _when(c),
            ].where((e) => e.isNotEmpty).join(' · '),
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: style.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(style.label, style: TextStyle(color: style.color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _showDetails(CallRecord c) {
    final style = _statusStyle(c);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Text(c.displayName, style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              [
                c.isInbound ? 'Inbound' : 'Outbound',
                style.label,
                _duration(c),
                _when(c),
              ].where((e) => e.isNotEmpty).join(' · '),
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            if (c.otherNumber.isNotEmpty && c.contactName != null) ...[
              const SizedBox(height: 2),
              Text(c.otherNumber, style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            _section('Summary', (c.summary ?? '').trim().isNotEmpty ? c.summary! : 'No summary yet.'),
            if ((c.outcome ?? '').trim().isNotEmpty) _section('Outcome', c.outcome!),
            _section(
              'Transcript',
              (c.transcript ?? '').trim().isNotEmpty
                  ? c.transcript!
                  : (c.isLive ? 'The transcript appears after the call ends.' : 'No transcript available.'),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          const SizedBox(height: 6),
          SelectableText(body, style: TextStyle(color: AppColors.text, fontSize: 14, height: 1.4)),
        ],
      ),
    );
  }
}
