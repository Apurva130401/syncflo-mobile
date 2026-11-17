import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
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

  StreamSubscription<List<Map<String, dynamic>>>? _sub;
  List<Conversation> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Subscribe once. The old code created the stream inside build(), so every rebuild
    // re-subscribed and the list flickered / lost its sort order.
    _sub = _supabase.subscribeConversations().listen((rows) {
      if (!mounted) return;
      setState(() {
        _conversations = _sorted(rows.map(Conversation.fromRow).toList());
        _isLoading = false;
      });
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Most recent activity first (ids are random UUIDs, so they can't be used for ordering).
  List<Conversation> _sorted(List<Conversation> list) {
    DateTime when(Conversation c) =>
        DateTime.tryParse(c.lastMessageAt ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) => when(b).compareTo(when(a)));
    return list;
  }

  Future<void> _loadData() async {
    try {
      final list = await _supabase.getConversations();
      if (!mounted) return;
      setState(() {
        _conversations = _sorted(list);
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _isClosed(Conversation c) => c.status == 'closed' || c.status == 'archived';

  bool _matches(Conversation c, String filter) {
    switch (filter) {
      case 'closed':
        return _isClosed(c);
      case 'ai':
        return c.status != 'escalated' && !_isClosed(c);
      case 'human':
        return c.status == 'escalated';
      default:
        return true;
    }
  }

  List<Conversation> _getFilteredConversations() {
    var result = _conversations.where((c) => _matches(c, _filter)).toList();

    if (_unreadOnly) {
      result = result.where((c) => c.unreadCount > 0).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((c) => c.contactName.toLowerCase().contains(q) || c.contactId.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  String _timeLabel(Conversation c) {
    final t = DateTime.tryParse(c.lastMessageAt ?? '')?.toLocal();
    if (t == null) return '';
    final now = DateTime.now();
    if (t.year == now.year && t.month == now.month && t.day == now.day) {
      return DateFormat('h:mm a').format(t);
    }
    if (now.difference(t).inDays < 7) return DateFormat('EEE').format(t);
    return DateFormat('MMM d').format(t);
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final displayList = _getFilteredConversations();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSearchRow(),
              _buildTabs(),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading && _conversations.isEmpty
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.primary,
                        child: displayList.isEmpty
                            ? _buildEmpty()
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: displayList.length,
                                itemBuilder: (context, index) => _buildRow(displayList[index]),
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A flat search field and an "Unread" toggle. No borders, no icon on the toggle.
  Widget _buildSearchRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              color: AppColors.surfaceLight,
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: AppColors.text, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search name or phone',
                  hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 16),
                  prefixIcon: Icon(LucideIcons.search, color: AppColors.textMuted, size: 18),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: _unreadOnly ? AppColors.primary : AppColors.surfaceLight,
            child: InkWell(
              onTap: () => setState(() => _unreadOnly = !_unreadOnly),
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                child: Text(
                  'Unread',
                  style: TextStyle(
                    color: _unreadOnly ? AppColors.textInverse : AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Plain text tabs with counts. The chosen one sits on a flat tone step.
  Widget _buildTabs() {
    int count(String f) => _conversations.where((c) => _matches(c, f)).length;
    final tabs = [
      ('all', 'All'),
      ('ai', 'AI'),
      ('human', 'Human'),
      ('closed', 'Closed'),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          for (final (type, label) in tabs)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: _filter == type ? AppColors.surfaceLight : Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _filter = type),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    child: Text(
                      '$label ${count(type)}',
                      style: TextStyle(
                        color: _filter == type ? AppColors.text : AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: _filter == type ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    final title = _unreadOnly
        ? 'Nothing unread'
        : _searchQuery.isNotEmpty
            ? 'No match'
            : _filter == 'human'
                ? 'No chat needs a human'
                : _filter == 'closed'
                    ? 'No closed chats'
                    : 'Your inbox is clear';
    final body = _unreadOnly
        ? 'Every message in this view has been read.'
        : _searchQuery.isNotEmpty
            ? 'No conversation matches “$_searchQuery”.'
            : 'New customer messages show up here the moment they arrive.';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
      children: [
        Text(
          title,
          style: TextStyle(color: AppColors.text, fontSize: 30, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -0.8),
        ),
        const SizedBox(height: 12),
        Text(body, style: TextStyle(color: AppColors.textSecondary, fontSize: 17, height: 1.45)),
      ],
    );
  }

  /// One conversation: name, what was said, when. No avatar, no badge, no divider line.
  Widget _buildRow(Conversation c) {
    final unread = c.unreadCount > 0;
    final closed = _isClosed(c);
    final human = c.status == 'escalated';
    final time = _timeLabel(c);
    final name = c.contactName.isNotEmpty ? c.contactName : c.contactId;
    final preview = c.lastMessage != null && c.lastMessage!.isNotEmpty ? c.lastMessage! : 'No messages yet';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatThreadScreen(conversation: c)),
        ); // The realtime subscription keeps the list current when coming back.
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: closed ? AppColors.textSecondary : AppColors.text,
                      fontSize: 19,
                      fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (human || closed) ...[
                    const SizedBox(height: 2),
                    Text(
                      human ? 'With a human' : 'Closed',
                      style: TextStyle(
                        color: human ? AppColors.primary : AppColors.textMuted,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: unread ? AppColors.text : AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (time.isNotEmpty)
                  Text(time, style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                if (unread) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 26),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    color: AppColors.primary,
                    alignment: Alignment.center,
                    child: Text(
                      '${c.unreadCount}',
                      style: TextStyle(color: AppColors.textInverse, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
