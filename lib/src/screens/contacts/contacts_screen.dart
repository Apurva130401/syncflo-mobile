import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/supabase_service.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../widgets/navigation_drawer.dart';
import '../inbox/chat_thread.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  String? _error;
  List<Contact> _allContacts = [];
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';

  StreamSubscription? _contactsSubscription;

  final List<String> _statusOptions = [
    'all',
    'new',
    'qualified',
    'contacted',
    'converted',
    'lost'
  ];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _setupRealtimeSubscription();
  }

  @override
  void dispose() {
    _contactsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadContacts({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final contacts = await _supabaseService.getLeads();
      if (!mounted) return;
      setState(() {
        _allContacts = contacts;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _setupRealtimeSubscription() {
    try {
      _contactsSubscription = _supabaseService.subscribeLeads().listen((data) {
        if (!mounted) return;
        _loadContacts(showLoader: false);
      }, onError: (e) {
        debugPrint('Realtime contacts error: $e');
      });
    } catch (e) {
      debugPrint('Realtime setup error: $e');
    }
  }

  List<Contact> get _filteredContacts {
    return _allContacts.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c.phone.contains(_searchQuery) ||
          (c.email != null && c.email!.toLowerCase().contains(_searchQuery.toLowerCase())) ||
          (c.company != null && c.company!.toLowerCase().contains(_searchQuery.toLowerCase()));

      final matchesStatus = _selectedStatusFilter == 'all' ||
          c.status.toLowerCase() == _selectedStatusFilter.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // Metrics
  int get _totalCount => _allContacts.length;
  int get _qualifiedCount => _allContacts.where((c) => c.status == 'qualified' || c.status == 'converted').length;
  double get _conversionRate => _totalCount > 0 ? (_qualifiedCount / _totalCount) * 100 : 0.0;
  int get _activeOptInCount => _allContacts.where((c) => c.optInStatus == 'active').length;

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return AppColors.info;
      case 'qualified':
        return AppColors.success;
      case 'contacted':
        return AppColors.accent;
      case 'converted':
        return AppColors.primary;
      case 'lost':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  Future<void> _openWhatsApp(Contact contact) async {
    try {
      final conversations = await _supabaseService.getConversations();
      final cleanPhone = contact.phone.replaceAll(RegExp(r'[^0-9]'), '');
      
      Conversation? targetConv;
      for (final c in conversations) {
        final cClean = c.contactId.replaceAll(RegExp(r'[^0-9]'), '');
        if ((cleanPhone.isNotEmpty && cClean.contains(cleanPhone)) ||
            (cClean.isNotEmpty && cleanPhone.contains(cClean)) ||
            c.contactId == contact.phone ||
            c.contactName.toLowerCase() == contact.name.toLowerCase()) {
          targetConv = c;
          break;
        }
      }

      targetConv ??= Conversation(
        id: 'new_${cleanPhone.isEmpty ? contact.id : cleanPhone}',
        contactId: contact.phone,
        contactName: contact.name,
        status: 'active',
        lastMessage: null,
        unreadCount: 0,
        aiEnabled: true,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatThreadScreen(conversation: targetConv!),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening live inbox: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showAddEditContactDialog([Contact? existing]) {
    final isEditing = existing != null;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final companyController = TextEditingController(text: existing?.company ?? '');
    final valueController = TextEditingController(text: existing?.value.toString() ?? '0');
    final tagsController = TextEditingController(text: existing?.tags.join(', ') ?? '');
    String status = existing?.status ?? 'new';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Contact' : 'Add New Contact',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(LucideIcons.x, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'Full Name *',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        prefixIcon: Icon(LucideIcons.user, color: AppColors.primary, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'WhatsApp Phone (+123456789) *',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        prefixIcon: Icon(LucideIcons.phone, color: AppColors.primary, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        prefixIcon: Icon(LucideIcons.mail, color: AppColors.primary, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: companyController,
                      style: TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'Company / Organization',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        prefixIcon: Icon(LucideIcons.building_2, color: AppColors.primary, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: status,
                            dropdownColor: AppColors.surface,
                            style: TextStyle(color: AppColors.text),
                            decoration: InputDecoration(
                              labelText: 'Status',
                              labelStyle: TextStyle(color: AppColors.textMuted),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: AppColors.border),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            items: ['new', 'qualified', 'contacted', 'converted', 'lost']
                                .map((s) => DropdownMenuItem(
                                      value: s,
                                      child: Text(s.toUpperCase()),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setModalState(() => status = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: valueController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: AppColors.text),
                            decoration: InputDecoration(
                              labelText: 'Lead Value (\$) ',
                              labelStyle: TextStyle(color: AppColors.textMuted),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: AppColors.border),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: tagsController,
                      style: TextStyle(color: AppColors.text),
                      decoration: InputDecoration(
                        labelText: 'Tags (comma separated, e.g. VIP, UAE)',
                        labelStyle: TextStyle(color: AppColors.textMuted),
                        prefixIcon: Icon(LucideIcons.tag, color: AppColors.primary, size: 20),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.border),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (nameController.text.trim().isEmpty ||
                                    phoneController.text.trim().isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Name and Phone number are required.'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                setModalState(() => isSaving = true);
                                try {
                                  final tags = tagsController.text
                                      .split(',')
                                      .map((t) => t.trim())
                                      .where((t) => t.isNotEmpty)
                                      .toList();
                                  final valDouble = double.tryParse(valueController.text.trim()) ?? 0.0;

                                  if (isEditing) {
                                    final updated = existing.copyWith(
                                      name: nameController.text.trim(),
                                      phone: phoneController.text.trim(),
                                      email: emailController.text.trim(),
                                      company: companyController.text.trim(),
                                      status: status,
                                      value: valDouble,
                                      tags: tags,
                                    );
                                    await _supabaseService.updateLead(updated);
                                  } else {
                                    await _supabaseService.createLead(
                                      name: nameController.text.trim(),
                                      phone: phoneController.text.trim(),
                                      email: emailController.text.trim(),
                                      company: companyController.text.trim(),
                                      status: status,
                                      value: valDouble,
                                      tags: tags,
                                    );
                                  }

                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  _loadContacts(showLoader: false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEditing
                                          ? 'Contact updated successfully'
                                          : 'Contact added successfully'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                } catch (e) {
                                  setModalState(() => isSaving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to save contact: $e'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                        child: isSaving
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textInverse,
                                ),
                              )
                            : Text(
                                isEditing ? 'Save Changes' : 'Create Contact',
                                style: TextStyle(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteContact(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete Contact?', style: TextStyle(color: AppColors.text)),
        content: Text(
          'Are you sure you want to delete ${contact.name}? This action cannot be undone.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _supabaseService.deleteLead(contact.id);
                _loadContacts(showLoader: false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Contact deleted successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to delete contact: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Contacts & Leads'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(LucideIcons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.user_plus),
            onPressed: () => _showAddEditContactDialog(),
            tooltip: 'Add Contact',
          ),
          IconButton(
            icon: const Icon(LucideIcons.refresh_cw),
            onPressed: () => _loadContacts(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: const NavigationDrawerWidget(currentRoute: '/contacts'),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showAddEditContactDialog(),
        child: Icon(LucideIcons.plus, color: AppColors.textInverse),
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadContacts(showLoader: false),
        color: AppColors.primary,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.triangle_alert, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load contacts: $_error',
                          style: TextStyle(color: AppColors.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadContacts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Metrics
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Total Contacts',
                                value: '$_totalCount',
                                icon: LucideIcons.users,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Qualified Leads',
                                value: '$_qualifiedCount',
                                icon: LucideIcons.target,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                title: 'Conversion Rate',
                                value: '${_conversionRate.toStringAsFixed(1)}%',
                                icon: LucideIcons.trending_up,
                                color: AppColors.accent,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                title: 'Active Opt-Ins',
                                value: '$_activeOptInCount',
                                icon: LucideIcons.circle_check,
                                color: AppColors.info,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Search Bar
                        TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          style: TextStyle(color: AppColors.text),
                          decoration: InputDecoration(
                            hintText: 'Search contacts by name, phone, email...',
                            hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 14),
                            prefixIcon: Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
                            fillColor: AppColors.surface,
                            filled: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.border),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Status Filter Chips
                        SizedBox(
                          height: 38,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _statusOptions.length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final statusOption = _statusOptions[index];
                              final isSelected = _selectedStatusFilter == statusOption;
                              return ChoiceChip(
                                label: Text(
                                  statusOption.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.textInverse : AppColors.textMuted,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.surface,
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() => _selectedStatusFilter = statusOption);
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Contacts List Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CONTACTS (${_filteredContacts.length})',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Row(
                              children: [
                                Icon(LucideIcons.wifi, color: AppColors.success, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Live Sync',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Contacts List
                        _filteredContacts.isEmpty
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  children: [
                                    Icon(LucideIcons.users, color: AppColors.textMuted, size: 40),
                                    const SizedBox(height: 12),
                                    Text(
                                      'No contacts found',
                                      style: TextStyle(
                                        color: AppColors.text,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _searchQuery.isNotEmpty || _selectedStatusFilter != 'all'
                                          ? 'Try adjusting your search or filters'
                                          : 'Tap the + button to add your first contact',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _filteredContacts.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final contact = _filteredContacts[index];
                                  final statusColor = _getStatusColor(contact.status);

                                  return Card(
                                    color: AppColors.surface,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(color: AppColors.border),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(14.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                                child: Text(
                                                  contact.name.isNotEmpty
                                                      ? contact.name[0].toUpperCase()
                                                      : '?',
                                                  style: TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      contact.name,
                                                      style: TextStyle(
                                                        color: AppColors.text,
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    if (contact.company != null &&
                                                        contact.company!.isNotEmpty)
                                                      Text(
                                                        contact.company!,
                                                        style: TextStyle(
                                                          color: AppColors.textMuted,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withValues(alpha: 0.15),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                      color: statusColor.withValues(alpha: 0.3)),
                                                ),
                                                child: Text(
                                                  contact.status.toUpperCase(),
                                                  style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          const Divider(height: 1),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Icon(LucideIcons.phone,
                                                  color: AppColors.textMuted, size: 14),
                                              const SizedBox(width: 6),
                                              Text(
                                                contact.phone,
                                                style: TextStyle(
                                                  color: AppColors.text,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              if (contact.optInStatus == 'opted_out') ...[
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.error.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Opted Out',
                                                    style: TextStyle(
                                                      color: AppColors.error,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          if (contact.email != null && contact.email!.isNotEmpty) ...[
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                Icon(LucideIcons.mail,
                                                    color: AppColors.textMuted, size: 14),
                                                const SizedBox(width: 6),
                                                Text(
                                                  contact.email!,
                                                  style: TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                          if (contact.tags.isNotEmpty) ...[
                                            const SizedBox(height: 10),
                                            Wrap(
                                              spacing: 6,
                                              runSpacing: 4,
                                              children: contact.tags
                                                  .map(
                                                    (tag) => Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: AppColors.surfaceLight,
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(color: AppColors.border),
                                                      ),
                                                      child: Text(
                                                        '#$tag',
                                                        style: TextStyle(
                                                          color: AppColors.textMuted,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          ],
                                          const SizedBox(height: 14),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              OutlinedButton.icon(
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: AppColors.success,
                                                  side: BorderSide(
                                                      color: AppColors.success.withValues(alpha: 0.4)),
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 12, vertical: 6),
                                                ),
                                                icon: Icon(LucideIcons.message_square, size: 14),
                                                label: const Text('WhatsApp',
                                                    style: TextStyle(fontSize: 12)),
                                                onPressed: () => _openWhatsApp(contact),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                icon: Icon(LucideIcons.pencil,
                                                    color: AppColors.primary, size: 18),
                                                onPressed: () =>
                                                    _showAddEditContactDialog(contact),
                                                tooltip: 'Edit',
                                              ),
                                              IconButton(
                                                icon: Icon(LucideIcons.trash_2,
                                                    color: AppColors.error, size: 18),
                                                onPressed: () => _confirmDeleteContact(contact),
                                                tooltip: 'Delete',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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
