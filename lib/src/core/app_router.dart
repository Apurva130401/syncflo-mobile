import 'package:flutter/material.dart';
import '../screens/agents/agents_screen.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/billing/billing_screen.dart';
import '../screens/calls/calls_screen.dart';
import '../screens/contacts/contacts_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inbox/chat_thread.dart';
import '../screens/inbox/conversation_list.dart';
import '../screens/notifications/notifications_center_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/support/support_screen.dart';
import '../screens/team/team_screen.dart';
import 'in_app_notification_service.dart';
import 'supabase_service.dart';

/// Opens screens from outside the widget tree (push taps, in-app banners).
class AppRouter {
  static NavigatorState? get _nav => InAppNotificationService.navigatorKey.currentState;

  /// Opens one chat. Falls back to the inbox list if the conversation can't be loaded.
  static Future<void> openConversation(String conversationId) async {
    final nav = _nav;
    if (nav == null) return;
    try {
      final conversation = await SupabaseService().getConversation(conversationId);
      if (conversation != null) {
        nav.push(MaterialPageRoute(builder: (_) => ChatThreadScreen(conversation: conversation)));
        return;
      }
    } catch (e) {
      debugPrint('[AppRouter] Could not load conversation $conversationId: $e');
    }
    nav.push(MaterialPageRoute(builder: (_) => const ConversationListScreen()));
  }

  static void openCalls() {
    _nav?.push(MaterialPageRoute(builder: (_) => const CallsScreen()));
  }

  /// Handles a push/local notification payload: `chat:<id>`, `calls`, or a bare conversation id.
  static void openPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    if (payload == 'calls' || payload.startsWith('call:')) {
      openCalls();
    } else if (payload.startsWith('chat:')) {
      openConversation(payload.substring(5));
    } else {
      openConversation(payload);
    }
  }

  /// Maps an in-app route (`/inbox`) or a dashboard web path (`/dashboard/billing`) to a mobile screen.
  /// Returns false when there is no matching mobile screen.
  static bool openRoute(String route) {
    final nav = _nav;
    if (nav == null) return false;

    var path = route.split('?').first;
    if (path.startsWith('/dashboard/')) path = path.substring('/dashboard'.length);

    Widget? destination;
    if (path == '/notifications') {
      destination = const NotificationsCenterScreen();
    } else if (path == '/inbox' || path.startsWith('/whatsapp/inbox') || path.startsWith('/whatsapp/logs')) {
      destination = const ConversationListScreen();
    } else if (path.startsWith('/whatsapp/calling') || path == '/calls') {
      destination = const CallsScreen();
    } else if (path == '/analytics') {
      destination = const AnalyticsScreen();
    } else if (path == '/agents') {
      destination = const AgentsScreen();
    } else if (path == '/team') {
      destination = const TeamScreen();
    } else if (path == '/billing') {
      destination = const BillingScreen();
    } else if (path == '/settings' || path == '/account') {
      destination = const SettingsScreen();
    } else if (path == '/support') {
      destination = const SupportScreen();
    } else if (path == '/contacts' || path.startsWith('/whatsapp/leads')) {
      destination = const ContactsScreen();
    } else if (path == '/overview' || path == '/' || path.isEmpty) {
      destination = const HomeScreen();
    }

    if (destination == null) return false;
    nav.push(MaterialPageRoute(builder: (_) => destination!));
    return true;
  }
}
