import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../widgets/in_app_notification_banner.dart';
import '../widgets/in_app_notification_modal.dart';
import '../screens/home_screen.dart';
import '../screens/inbox/conversation_list.dart';
import '../screens/analytics/analytics_screen.dart';
import '../screens/agents/agents_screen.dart';
import '../screens/team/team_screen.dart';
import '../screens/notifications/notifications_center_screen.dart';
import '../screens/billing/billing_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/support/support_screen.dart';
import 'supabase_service.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  /// Global key to access the navigator state from outside the widget tree
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  RealtimeChannel? _channel;
  bool _isListening = false;
  OverlayEntry? _currentOverlayEntry;

  /// Starts listening to real-time notification inserts in Supabase.
  /// Should be called after the user has successfully signed in.
  void initialize() {
    if (_isListening) return;

    final client = SupabaseService().client;
    final user = client.auth.currentUser;
    if (user == null) return;

    _isListening = true;
    debugPrint('[InAppNotif] Initializing real-time listener for user: ${user.id}');

    // Subscribe to INSERT events on the notifications table
    _channel = client
        .channel('public:notifications:in_app')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) {
            final record = payload.newRecord;
            try {
              final notification = AppNotification.fromJson(record);
              showNotification(notification);
            } catch (e) {
              debugPrint('[InAppNotif] Error parsing notification record: $e');
            }
          },
        )
        .subscribe();

    // Fetch and check for any missed unread mobile modal notifications
    _checkMissedNotifications();

    // Listen for auth changes to clean up listeners on logout
    client.auth.onAuthStateChange.listen((data) {
      if (data.session == null) {
        dispose();
      }
    });
  }

  /// Queries the database for the latest unread mobile-modal notification
  /// and shows it if found.
  Future<void> _checkMissedNotifications() async {
    final client = SupabaseService().client;
    final user = client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await client
          .from('notifications')
          .select('*')
          .eq('user_id', user.id)
          .eq('read', false)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final notification = AppNotification.fromJson(response);
        final actionUrl = notification.actionUrl ?? '';
        if (actionUrl.startsWith('mobile_modal:')) {
          showNotification(notification);
        }
      }
    } catch (e) {
      debugPrint('[InAppNotif] Error checking missed notifications: $e');
    }
  }

  /// Displays an animated in-app notification banner or a modal dialog
  void showNotification(AppNotification notification) {
    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint('[InAppNotif] Navigator context is null, cannot display alert');
      return;
    }

    final actionUrl = notification.actionUrl ?? '';
    if (actionUrl.startsWith('mobile_modal:')) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return InAppNotificationModalWidget(
            notification: notification,
            onAction: () {
              Navigator.of(dialogContext).pop();
              _handleNotificationAction(notification);
            },
            onDismiss: () {
              Navigator.of(dialogContext).pop();
              _handleNotificationDismiss(notification);
            },
          );
        },
      );
      return;
    }

    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) {
      debugPrint('[InAppNotif] Overlay state is null, cannot display banner');
      return;
    }

    // Instantly remove previous overlay if still active
    _removeOverlayEntry();

    _currentOverlayEntry = OverlayEntry(
      builder: (context) {
        return InAppNotificationBannerWidget(
          notification: notification,
          onAction: () {
            _removeOverlayEntry();
            _handleNotificationAction(notification);
          },
          onDismissComplete: () {
            _removeOverlayEntry();
            _handleNotificationDismiss(notification);
          },
        );
      },
    );

    overlayState.insert(_currentOverlayEntry!);
  }

  void _removeOverlayEntry() {
    if (_currentOverlayEntry != null) {
      _currentOverlayEntry!.remove();
      _currentOverlayEntry = null;
    }
  }

  /// Disposes of the active listener channel and clears overlays
  void dispose() {
    _removeOverlayEntry();
    if (_channel != null) {
      SupabaseService().client.removeChannel(_channel!);
      _channel = null;
    }
    _isListening = false;
    debugPrint('[InAppNotif] Listener and overlays disposed');
  }

  /// Marks the notification as read in Supabase
  void _handleNotificationDismiss(AppNotification notification) {
    SupabaseService().markNotificationRead(notification.id);
  }

  /// Handles routing or deep linking action when notification banner/modal is tapped
  void _handleNotificationAction(AppNotification notification) async {
    // Mark as read in Supabase
    _handleNotificationDismiss(notification);

    if (notification.actionUrl == null || notification.actionUrl!.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    var url = notification.actionUrl!;
    debugPrint('[InAppNotif] Handling notification action route: $url');
    
    // Strip mobile routing prefixes if present
    if (url.startsWith('mobile_modal:')) {
      url = url.substring('mobile_modal:'.length);
    } else if (url.startsWith('mobile_banner:')) {
      url = url.substring('mobile_banner:'.length);
    } else if (url.startsWith('mobile:')) {
      url = url.substring('mobile:'.length);
    }

    // Handle external website URL redirection
    if (url.startsWith('http://') || url.startsWith('https://')) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('[InAppNotif] Could not launch external URL: $url');
      }
      return;
    }

    // Handle internal screen routing
    Widget? destination;
    if (url == '/notifications') {
      destination = const NotificationsCenterScreen();
    } else if (url == '/inbox') {
      destination = const ConversationListScreen();
    } else if (url == '/analytics') {
      destination = const AnalyticsScreen();
    } else if (url == '/agents') {
      destination = const AgentsScreen();
    } else if (url == '/team') {
      destination = const TeamScreen();
    } else if (url == '/billing') {
      destination = const BillingScreen();
    } else if (url == '/settings') {
      destination = const SettingsScreen();
    } else if (url == '/support') {
      destination = const SupportScreen();
    } else if (url == '/overview') {
      destination = const HomeScreen();
    }

    if (destination != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => destination!),
      );
    }
  }
}
