import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import 'chat_thread.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}


class _ConversationListScreenState extends State<ConversationListScreen> {
  final SupabaseService _supabase = SupabaseService();
  String _filter = 'all'; // 'all', 'ai', 'human', 'closed'
  String _searchQuery = '';
  bool _unreadOnly = false;
  final TextEditingController _searchController = TextEditingController();

  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final list = await _supabase.getConversations();
      setState(() {
        _conversations = list;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  List<Conversation> _getFilteredConversations() {
    var result = _conversations;

    if (_filter != 'all') {
      if (_filter == 'closed') {
        result = result.where((c) => c.status == 'closed').toList();
      } else if (_filter == 'ai') {
        result = result.where((c) => c.status == 'active').toList();
      } else if (_filter == 'human') {
        result = result.where((c) => c.status == 'escalated').toList();
      }
    }

    if (_unreadOnly) {
      result = result.where((c) => c.unreadCount > 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) =>
        c.contactName.toLowerCase().contains(q) ||
        c.contactId.toLowerCase().contains(q)
      ).toList();
    }

    return result;
  }

  Widget _buildFilterTab(String type, String label) {
    final isActive = _filter == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? AppColors.surfaceLight : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? AppColors.primary : AppColors.textMuted,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Inbox'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(LucideIcons.refresh_cw, size: 20),
            onPressed: _loadData,
          )
        ],
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/inbox'),
      body: Column(
        children: [
          // Search & Unread Toggle Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: AppColors.text, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search name or phone...',
                        prefixIcon: Icon(LucideIcons.search, color: AppColors.textMuted, size: 18),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (value) => setState(() => _searchQuery = value),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => setState(() => _unreadOnly = !_unreadOnly),
                  child: Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _unreadOnly ? AppColors.primary : AppColors.surfaceLight,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.mail,
                          size: 16,
                          color: _unreadOnly ? AppColors.background : AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Unread',
                          style: TextStyle(
                            color: _unreadOnly ? AppColors.background : AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filters Tab Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surface,
            child: Row(
              children: [
                _buildFilterTab('all', 'All'),
                _buildFilterTab('ai', 'AI'),
                _buildFilterTab('human', 'Human'),
                _buildFilterTab('closed', 'Closed'),
              ],
            ),
          ),

          const Divider(),

          // Conversation List
          Expanded(
            child: _isLoading && _conversations.isEmpty
                ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppColors.primary,
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _supabase.subscribeConversations(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          for (var change in snapshot.data!) {
                            final idx = _conversations.indexWhere((c) => c.id == change['id']);
                            final updatedConv = Conversation(
                              id: change['id'] as String,
                              contactId: (change['contact_id'] ?? '') as String,
                              contactName: (change['contact_name'] ?? '') as String,
                              status: (change['status'] ?? 'active') as String,
                              lastMessage: (change['last_message_preview'] ?? change['last_message'] ?? '') as String?,
                              unreadCount: (change['unread_count'] ?? 0) as int,
                              assignedTo: change['assigned_to'] as String?,
                              humanTakeoverStartedAt: change['human_takeover_started_at'] as String?,
                              aiEnabled: (change['ai_enabled'] ?? true) as bool,
                              humanLastActivityAt: change['human_last_activity_at'] as String?,
                              humanTakeoverTimeoutMinutes: change['human_takeover_timeout_minutes'] as int?,
                              humanTakeoverBy: change['human_takeover_by'] as String?,
                            );
                            if (idx != -1) {
                              _conversations[idx] = updatedConv;
                            } else {
                              _conversations.insert(0, updatedConv);
                            }
                          }
                          // Re-sort so most recent chat updates bubble up
                          _conversations.sort((a, b) => b.id.compareTo(a.id));
                        }

                        final displayList = _getFilteredConversations();

                        if (displayList.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.message_square, size: 48, color: AppColors.textMuted),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No conversations found',
                                    style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32),
                                    child: Text(
                                      _unreadOnly
                                          ? 'No unread messages found matching your filters.'
                                          : _searchQuery.isNotEmpty
                                              ? 'No conversations match your search query.'
                                              : 'Your inbox is clear!',
                                      style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        }

                        return ListView.separated(
                          itemCount: displayList.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final c = displayList[index];
                            
                            // Determine status indicator tag
                            Color statusColor;
                            String statusLabel;
                            if (c.status == 'closed') {
                              statusColor = AppColors.textMuted;
                              statusLabel = 'Closed';
                            } else if (c.status == 'escalated') {
                              statusColor = AppColors.primary;
                              statusLabel = 'Human';
                            } else {
                              statusColor = AppColors.success;
                              statusLabel = 'AI Mode';
                            }

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppColors.surfaceLight,
                                foregroundColor: AppColors.primary,
                                child: Icon(LucideIcons.user),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.contactName.isNotEmpty ? c.contactName : c.contactId,
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontWeight: c.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  c.lastMessage != null && c.lastMessage!.isNotEmpty
                                      ? c.lastMessage!
                                      : 'No messages yet',
                                  style: TextStyle(
                                    color: c.unreadCount > 0 ? AppColors.text : AppColors.textMuted,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (c.unreadCount > 0)
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '${c.unreadCount}',
                                        style: TextStyle(
                                          color: AppColors.textInverse,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatThreadScreen(conversation: c),
                                  ),
                                ).then((_) => _loadData()); // Reload when coming back
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
