import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../core/push_notification_service.dart';
import '../core/supabase_service.dart';
import '../core/theme.dart';
import '../models/models.dart';

class TakeoverManager extends StatefulWidget {
  final Widget child;
  const TakeoverManager({super.key, required this.child});

  @override
  State<TakeoverManager> createState() => _TakeoverManagerState();
}

class _TakeoverManagerState extends State<TakeoverManager> {
  final SupabaseService _supabaseService = SupabaseService();
  StreamSubscription? _sub;
  Timer? _timer;
  List<Conversation> _conversations = [];
  
  // Notification countdown and modal states
  final Map<String, int> _lastNotifiedMins = {};
  final Set<String> _shownResumedDialogs = {};
  bool _isDialogOpen = false;
  String? _activeDialogChatId;
  BuildContext? _dialogContext;

  @override
  void initState() {
    super.initState();
    _loadInitialConversations();
    _initSubscription();
    _startTimer();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialConversations() async {
    try {
      final list = await _supabaseService.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
      });
    } catch (e) {
      debugPrint('[TakeoverManager] Failed to load initial conversations: $e');
    }
  }

  void _initSubscription() {
    _sub = _supabaseService.subscribeConversations().listen((data) {
      if (!mounted) return;
      setState(() {
        _conversations = data.map((c) {
          return Conversation(
            id: c['id'] as String,
            contactId: (c['contact_id'] ?? c['contactId'] ?? '') as String,
            contactName: (c['contact_name'] ?? c['contactName'] ?? '') as String,
            status: (c['status'] ?? 'active') as String,
            lastMessage: (c['last_message_preview'] ?? c['last_message'] ?? '') as String?,
            unreadCount: (c['unread_count'] ?? c['unreadCount'] ?? 0) as int,
            assignedTo: (c['assigned_to'] ?? c['assignedTo']) as String?,
            humanTakeoverStartedAt: (c['human_takeover_started_at'] ?? c['humanTakeoverStartedAt']) as String?,
            aiEnabled: (c['ai_enabled'] ?? c['aiEnabled'] ?? true) as bool,
            humanLastActivityAt: (c['human_last_activity_at'] ?? c['humanLastActivityAt']) as String?,
            humanTakeoverTimeoutMinutes: (c['human_takeover_timeout_minutes'] ?? c['humanTakeoverTimeoutMinutes']) as int?,
            humanTakeoverBy: (c['human_takeover_by'] ?? c['humanTakeoverBy']) as String?,
          );
        }).toList();
      });
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      _checkConversations();
    });
  }

  void _dismissActiveDialog() {
    if (_isDialogOpen && _dialogContext != null) {
      try {
        Navigator.of(_dialogContext!).pop();
      } catch (e) {
        debugPrint('[TakeoverManager] Dialog pop failed: $e');
      }
    }
  }

  void _checkConversations() async {
    final nowUtc = DateTime.now().toUtc();
    final escalated = _conversations.where((c) => c.status == 'escalated' && c.humanLastActivityAt != null).toList();

    // Check if showing dialog for a chat that is no longer escalated or has been reset
    if (_isDialogOpen && _activeDialogChatId != null) {
      final activeChat = escalated.firstWhere(
        (c) => c.id == _activeDialogChatId, 
        orElse: () => Conversation(id: '', contactId: '', contactName: '', status: '', unreadCount: 0, aiEnabled: false)
      );

      if (activeChat.id.isEmpty) {
        _dismissActiveDialog();
      } else {
        final activityTime = DateTime.parse(activeChat.humanLastActivityAt!).toUtc();
        final elapsed = nowUtc.difference(activityTime);
        final timeout = Duration(minutes: activeChat.humanTakeoverTimeoutMinutes ?? 30);
        final remaining = timeout - elapsed;
        if (remaining.inSeconds > 300) {
          _dismissActiveDialog();
        }
      }
    }

    for (var conv in escalated) {
      final activityTime = DateTime.parse(conv.humanLastActivityAt!).toUtc();
      final elapsed = nowUtc.difference(activityTime);
      final timeout = Duration(minutes: conv.humanTakeoverTimeoutMinutes ?? 30);
      final remaining = timeout - elapsed;
      final remainingSeconds = remaining.inSeconds;

      if (remainingSeconds <= 300 && remainingSeconds > 0) {
        // Countdown push notification reminder (updates dynamically every minute in-place)
        final remainingMins = (remainingSeconds / 60).ceil();
        if (_lastNotifiedMins[conv.id] != remainingMins) {
          _lastNotifiedMins[conv.id] = remainingMins;
          await PushNotificationService().showLocalNotification(
            conv.id.hashCode,
            'Inactivity Warning',
            'AI will automatically resume in $remainingMins min(s) for ${conv.contactName} due to inactivity.',
            payload: conv.id,
          );
        }

        // Show in-app warning modal dialog
        if (!_isDialogOpen) {
          _showWarningDialog(conv);
        }
      } else if (remainingSeconds <= 0) {
        // Auto-resume timer reached 0
        if (_isDialogOpen && _activeDialogChatId == conv.id) {
          _dismissActiveDialog();
        }

        try {
          await _supabaseService.resumeAI(conv.id);

          // Trigger resumed push notification
          await PushNotificationService().showLocalNotification(
            conv.id.hashCode,
            'AI Resumed',
            'AI has resumed automation for ${conv.contactName} due to human inactivity.',
            payload: conv.id,
          );

          // Show resumed modal notification
          if (!_shownResumedDialogs.contains(conv.id)) {
            _shownResumedDialogs.add(conv.id);
            _showResumedDialog(conv);
          }

          _lastNotifiedMins.remove(conv.id);
        } catch (e) {
          debugPrint('[TakeoverManager] Auto-resume API failure for ${conv.id}: $e');
        }
      }
    }

    // Clean tracking states for conversations no longer escalated
    final escalatedIds = escalated.map((c) => c.id).toSet();
    _shownResumedDialogs.removeWhere((id) => !escalatedIds.contains(id));
    _lastNotifiedMins.removeWhere((id, min) => !escalatedIds.contains(id));
  }

  void _showWarningDialog(Conversation conv) {
    _isDialogOpen = true;
    _activeDialogChatId = conv.id;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        _dialogContext = dialogCtx;
        return LiveCountdownDialog(
          conversation: conv,
          onKeepControl: () async {
            try {
              await _supabaseService.takeoverConversation(conv.id);
              if (mounted && _dialogContext != null) {
                Navigator.of(_dialogContext!).pop();
              }
            } catch (e) {
              debugPrint('[TakeoverManager] Keep control callback failure: $e');
            }
          },
          onResumeNow: () async {
            try {
              await _supabaseService.resumeAI(conv.id);
              if (mounted && _dialogContext != null) {
                Navigator.of(_dialogContext!).pop();
              }
            } catch (e) {
              debugPrint('[TakeoverManager] Resume AI callback failure: $e');
            }
          },
        );
      }
    ).then((_) {
      _isDialogOpen = false;
      _activeDialogChatId = null;
      _dialogContext = null;
    });
  }

  void _showResumedDialog(Conversation conv) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              Icon(LucideIcons.bot, color: AppColors.success, size: 24),
              const SizedBox(width: 8),
              Text(
                'AI Control Resumed',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Human takeover has expired for ${conv.contactName} due to inactivity.',
                style: TextStyle(color: AppColors.text, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Text(
                'AI is now automating the chat and answering messages.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: AppColors.textInverse),
              ),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class LiveCountdownDialog extends StatefulWidget {
  final Conversation conversation;
  final Future<void> Function() onKeepControl;
  final Future<void> Function() onResumeNow;

  const LiveCountdownDialog({
    super.key,
    required this.conversation,
    required this.onKeepControl,
    required this.onResumeNow,
  });

  @override
  State<LiveCountdownDialog> createState() => _LiveCountdownDialogState();
}

class _LiveCountdownDialogState extends State<LiveCountdownDialog> {
  Timer? _timer;
  late int _remainingSeconds;
  bool _isResetting = false;
  bool _isResuming = false;

  @override
  void initState() {
    super.initState();
    _calculateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _calculateRemaining();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateRemaining() {
    final nowUtc = DateTime.now().toUtc();
    final activityTime = DateTime.parse(widget.conversation.humanLastActivityAt!).toUtc();
    final elapsed = nowUtc.difference(activityTime);
    final timeout = Duration(minutes: widget.conversation.humanTakeoverTimeoutMinutes ?? 30);
    final remaining = timeout - elapsed;
    _remainingSeconds = remaining.inSeconds;
    if (_remainingSeconds <= 0) {
      _remainingSeconds = 0;
      _timer?.cancel();
    }
  }

  String _formatTime() {
    if (_remainingSeconds <= 0) return '00:00';
    final minutes = (_remainingSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Icon(LucideIcons.triangle_alert, color: AppColors.warning, size: 24),
          const SizedBox(width: 8),
          Text(
            'Inactivity Warning',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'AI is scheduled to take over the chat with ${widget.conversation.contactName} in:',
            style: TextStyle(color: AppColors.text, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              _formatTime(),
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Keep control to prevent the AI from automatically responding to the customer.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isResuming || _isResetting ? null : () async {
            setState(() => _isResuming = true);
            await widget.onResumeNow();
          },
          child: _isResuming
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Resume AI Now', style: TextStyle(color: AppColors.textMuted)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          onPressed: _isResuming || _isResetting ? null : () async {
            setState(() => _isResetting = true);
            await widget.onKeepControl();
          },
          child: _isResetting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Keep Control', style: TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
