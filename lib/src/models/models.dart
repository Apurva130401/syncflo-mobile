export 'contact.dart';

class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final List<String> permissions;
  final String? phone;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.permissions,
    this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      role: json['role'] as String,
      permissions: List<String>.from(json['permissions'] ?? []),
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'permissions': permissions,
      'phone': phone,
    };
  }
}

class Conversation {
  final String id;
  final String contactId;
  final String contactName;
  final String status; // 'ai' | 'human' | 'resolved'
  final String? lastMessage;
  final int unreadCount;
  final String? assignedTo;
  final String? humanTakeoverStartedAt;
  final bool aiEnabled;
  final String? humanLastActivityAt;
  final int? humanTakeoverTimeoutMinutes;
  final String? humanTakeoverBy;

  Conversation({
    required this.id,
    required this.contactId,
    required this.contactName,
    required this.status,
    this.lastMessage,
    required this.unreadCount,
    this.assignedTo,
    this.humanTakeoverStartedAt,
    required this.aiEnabled,
    this.humanLastActivityAt,
    this.humanTakeoverTimeoutMinutes,
    this.humanTakeoverBy,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      contactId: json['contactId'] as String,
      contactName: json['contactName'] as String,
      status: json['status'] as String,
      lastMessage: json['lastMessage'] as String?,
      unreadCount: json['unreadCount'] as int? ?? 0,
      assignedTo: json['assignedTo'] as String?,
      humanTakeoverStartedAt: json['humanTakeoverStartedAt'] as String?,
      aiEnabled: json['aiEnabled'] as bool? ?? true,
      humanLastActivityAt: json['humanLastActivityAt'] as String?,
      humanTakeoverTimeoutMinutes: json['humanTakeoverTimeoutMinutes'] as int?,
      humanTakeoverBy: json['humanTakeoverBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactId': contactId,
      'contactName': contactName,
      'status': status,
      'lastMessage': lastMessage,
      'unreadCount': unreadCount,
      'assignedTo': assignedTo,
      'humanTakeoverStartedAt': humanTakeoverStartedAt,
      'aiEnabled': aiEnabled,
      'humanLastActivityAt': humanLastActivityAt,
      'humanTakeoverTimeoutMinutes': humanTakeoverTimeoutMinutes,
      'humanTakeoverBy': humanTakeoverBy,
    };
  }
}

class Message {
  final String id;
  final String conversationId;
  final String content;
  final String? senderId;
  final bool isFromUser;
  final bool sentByAi;
  final String createdAt;
  final String status; // 'sent' | 'delivered' | 'read' | 'failed'

  Message({
    required this.id,
    required this.conversationId,
    required this.content,
    this.senderId,
    required this.isFromUser,
    required this.sentByAi,
    required this.createdAt,
    required this.status,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      content: json['content'] as String,
      senderId: json['senderId'] as String?,
      isFromUser: json['isFromUser'] as bool? ?? false,
      sentByAi: json['sentByAi'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      status: json['status'] as String? ?? 'sent',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'content': content,
      'senderId': senderId,
      'isFromUser': isFromUser,
      'sentByAi': sentByAi,
      'createdAt': createdAt,
      'status': status,
    };
  }
}

class AuthSession {
  final User user;
  final String accessToken;
  final String refreshToken;
  final int? expiresAt;

  AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.expiresAt,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: User.fromJson(json['user']),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: json['expiresAt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt,
    };
  }
}

class Agent {
  final String id;
  final String name;
  final String description;
  final bool isActive;
  final String systemPrompt;
  final String tone;

  Agent({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.systemPrompt,
    required this.tone,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] as String,
      name: (json['name'] ?? json['agent_name'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      isActive: (json['is_active'] ?? true) as bool,
      systemPrompt: (json['system_prompt'] ?? '') as String,
      tone: (json['tone'] ?? 'professional') as String,
    );
  }
}

class Profile {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final String? phone;
  final String? companyName;
  final String? companySize;
  final String? industry;
  final int activeChats;
  /// The workspace owner's user ID. For owners, this equals their own `id`.
  /// For invited agents, this is the owner's user ID from account_members.
  final String? ownerUserId;

  Profile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.phone,
    this.companyName,
    this.companySize,
    this.industry,
    this.activeChats = 0,
    this.ownerUserId,
  });

  factory Profile.fromJson(Map<String, dynamic> json, {int activeChats = 0}) {
    return Profile(
      id: json['id'] as String,
      firstName: (json['first_name'] ?? '') as String,
      lastName: (json['last_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      role: (json['role'] ?? 'user') as String,
      phone: json['phone'] as String?,
      companyName: json['company_name'] as String?,
      companySize: json['company_size'] as String?,
      industry: json['industry'] as String?,
      activeChats: activeChats,
      ownerUserId: null, // set explicitly after member lookup
    );
  }
}

class Subscription {
  final String userId;
  final String subscriptionStatus; // active, trial, cancelled, expired
  final String? currentPlan;       // e.g. "whatsapp-starter"
  final String? billingCycle;      // monthly, yearly
  final String? subscriptionStartDate;
  final String? subscriptionEndDate;
  final String? trialEndDate;
  final bool cancelAtPeriodEnd;
  final String? whatsappSubscriptionStatus;
  final String? whatsappPlanId;
  final String? voiceSubscriptionStatus;
  final String? voicePlanId;

  Subscription({
    required this.userId,
    required this.subscriptionStatus,
    this.currentPlan,
    this.billingCycle,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.trialEndDate,
    this.cancelAtPeriodEnd = false,
    this.whatsappSubscriptionStatus,
    this.whatsappPlanId,
    this.voiceSubscriptionStatus,
    this.voicePlanId,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      userId: (json['user_id'] ?? '') as String,
      subscriptionStatus: (json['subscription_status'] ?? 'trial') as String,
      currentPlan: json['current_plan'] as String?,
      billingCycle: json['billing_cycle'] as String?,
      subscriptionStartDate: json['subscription_start_date']?.toString(),
      subscriptionEndDate: json['subscription_end_date']?.toString(),
      trialEndDate: json['trial_end_date']?.toString(),
      cancelAtPeriodEnd: (json['cancel_at_period_end'] ?? false) as bool,
      whatsappSubscriptionStatus: json['whatsapp_subscription_status'] as String?,
      whatsappPlanId: json['whatsapp_plan_id'] as String?,
      voiceSubscriptionStatus: json['voice_subscription_status'] as String?,
      voicePlanId: json['voice_plan_id'] as String?,
    );
  }
}

class UserUsage {
  final String userId;
  final String? planName;
  final int messageCredits;
  final int usedMessages;
  final int minuteCredits;
  final int usedVoice;
  final String? periodStart;
  final String? periodEnd;

  UserUsage({
    required this.userId,
    this.planName,
    required this.messageCredits,
    required this.usedMessages,
    required this.minuteCredits,
    required this.usedVoice,
    this.periodStart,
    this.periodEnd,
  });

  factory UserUsage.fromJson(Map<String, dynamic> json) {
    return UserUsage(
      userId: (json['user_id'] ?? '') as String,
      planName: json['plan_name'] as String?,
      messageCredits: (json['message_credits'] ?? 0) as int,
      usedMessages: (json['used_messages'] ?? 0) as int,
      minuteCredits: (json['minute_credits'] ?? 0) as int,
      usedVoice: (json['used_voice'] ?? 0) as int,
      periodStart: json['period_start']?.toString(),
      periodEnd: json['period_end']?.toString(),
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool read;
  final String? actionUrl;
  final String createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.read,
    this.actionUrl,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      title: (json['title'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      type: (json['type'] ?? 'info') as String,
      read: (json['read'] ?? false) as bool,
      actionUrl: json['action_url'] as String?,
      createdAt: (json['created_at'] ?? '') as String,
    );
  }
}

class SupportTicket {
  final String id;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String createdAt;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] as String,
      subject: (json['subject'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      category: (json['category'] ?? 'general') as String,
      priority: (json['priority'] ?? 'medium') as String,
      status: (json['status'] ?? 'open') as String,
      createdAt: (json['created_at'] ?? '') as String,
    );
  }
}
