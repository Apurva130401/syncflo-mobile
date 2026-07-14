import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
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

  List<models.Message> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  late models.Conversation _activeConversation;

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
    _loadMessages();
    // Mark conversation as read when opening
    _supabase.markConversationRead(_activeConversation.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final list = await _supabase.getConversationMessages(_activeConversation.id);
      setState(() {
        _messages = list;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      setState(() => _isLoading = false);
    }
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
    if (text.trim().isEmpty) return;
    setState(() => _isSending = true);
    _messageController.clear();

    try {
      final newMsg = await _supabase.sendMessage(_activeConversation.id, text.trim());
      if (!mounted) return;
      setState(() {
        _messages.add(newMsg);
        // Update human activity timestamp locally
        _activeConversation = models.Conversation(
          id: _activeConversation.id,
          contactId: _activeConversation.contactId,
          contactName: _activeConversation.contactName,
          status: 'escalated',
          lastMessage: text.trim(),
          unreadCount: 0,
          assignedTo: _activeConversation.assignedTo,
          humanTakeoverStartedAt: _activeConversation.humanTakeoverStartedAt ?? DateTime.now().toUtc().toIso8601String(),
          aiEnabled: _activeConversation.aiEnabled,
        );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
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
        _activeConversation = models.Conversation(
          id: _activeConversation.id,
          contactId: _activeConversation.contactId,
          contactName: _activeConversation.contactName,
          status: 'escalated',
          lastMessage: _activeConversation.lastMessage,
          unreadCount: 0,
          assignedTo: _activeConversation.assignedTo,
          humanTakeoverStartedAt: DateTime.now().toUtc().toIso8601String(),
          aiEnabled: _activeConversation.aiEnabled,
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
        _activeConversation = models.Conversation(
          id: _activeConversation.id,
          contactId: _activeConversation.contactId,
          contactName: _activeConversation.contactName,
          status: 'active',
          lastMessage: _activeConversation.lastMessage,
          unreadCount: 0,
          assignedTo: _activeConversation.assignedTo,
          humanTakeoverStartedAt: null,
          aiEnabled: _activeConversation.aiEnabled,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resume AI: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _handleAssign() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
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
              ListTile(
                title: Text('Me (Agent)', style: TextStyle(color: AppColors.text)),
                onTap: () => _updateAssignment('Agent'),
              ),
              ListTile(
                title: Text('Apurva (Owner)', style: TextStyle(color: AppColors.text)),
                onTap: () => _updateAssignment('Apurva'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateAssignment(String? agent) async {
    Navigator.pop(context); // Close bottom sheet
    try {
      await _supabase.assignConversation(_activeConversation.id, agent ?? '');
      if (!mounted) return;
      setState(() {
        _activeConversation = models.Conversation(
          id: _activeConversation.id,
          contactId: _activeConversation.contactId,
          contactName: _activeConversation.contactName,
          status: _activeConversation.status,
          lastMessage: _activeConversation.lastMessage,
          unreadCount: 0,
          assignedTo: agent,
          humanTakeoverStartedAt: _activeConversation.humanTakeoverStartedAt,
          aiEnabled: _activeConversation.aiEnabled,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isClosed = _activeConversation.status == 'closed';
    final bool isEscalated = _activeConversation.status == 'escalated';
    final bool isAi = !isClosed && !isEscalated;
    final bool isHuman = !isClosed && isEscalated;

    return Scaffold(
      appBar: AppBar(
        title: Text(_activeConversation.contactName.isNotEmpty
            ? _activeConversation.contactName
            : _activeConversation.contactId),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.user_check, color: AppColors.primary),
            onPressed: _handleAssign,
          ),
        ],
      ),
      body: Column(
        children: [
          // Assignment & AI Mode Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Assigned to: ${_activeConversation.assignedTo ?? "Unassigned"}',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
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
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _supabase.subscribeMessages(_activeConversation.id),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        for (var change in snapshot.data!) {
                          final idx = _messages.indexWhere((m) => m.id == change['id'].toString());
                          final isFromUser = change['is_from_user'] ?? (change['sender_type'] == 'customer');
                          final sentByAi = change['sent_by_ai'] ?? (change['sender_type'] == 'ai');

                          final updatedMsg = models.Message(
                            id: change['id'].toString(),
                            conversationId: change['conversation_id'] as String,
                            content: (change['content'] ?? change['text'] ?? '') as String,
                            senderId: change['sender_id'] as String?,
                            isFromUser: isFromUser as bool,
                            sentByAi: sentByAi as bool,
                            createdAt: (change['created_at'] ?? '') as String,
                            status: (change['status'] ?? 'sent') as String,
                          );

                          if (idx != -1) {
                            _messages[idx] = updatedMsg;
                          } else {
                            _messages.add(updatedMsg);
                          }
                        }
                        // Sort by date ascending for chat UI list
                        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                        _scrollToBottom();
                      }

                      if (_messages.isEmpty) {
                        return Center(
                          child: Text('No messages in this chat yet.', style: TextStyle(color: AppColors.textMuted)),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final m = _messages[index];
                          final isMe = !m.isFromUser;

                          // Format time
                          String formattedTime = '';
                          try {
                            final parsedDate = DateTime.parse(m.createdAt).toLocal();
                            formattedTime = DateFormat('h:mm a').format(parsedDate);
                          } catch (_) {}

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? AppColors.primary.withValues(alpha: 0.9)
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                                ),
                                border: Border.all(
                                  color: isMe ? Colors.transparent : AppColors.border,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe && m.sentByAi)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 4.0),
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
                          );
                        },
                      );
                    },
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
          if (!isClosed && !isAi && _quickReplies.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: _quickReplies.length,
                itemBuilder: (context, index) {
                  final reply = _quickReplies[index];
                  return GestureDetector(
                    onTap: () => _handleSend(reply),
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

          // Message Input Field (if not closed and not AI)
          if (!isClosed && !isAi)
            Container(
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
                        maxLines: null,
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
        ],
      ),
    );
  }
}
