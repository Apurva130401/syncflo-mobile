import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'active_chat.dart';
import 'notification_prefs.dart';
import 'push_notification_service.dart';
import 'supabase_service.dart';

/// Foreground alerts for the two things the dashboard does not push for:
///  - customer messages in chats that need a human (escalated, or assigned to / taken over by me)
///  - AI call updates (new call, call finished)
///
/// Background delivery still comes from FCM. Notification ids are shared with the push handler
/// (per conversation), so a push and a realtime alert for the same chat replace each other.
class RealtimeAlertsService with WidgetsBindingObserver {
  static final RealtimeAlertsService _instance = RealtimeAlertsService._internal();
  factory RealtimeAlertsService() => _instance;
  RealtimeAlertsService._internal();

  static const _callPollInterval = Duration(seconds: 20);

  final SupabaseService _service = SupabaseService();
  RealtimeChannel? _channel;
  RealtimeChannel? _callsChannel;
  Timer? _callTimer;
  Timer? _callDebounce;

  /// Bumped whenever a call row changes, so open screens can refresh immediately.
  final ValueNotifier<int> callsChanged = ValueNotifier<int>(0);
  bool _started = false;
  bool _foreground = true;

  // Conversation lookups for message alerts (name + who owns it), cached briefly.
  final Map<String, ({Conversation conversation, DateTime at})> _convCache = {};
  // Message ids we already alerted for (realtime can redeliver after a reconnect).
  final Set<String> _alertedMessages = {};

  // AI call tracking: id -> last status we saw. Null until the first poll has seeded it.
  Map<String, String>? _callStatuses;
  bool _callingUnavailable = false;

  void start() {
    if (_started) return;
    final user = _service.client.auth.currentUser;
    if (user == null) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);

    _channel = _service.client
        .channel('public:whatsapp_messages:alerts')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'whatsapp_messages',
          callback: (payload) => _onMessageInserted(payload.newRecord),
        )
        .subscribe();

    // Call rows are only visible to the account owner (RLS), so for team members this stays quiet
    // and the poll below keeps them up to date.
    _callsChannel = _service.client.channel('public:whatsapp_voice_calls:alerts');
    for (final table in const ['whatsapp_voice_calls', 'whatsapp_active_calls']) {
      _callsChannel!.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: (_) => _onCallsRealtime(),
      );
    }
    _callsChannel!.subscribe();

    _pollCalls();
    _callTimer = Timer.periodic(_callPollInterval, (_) {
      if (_foreground) _pollCalls();
    });
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _callTimer?.cancel();
    _callTimer = null;
    _callDebounce?.cancel();
    _callDebounce = null;
    if (_channel != null) {
      _service.client.removeChannel(_channel!);
      _channel = null;
    }
    if (_callsChannel != null) {
      _service.client.removeChannel(_callsChannel!);
      _callsChannel = null;
    }
    _convCache.clear();
    _alertedMessages.clear();
    _callStatuses = null;
    _callingUnavailable = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (_foreground && _started) _pollCalls();
  }

  // ---------------------------------------------------------------------------
  // Messages
  // ---------------------------------------------------------------------------

  Future<void> _onMessageInserted(Map<String, dynamic> row) async {
    try {
      if (row['is_from_user'] != true) return; // only customer messages
      final messageId = row['id']?.toString();
      final conversationId = row['conversation_id']?.toString();
      if (messageId == null || conversationId == null) return;
      if (!_alertedMessages.add(messageId)) return;
      if (_alertedMessages.length > 200) _alertedMessages.remove(_alertedMessages.first);

      if (conversationId == ActiveChat.conversationId) return; // already looking at it
      if (!await NotificationPrefs.messages()) return;

      final conversation = await _conversation(conversationId);
      if (conversation == null) return;

      final me = _service.client.auth.currentUser?.id;
      final needsHuman = conversation.status == 'escalated';
      final mine = conversation.assignedTo == me || conversation.humanTakeoverBy == me;
      if (!needsHuman && !mine) return; // AI is handling it and nobody owns it: stay quiet

      final name = conversation.contactName.isNotEmpty ? conversation.contactName : conversation.contactId;
      final type = row['message_type']?.toString();
      final content = (row['content'] ?? '').toString();
      final body = type == 'audio' && content.isEmpty ? '🎤 Voice note' : (content.isEmpty ? 'New message' : content);

      await PushNotificationService().showLocalNotification(
        conversationId.hashCode,
        'New message from $name',
        body.length > 100 ? '${body.substring(0, 100)}…' : body,
        payload: 'chat:$conversationId',
      );
    } catch (e) {
      debugPrint('[RealtimeAlerts] Message alert failed: $e');
    }
  }

  Future<Conversation?> _conversation(String id) async {
    final cached = _convCache[id];
    if (cached != null && DateTime.now().difference(cached.at) < const Duration(seconds: 30)) {
      return cached.conversation;
    }
    final conversation = await _service.getConversation(id);
    if (conversation != null) _convCache[id] = (conversation: conversation, at: DateTime.now());
    return conversation;
  }

  // ---------------------------------------------------------------------------
  // AI calls
  // ---------------------------------------------------------------------------

  /// A call row changed: poll once (debounced, a call fires several updates in a row) and tell open screens.
  void _onCallsRealtime() {
    _callDebounce?.cancel();
    _callDebounce = Timer(const Duration(milliseconds: 700), () {
      if (!_started) return;
      callsChanged.value++;
      if (_foreground) _pollCalls();
    });
  }

  Future<void> _pollCalls() async {
    if (_callingUnavailable) return;
    try {
      final result = await _service.getAiCalls(limit: 20);
      final previous = _callStatuses;
      final next = {for (final c in result.calls) c.id: c.status};
      _callStatuses = next;
      if (previous == null) return; // first poll only seeds state, so old calls don't alert

      if (!await NotificationPrefs.calls()) return;

      for (final call in result.calls) {
        final before = previous[call.id];
        if (before == call.status) continue;

        if (before == null && call.isLive) {
          await _notifyCall(call, call.isInbound ? 'Incoming AI call' : 'AI is calling',
              call.isInbound ? '${call.displayName} is calling. The AI is answering.' : 'Calling ${call.displayName}…');
        } else if (call.status == 'completed' && (before == null || before == 'ringing' || before == 'in_progress')) {
          final summary = (call.summary ?? '').trim();
          await _notifyCall(
            call,
            'AI call finished · ${call.displayName}',
            summary.isNotEmpty ? summary : 'Call ended${_durationText(call)}.',
          );
        } else if (call.status == 'no_answer' || call.status == 'failed' || call.status == 'rejected') {
          if (before == null || before == 'ringing' || before == 'in_progress') {
            await _notifyCall(call, 'AI call not connected', '${call.displayName} did not answer.');
          }
        }
      }
    } on CallingApiException catch (e) {
      // 403 = AI Calling isn't enabled for this account: stop asking for the rest of the session.
      if (e.notAvailable) _callingUnavailable = true;
    } catch (e) {
      debugPrint('[RealtimeAlerts] Call poll failed: $e');
    }
  }

  String _durationText(CallRecord call) {
    final s = call.durationSeconds;
    if (s == null || s <= 0) return '';
    final m = s ~/ 60;
    return ' after ${m > 0 ? '${m}m ' : ''}${s % 60}s';
  }

  Future<void> _notifyCall(CallRecord call, String title, String body) {
    return PushNotificationService().showLocalNotification(
      call.id.hashCode,
      title,
      body.length > 140 ? '${body.substring(0, 140)}…' : body,
      payload: 'calls',
      channelId: 'syncflo_calls',
    );
  }
}
