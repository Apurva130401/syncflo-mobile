import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart' as models;
import 'constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final SupabaseClient client = Supabase.instance.client;

  /// Cached workspace owner user ID. For owners = their own ID.
  /// For invited agents = the owner's user ID from account_members.
  /// Used to send the x-syncflo-account-id header on all API calls.
  String? _cachedOwnerUserId;

  // Authentication Methods
  models.User? get currentUser {
    final user = client.auth.currentUser;
    if (user == null) return null;
    
    final fullName = user.userMetadata?['full_name'] as String? ?? '';
    final parts = fullName.split(' ');
    final firstName = parts.isNotEmpty ? parts[0] : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    
    return models.User(
      id: user.id,
      email: user.email ?? '',
      firstName: firstName,
      lastName: lastName,
      role: user.userMetadata?['role'] as String? ?? 'agent',
      permissions: List<String>.from(user.userMetadata?['permissions'] ?? []),
      phone: user.userMetadata?['phone'] as String?,
    );
  }

  Future<models.User> signIn(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.user == null) {
      throw Exception('Invalid session or user payload received.');
    }
    
    final fullName = response.user!.userMetadata?['full_name'] as String? ?? '';
    final parts = fullName.split(' ');
    final firstName = parts.isNotEmpty ? parts[0] : '';
    final lastName = response.user!.userMetadata?['last_name'] as String? ?? (parts.length > 1 ? parts.sublist(1).join(' ') : '');

    return models.User(
      id: response.user!.id,
      email: response.user!.email ?? '',
      firstName: firstName,
      lastName: lastName,
      role: response.user!.userMetadata?['role'] as String? ?? 'agent',
      permissions: List<String>.from(response.user!.userMetadata?['permissions'] ?? []),
      phone: response.user!.userMetadata?['phone'] as String?,
    );
  }

  Future<void> signUp(String email, String password, String firstName, String lastName) async {
    await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': '$firstName $lastName'.trim(),
        'role': 'agent',
        'permissions': ['read:conversations', 'write:messages'],
      },
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Database - Conversations
  Future<List<models.Conversation>> getConversations({String? status}) async {
    var query = client.from('whatsapp_conversations').select('*');
    if (status != null) {
      if (status == 'closed') {
        query = query.eq('status', 'closed');
      } else if (status == 'ai') {
        query = query.eq('status', 'active').eq('ai_enabled', true);
      } else if (status == 'human') {
        query = query.eq('status', 'active').eq('ai_enabled', false);
      }
    }
    
    final response = await query;
    final list = response as List<dynamic>;
    
    return list.map((c) {
      return models.Conversation(
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
  }

  // Realtime subscription for conversations
  Stream<List<Map<String, dynamic>>> subscribeConversations() {
    return client.from('whatsapp_conversations').stream(primaryKey: ['id']);
  }

  // Database - Messages
  Future<List<models.Message>> getConversationMessages(String conversationId, {int? limit}) async {
    var query = client
        .from('whatsapp_messages')
        .select('*')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);
    
    if (limit != null) {
      query = query.limit(limit);
    }

    final response = await query;
    final list = response as List<dynamic>;
    
    return list.map((m) {
      final isFromUser = m['is_from_user'] ?? (m['sender_type'] == 'customer');
      final sentByAi = m['sent_by_ai'] ?? (m['sender_type'] == 'ai');

      return models.Message(
        id: m['id'].toString(),
        conversationId: (m['conversation_id'] ?? m['conversationId'] ?? '') as String,
        content: (m['content'] ?? m['text'] ?? '') as String,
        senderId: (m['sender_id'] ?? m['senderId']) as String?,
        isFromUser: isFromUser as bool,
        sentByAi: sentByAi as bool,
        createdAt: (m['created_at'] ?? m['createdAt'] ?? '') as String,
        status: (m['status'] ?? 'sent') as String,
      );
    }).toList();
  }

  // Realtime subscription for messages in a conversation
  Stream<List<Map<String, dynamic>>> subscribeMessages(String conversationId) {
    return client
        .from('whatsapp_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId);
  }

  // Send Message
  Future<models.Message> sendMessage(String conversationId, String messageContent) async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null) {
      throw Exception('Session expired. Please log in again.');
    }

    // 1. Fetch conversation first to get contact_id (phone number)
    final convResponse = await client
        .from('whatsapp_conversations')
        .select('contact_id')
        .eq('id', conversationId)
        .single();

    final phone = convResponse['contact_id'] as String;

    // 2. Call the Next.js dashboard send API
    final ownerUserId = _cachedOwnerUserId ?? client.auth.currentUser?.id ?? '';
    final url = Uri.parse('${Constants.apiUrl}/whatsapp/send');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'x-syncflo-account-id': ownerUserId,
      },
      body: jsonEncode({
        'phone': phone,
        'message': messageContent,
        'conversationId': conversationId,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to send WhatsApp message via Meta gateway');
    }

    final responseData = jsonDecode(response.body);
    final waMessageId = responseData['waMessageId'] as String;

    // 3. Retrieve the created message from database for consistency
    try {
      final dbMessage = await client
          .from('whatsapp_messages')
          .select('*')
          .eq('whatsapp_message_id', waMessageId)
          .maybeSingle();

      if (dbMessage != null) {
        final isFromUser = dbMessage['is_from_user'] ?? (dbMessage['sender_type'] == 'customer');
        final sentByAi = dbMessage['sent_by_ai'] ?? (dbMessage['sender_type'] == 'ai');
        return models.Message(
          id: dbMessage['id'].toString(),
          conversationId: dbMessage['conversation_id'] as String,
          content: dbMessage['content'] as String,
          senderId: dbMessage['sender_id'] as String?,
          isFromUser: isFromUser as bool,
          sentByAi: sentByAi as bool,
          createdAt: dbMessage['created_at'] as String,
          status: dbMessage['status'] as String,
        );
      }
    } catch (_) {
      // Fallback if query failed
    }

    return models.Message(
      id: waMessageId,
      conversationId: conversationId,
      content: messageContent,
      senderId: client.auth.currentUser?.id,
      isFromUser: false,
      sentByAi: false,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      status: 'sent',
    );
  }

  // Mark conversation as read
  Future<void> markConversationRead(String conversationId) async {
    await client
        .from('whatsapp_conversations')
        .update({
          'unread_count': 0,
          'last_read_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', conversationId);
  }

  // Takeover conversation manually — calls Next.js dashboard API to toggle status
  Future<void> takeoverConversation(String conversationId) async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null) {
      throw Exception('Session expired. Please log in again.');
    }

    final ownerUserId = _cachedOwnerUserId ?? client.auth.currentUser?.id ?? '';
    final url = Uri.parse('${Constants.apiUrl}/whatsapp/takeover');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'x-syncflo-account-id': ownerUserId,
      },
      body: jsonEncode({
        'conversationId': conversationId,
        'status': 'escalated',
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to perform human takeover');
    }
  }

  // Resume AI control — calls Next.js dashboard API to toggle status
  Future<void> resumeAI(String conversationId) async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null) {
      throw Exception('Session expired. Please log in again.');
    }

    final ownerUserId = _cachedOwnerUserId ?? client.auth.currentUser?.id ?? '';
    final url = Uri.parse('${Constants.apiUrl}/whatsapp/takeover');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
        'x-syncflo-account-id': ownerUserId,
      },
      body: jsonEncode({
        'conversationId': conversationId,
        'status': 'active',
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to resume AI automation');
    }
  }

  // Assign conversation to an agent
  Future<void> assignConversation(String conversationId, String userId) async {
    await client
        .from('whatsapp_conversations')
        .update({
          'assigned_to': userId,
        })
        .eq('id', conversationId);
  }

  // AI Agents (View-only)
  Future<List<models.Agent>> getAgents() async {
    final response = await client.from('agents').select('*');
    final list = response as List<dynamic>;
    return list.map((a) => models.Agent.fromJson(a)).toList();
  }

  // Team Members
  Future<List<models.Profile>> getTeamMembers() async {
    // Get profiles
    final profilesRes = await client.from('profiles').select('*');
    final profilesList = profilesRes as List<dynamic>;

    // Get active chat workload (assigned chats that are not closed)
    final chatsRes = await client
        .from('whatsapp_conversations')
        .select('assigned_to')
        .neq('status', 'closed');
    final chatsList = chatsRes as List<dynamic>;

    // Calculate active chats count for each agent
    final Map<String, int> workload = {};
    for (var chat in chatsList) {
      final assigned = chat['assigned_to'] as String?;
      if (assigned != null) {
        workload[assigned] = (workload[assigned] ?? 0) + 1;
      }
    }

    return profilesList.map((p) {
      final pId = p['id'] as String;
      return models.Profile.fromJson(p, activeChats: workload[pId] ?? 0);
    }).toList();
  }

  // Get current user's full profile from profiles table
  Future<models.Profile?> getMyProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    // 1. Fetch own profile first
    final response = await client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    
    final myProfile = models.Profile.fromJson(response);
    
    // If we have a company name on our own profile, we ARE the owner
    if (myProfile.companyName != null && myProfile.companyName!.trim().isNotEmpty) {
      _cachedOwnerUserId = user.id;
      return models.Profile(
        id: myProfile.id,
        firstName: myProfile.firstName,
        lastName: myProfile.lastName,
        email: myProfile.email,
        role: myProfile.role,
        phone: myProfile.phone,
        companyName: myProfile.companyName,
        companySize: myProfile.companySize,
        industry: myProfile.industry,
        activeChats: myProfile.activeChats,
        ownerUserId: user.id,
      );
    }

    // 2. Otherwise, check if we are an invited agent in another workspace
    try {
      final membership = await client
          .from('account_members')
          .select('owner_user_id')
          .eq('member_user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (membership != null && membership['owner_user_id'] != null) {
        final ownerId = membership['owner_user_id'] as String;
        // Fetch the owner's profile to get their company_name
        final ownerResponse = await client
            .from('profiles')
            .select('company_name')
            .eq('id', ownerId)
            .maybeSingle();

        if (ownerResponse != null && ownerResponse['company_name'] != null) {
          _cachedOwnerUserId = ownerId;
          return models.Profile(
            id: myProfile.id,
            firstName: myProfile.firstName,
            lastName: myProfile.lastName,
            email: myProfile.email,
            role: myProfile.role,
            phone: myProfile.phone,
            companyName: ownerResponse['company_name'] as String,
            companySize: myProfile.companySize,
            industry: myProfile.industry,
            activeChats: myProfile.activeChats,
            ownerUserId: ownerId,
          );
        }
      }
    } catch (e) {
      debugPrint('[SupabaseService] Error loading workspace owner company name: $e');
    }

    _cachedOwnerUserId = user.id;
    return models.Profile(
      id: myProfile.id,
      firstName: myProfile.firstName,
      lastName: myProfile.lastName,
      email: myProfile.email,
      role: myProfile.role,
      phone: myProfile.phone,
      companyName: myProfile.companyName,
      companySize: myProfile.companySize,
      industry: myProfile.industry,
      activeChats: myProfile.activeChats,
      ownerUserId: user.id,
    );
  }

  // Billing & Subscriptions — query matching dashboard logic
  Future<models.Subscription?> getSubscription() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('subscriptions')
        .select('*')
        .eq('user_id', user.id)
        .inFilter('subscription_status', ['active', 'trial', 'cancelled'])
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return models.Subscription.fromJson(response);
  }

  // Usage data from user_usage table
  Future<models.UserUsage?> getUserUsage() async {
    final user = client.auth.currentUser;
    if (user == null) return null;

    final response = await client
        .from('user_usage')
        .select('*')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return models.UserUsage.fromJson(response);
  }

  // Notification Center Log
  Future<List<models.AppNotification>> getNotifications() async {
    final response = await client
        .from('notifications')
        .select('*')
        .order('created_at', ascending: false);
    final list = response as List<dynamic>;
    return list.map((n) => models.AppNotification.fromJson(n)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await client
        .from('notifications')
        .update({'read': true})
        .eq('id', id);
  }

  // Support
  Future<void> createSupportTicket(String subject, String description, String category, String priority) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Fetch profile for first_name and last_name
    final profileResponse = await client
        .from('profiles')
        .select('first_name, last_name')
        .eq('id', user.id)
        .maybeSingle();

    final firstName = profileResponse?['first_name'] as String?;
    final lastName = profileResponse?['last_name'] as String?;

    final ticket = {
      'user_id': user.id,
      'first_name': firstName,
      'last_name': lastName,
      'title': subject.trim(),
      'description': description.trim(),
      'category': category.isEmpty ? null : category,
      'priority': priority.isEmpty ? 'medium' : priority,
      'status': 'open',
    };

    await client.from('support_tickets').insert(ticket);
  }

  // Update Profile
  Future<void> updateProfile(String firstName, String lastName, String? phone) async {
    final user = client.auth.currentUser;
    if (user == null) return;

    // Update profiles table row
    await client.from('profiles').update({
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', user.id);

    // Update auth metadata
    await client.auth.updateUser(
      UserAttributes(
        data: {
          'full_name': '$firstName $lastName'.trim(),
          'phone': phone,
        },
      ),
    );
  }

  // Get Analytics Overview from Next.js API
  Future<Map<String, dynamic>> getAnalyticsOverview(String timeRange) async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null) {
      throw Exception('Session expired. Please log in again.');
    }

    final ownerUserId = _cachedOwnerUserId ?? client.auth.currentUser?.id ?? '';
    final url = Uri.parse('${Constants.apiUrl}/analytics/overview?range=$timeRange');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'x-syncflo-account-id': ownerUserId,
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to load analytics overview');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // CTWA - Get Connected Meta Ad Accounts & Destinations
  Future<Map<String, dynamic>> getCtwaAssets() async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null) {
      throw Exception('Session expired. Please log in again.');
    }

    final ownerUserId = _cachedOwnerUserId ?? client.auth.currentUser?.id ?? '';
    final url = Uri.parse('${Constants.apiUrl}/ctwa/assets');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'x-syncflo-account-id': ownerUserId,
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to load Meta ad assets');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // CTWA - Get Meta Billing Details
  Future<Map<String, dynamic>> getCtwaBilling({String? adAccountId}) async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null) {
      throw Exception('Session expired. Please log in again.');
    }

    final ownerUserId = _cachedOwnerUserId ?? client.auth.currentUser?.id ?? '';
    final query = adAccountId != null ? '?ad_account_id=${Uri.encodeComponent(adAccountId)}' : '';
    final url = Uri.parse('${Constants.apiUrl}/ctwa/billing$query');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'x-syncflo-account-id': ownerUserId,
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to load Meta billing details');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // CTWA - Get Ads Fetched Directly from Meta
  Future<List<dynamic>> getCtwaFetchedAds(String adAccountId) async {
    final session = client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null) {
      throw Exception('Session expired. Please log in again.');
    }

    final ownerUserId = _cachedOwnerUserId ?? client.auth.currentUser?.id ?? '';
    final url = Uri.parse('${Constants.apiUrl}/ctwa/fetched-ads?adAccountId=${Uri.encodeComponent(adAccountId)}');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'x-syncflo-account-id': ownerUserId,
      },
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Failed to fetch Meta ads');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['ads'] as List<dynamic>?) ?? [];
  }

  // Database - Leads / Contacts Management
  Future<List<models.Contact>> getLeads() async {
    final user = client.auth.currentUser;
    if (user == null) return [];

    final response = await client
        .from('leads')
        .select('*')
        .order('created_at', ascending: false);

    final list = response as List<dynamic>;
    return list.map((item) => models.Contact.fromJson(item as Map<String, dynamic>)).toList();
  }

  Stream<List<Map<String, dynamic>>> subscribeLeads() {
    return client.from('leads').stream(primaryKey: ['id']);
  }

  Future<models.Contact> createLead({
    required String name,
    required String phone,
    String? email,
    String? company,
    String status = 'new',
    String source = 'manual',
    double value = 0.0,
    List<String> tags = const [],
    String? assignedTo,
  }) async {
    final user = client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final payload = {
      'user_id': user.id,
      'name': name.trim(),
      'whatsapp_contact_id': phone.trim(),
      'email': email != null && email.trim().isNotEmpty ? email.trim() : null,
      'company': company != null && company.trim().isNotEmpty ? company.trim() : null,
      'status': status,
      'source': source,
      'value': value,
      'tags': tags,
      'assigned_to': assignedTo,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await client
        .from('leads')
        .insert(payload)
        .select()
        .single();

    return models.Contact.fromJson(response);
  }

  Future<void> updateLead(models.Contact contact) async {
    final payload = {
      'name': contact.name.trim(),
      'whatsapp_contact_id': contact.phone.trim(),
      'email': contact.email != null && contact.email!.trim().isNotEmpty ? contact.email!.trim() : null,
      'company': contact.company != null && contact.company!.trim().isNotEmpty ? contact.company!.trim() : null,
      'status': contact.status,
      'source': contact.source,
      'value': contact.value,
      'tags': contact.tags,
      'assigned_to': contact.assignedTo,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    await client.from('leads').update(payload).eq('id', contact.id);
  }

  Future<void> deleteLead(String leadId) async {
    await client.from('leads').delete().eq('id', leadId);
  }
}


