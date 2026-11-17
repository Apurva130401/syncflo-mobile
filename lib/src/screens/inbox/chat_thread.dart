import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../core/active_chat.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart' as models;

class ChatThreadScreen extends StatefulWidget {
  final models.Conversation conversation;

  const ChatThreadScreen({super.key, required this.conversation});

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final SupabaseService _supabase = SupabaseService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;
  StreamSubscription<List<Map<String, dynamic>>>? _conversationSub;

  final List<models.Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _readMarkPending = false;
  late models.Conversation _activeConversation;
  List<models.Profile> _team = [];

  final List<String> _quickReplies = [
    'Hello! How can I help you?',
    'Checking on this, please wait...',
    'Your ticket is resolved.',
    'Could you share your email?',
    'Thank you for contacting Syncflo!',
  ];

  @override
  void initState() {
    super.initState();
    _activeConversation = widget.conversation;
    // Tell the notification layer which chat is open so it doesn't alert for it.
    ActiveChat.conversationId = _activeConversation.id;

    // One subscription for the lifetime of the screen. (Creating the stream inside build()
    // re-subscribed on every rebuild, which is what let sent messages show up twice.)
    _messagesSub = _supabase.subscribeMessages(_activeConversation.id).listen(_onMessageRows);
    _conversationSub = _supabase.subscribeConversation(_activeConversation.id).listen((rows) {
      if (!mounted || rows.isEmpty) return;
      setState(() => _activeConversation = models.Conversation.fromRow(rows.first));
    });

    _loadMessages();
    _loadTeam();
    _supabase.markConversationRead(_activeConversation.id);
  }

  @override
  void dispose() {
    if (ActiveChat.conversationId == _activeConversation.id) {
      ActiveChat.conversationId = null;
    }
    _messagesSub?.cancel();
    _conversationSub?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final list = await _supabase.getConversationMessages(_activeConversation.id);
      if (!mounted) return;
      setState(() {
        for (final m in list) {
          _mergeMessage(m);
        }
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTeam() async {
    try {
      final team = await _supabase.getTeamMembers();
      if (mounted) setState(() => _team = team);
    } catch (_) {}
  }

  /// Insert or replace a message. A message is "the same" if the row id matches OR it carries the
  /// same WhatsApp message id (the optimistic copy returned by the send call vs the realtime row).
  void _mergeMessage(models.Message incoming) {
    final idx = _messages.indexWhere((m) =>
        m.id == incoming.id ||
        (incoming.waMessageId != null && m.waMessageId == incoming.waMessageId) ||
        (m.waMessageId != null && m.waMessageId == incoming.id));
    if (idx != -1) {
      _messages[idx] = incoming;
    } else {
      _messages.add(incoming);
    }
    _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void _onMessageRows(List<Map<String, dynamic>> rows) {
    if (!mounted) return;
    var hasNewCustomerMessage = false;
    final knownBefore = _messages.length;
    setState(() {
      for (final row in rows) {
        final msg = models.Message.fromRow(row);
        final isNew = !_messages.any((m) => m.id == msg.id);
        _mergeMessage(msg);
        if (isNew && msg.isFromUser) hasNewCustomerMessage = true;
      }
      _isLoading = false;
    });
    if (_messages.length != knownBefore) _scrollToBottom();
    // Keep the unread badge honest while the chat is open.
    if (hasNewCustomerMessage) _markReadSoon();
  }

  void _markReadSoon() {
    if (_readMarkPending) return;
    _readMarkPending = true;
    Future.delayed(const Duration(seconds: 1), () {
      _readMarkPending = false;
      if (mounted) _supabase.markConversationRead(_activeConversation.id);
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSend(String text) async {
    final trimmed = text.trim();
    // _isSending also guards quick-reply chips and double taps against sending twice.
    if (trimmed.isEmpty || _isSending) return;
    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final newMsg = await _supabase.sendMessage(_activeConversation.id, trimmed);
      if (!mounted) return;
      setState(() {
        _mergeMessage(newMsg);
        _activeConversation = _activeConversation.copyWith(
          status: 'escalated',
          lastMessage: trimmed,
          unreadCount: 0,
          humanTakeoverStartedAt:
              _activeConversation.humanTakeoverStartedAt ?? DateTime.now().toUtc().toIso8601String(),
        );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      // Restore the text so the agent can retry.
      _messageController.text = trimmed;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send message: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _handleTakeover() async {
    try {
      await _supabase.takeoverConversation(_activeConversation.id);
      if (!mounted) return;
      setState(() {
        _activeConversation = _activeConversation.copyWith(
          status: 'escalated',
          unreadCount: 0,
          humanTakeoverStartedAt: DateTime.now().toUtc().toIso8601String(),
          humanLastActivityAt: DateTime.now().toUtc().toIso8601String(),
          humanTakeoverBy: _supabase.client.auth.currentUser?.id,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop AI: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleRelease() async {
    try {
      await _supabase.resumeAI(_activeConversation.id);
      if (!mounted) return;
      setState(() {
        _activeConversation = _activeConversation.copyWith(
          status: 'active',
          unreadCount: 0,
          clearHumanTakeover: true,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resume AI: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  String _memberName(models.Profile p) {
    final name = '${p.firstName} ${p.lastName}'.trim();
    return name.isNotEmpty ? name : p.email;
  }

  String get _assigneeLabel {
    final id = _activeConversation.assignedTo;
    if (id == null || id.isEmpty) return 'Unassigned';
    if (id == _supabase.client.auth.currentUser?.id) return 'Me';
    for (final p in _team) {
      if (p.id == id) return _memberName(p);
    }
    return 'Teammate';
  }

  void _handleAssign() {
    final myId = _supabase.client.auth.currentUser?.id;
    final others = _team.where((p) => p.id != myId).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetContext).size.height * 0.7),
            child: ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Assign Chat',
                    style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ListTile(
                  title: Text('Unassigned', style: TextStyle(color: AppColors.text)),
                  onTap: () => _updateAssignment(null),
                ),
                if (myId != null)
                  ListTile(
                    title: Text('Me', style: TextStyle(color: AppColors.text)),
                    onTap: () => _updateAssignment(myId),
                  ),
                for (final p in others)
                  ListTile(
                    title: Text(_memberName(p), style: TextStyle(color: AppColors.text)),
                    subtitle: Text(p.email, style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    onTap: () => _updateAssignment(p.id),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _updateAssignment(String? userId) async {
    Navigator.pop(context); // Close bottom sheet
    try {
      await _supabase.assignConversation(_activeConversation.id, userId);
      if (!mounted) return;
      setState(() {
        _activeConversation = userId == null
            ? _activeConversation.copyWith(clearAssignedTo: true)
            : _activeConversation.copyWith(assignedTo: userId);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _handleAiCall() async {
    final integrationId = _activeConversation.integrationId;
    if (integrationId == null || integrationId.isEmpty) return;

    final name = _activeConversation.contactName.isNotEmpty
        ? _activeConversation.contactName
        : _activeConversation.contactId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Call with AI?', style: TextStyle(color: AppColors.text)),
        content: Text(
          'The AI assistant will call $name on WhatsApp. If they have not allowed calls yet, '
          'they will get a permission request first.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Call')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final message = await _supabase.startAiCall(
        integrationId: integrationId,
        toPhone: _activeConversation.contactId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } on CallingApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.notAvailable ? 'AI Calling is not enabled for your account yet.' : e.message),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not start the call: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isClosed = _activeConversation.status == 'closed' || _activeConversation.status == 'archived';
    final bool isEscalated = _activeConversation.status == 'escalated';
    final bool isAi = !isClosed && !isEscalated;
    final bool isHuman = !isClosed && isEscalated;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _activeConversation.contactName.isNotEmpty
              ? _activeConversation.contactName
              : _activeConversation.contactId,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_activeConversation.integrationId != null)
            IconButton(
              tooltip: 'Call with AI',
              icon: Icon(LucideIcons.phone_call, color: AppColors.primary),
              onPressed: _handleAiCall,
            ),
          IconButton(
            tooltip: 'Assign chat',
            icon: Icon(LucideIcons.user_check, color: AppColors.primary),
            onPressed: _handleAssign,
          ),
        ],
      ),
      body: Center(
        // Keeps the thread readable on tablets / landscape instead of stretching edge to edge.
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              // Assignment & AI Mode Status Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Assigned to: $_assigneeLabel',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isClosed
                          ? '🔒 Closed'
                          : isAi
                              ? '🤖 AI Handled'
                              : '👤 Agent Handled',
                      style: TextStyle(
                        color: isClosed
                            ? AppColors.textMuted
                            : isAi
                                ? AppColors.success
                                : AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Message Thread List
              Expanded(
                child: _isLoading && _messages.isEmpty
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _messages.isEmpty
                        ? Center(
                            child: Text('No messages in this chat yet.',
                                style: TextStyle(color: AppColors.textMuted)),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) => _buildMessage(_messages[index]),
                          ),
              ),

              // Takeover Banner if AI is active
              if (isAi)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      Icon(LucideIcons.bot, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'AI is currently handling this conversation.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _handleTakeover,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Takeover'),
                      ),
                    ],
                  ),
                ),

              // Release back to AI option if Human is active
              if (isHuman)
                Container(
                  padding: const EdgeInsets.all(12),
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      Icon(LucideIcons.user, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'You are managing this conversation.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: _handleRelease,
                        child: const Text('Release to AI'),
                      ),
                    ],
                  ),
                ),

              // Quick Replies List (if not closed and not AI)
              if (isHuman && _quickReplies.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _quickReplies.length,
                    itemBuilder: (context, index) {
                      final reply = _quickReplies[index];
                      return GestureDetector(
                        onTap: _isSending ? null : () => _handleSend(reply),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            reply,
                            style: TextStyle(color: AppColors.text, fontSize: 12),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Message Input Field (only while a human is managing the chat)
              if (isHuman)
                SafeArea(
                  top: false,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: AppColors.surface,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(color: AppColors.text, fontSize: 15),
                              minLines: 1,
                              maxLines: 5,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          radius: 20,
                          child: IconButton(
                            icon: _isSending
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textInverse),
                                    ),
                                  )
                                : Icon(LucideIcons.send, color: AppColors.textInverse, size: 18),
                            onPressed: _isSending ? null : () => _handleSend(_messageController.text),
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
    );
  }

  Widget _buildMessage(models.Message m) {
    final isMe = !m.isFromUser;

    String formattedTime = '';
    try {
      final parsedDate = DateTime.parse(m.createdAt).toLocal();
      formattedTime = DateFormat('h:mm a').format(parsedDate);
    } catch (_) {}

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width.clamp(0, 760) * 0.78,
        ),
        child: m.messageType == 'audio'
            ? _buildVoiceNoteBubble(m, isMe)
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.primary.withValues(alpha: 0.9) : AppColors.surfaceLight,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                    bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                  ),
                  border: Border.all(color: isMe ? Colors.transparent : AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isMe && m.sentByAi)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          'Syncflo AI Bot',
                          style: TextStyle(color: AppColors.success, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    Text(
                      m.content,
                      style: TextStyle(
                        color: isMe ? AppColors.textInverse : AppColors.text,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          formattedTime,
                          style: TextStyle(
                            color: isMe ? AppColors.textInverse.withValues(alpha: 0.5) : AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildVoiceNoteBubble(models.Message m, bool isMe) {
    final audioMeta = m.metadata?['audio'] as Map<String, dynamic>?;
    final isGenerated = audioMeta?['generated'] == true;
    final transcript = (audioMeta?['transcript'] as String?)?.isNotEmpty == true
        ? audioMeta!['transcript'] as String
        : m.content.isNotEmpty
            ? m.content
            : null;
    final label = isGenerated ? 'Voice note sent' : 'Voice note received';

    return Container(
      padding: const EdgeInsets.all(12),
      constraints: BoxConstraints(
        minWidth: 200,
        maxWidth: MediaQuery.of(context).size.width.clamp(0, 760) * 0.78,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
          bottomRight: isMe ? Radius.zero : const Radius.circular(12),
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🎤', style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          transcript != null
              ? Text(
                  transcript,
                  style: TextStyle(color: AppColors.text, fontSize: 14),
                )
              : Text(
                  'Transcript unavailable',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
        ],
      ),
    );
  }
}
