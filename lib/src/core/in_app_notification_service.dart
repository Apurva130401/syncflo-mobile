import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import '../widgets/in_app_notification_banner.dart';
import '../widgets/in_app_notification_modal.dart';
import 'app_router.dart';
import 'supabase_service.dart';

class InAppNotificationService {
  static final InAppNotificationService _instance = InAppNotificationService._internal();
  factory InAppNotificationService() => _instance;
  InAppNotificationService._internal();

  /// Global key to access the navigator state from outside the widget tree
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  RealtimeChannel? _channel;
  StreamSubscription<AuthState>? _authSub;
  bool _isListening = false;
  OverlayEntry? _currentOverlayEntry;

  /// Notification ids already shown, so a realtime redelivery (reconnect) doesn't show them twice.
  final Set<String> _shownIds = {};

  /// Unread notification count for badges (updated live).
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Starts listening to real-time notification inserts in Supabase.
  /// Should be called after the user has successfully signed in.
  void initialize() {
    if (_isListening) return;

    final client = SupabaseService().client;
    final user = client.auth.currentUser;
    if (user == null) return;

    _isListening = true;
    debugPrint('[InAppNotif] Initializing real-time listener');

    // Only this user's notifications.
    _channel = client
        .channel('public:notifications:in_app')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            try {
              final notification = AppNotification.fromJson(payload.newRecord);
              unreadCount.value = unreadCount.value + 1;
              if (_shownIds.add(notification.id)) showNotification(notification);
            } catch (e) {
              debugPrint('[InAppNotif] Error parsing notification record: $e');
            }
          },
        )
        .subscribe();

    refreshUnreadCount();
    // Fetch and check for any missed unread mobile modal notifications
    _checkMissedNotifications();

    // Clean up on logout (one listener, cancelled in dispose — it used to leak one per login).
    _authSub = client.auth.onAuthStateChange.listen((data) {
      if (data.session == null) dispose();
    });
  }

  /// Recounts unread notifications for the badge.
  Future<void> refreshUnreadCount() async {
    final client = SupabaseService().client;
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final rows = await client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('read', false);
      unreadCount.value = (rows as List).length;
    } catch (e) {
      debugPrint('[InAppNotif] Unread count failed: $e');
    }
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
        if (actionUrl.startsWith('mobile_modal:') && _shownIds.add(notification.id)) {
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
    _authSub?.cancel();
    _authSub = null;
    if (_channel != null) {
      SupabaseService().client.removeChannel(_channel!);
      _channel = null;
    }
    _shownIds.clear();
    unreadCount.value = 0;
    _isListening = false;
    debugPrint('[InAppNotif] Listener and overlays disposed');
  }

  /// Marks the notification as read in Supabase
  void _handleNotificationDismiss(AppNotification notification) {
    SupabaseService().markNotificationRead(notification.id).then((_) => refreshUnreadCount());
  }

  /// Handles routing or deep linking action when notification banner/modal is tapped
  void _handleNotificationAction(AppNotification notification) async {
    // Mark as read in Supabase
    _handleNotificationDismiss(notification);
    await openNotificationTarget(notification);
  }

  /// Opens the screen or link a notification points to. Also used by the notifications list.
  Future<void> openNotificationTarget(AppNotification notification) async {
    if (notification.actionUrl == null || notification.actionUrl!.isEmpty) return;
    if (navigatorKey.currentContext == null) return;

    var url = notification.actionUrl!;
    debugPrint('[InAppNotif] Handling notification action route: $url');

    // Strip mobile routing prefixes if present
    for (final prefix in const ['mobile_modal:', 'mobile_banner:', 'mobile:']) {
      if (url.startsWith(prefix)) {
        url = url.substring(prefix.length);
        break;
      }
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

    // Internal screens, including dashboard web paths such as /dashboard/billing.
    if (!AppRouter.openRoute(url)) {
      debugPrint('[InAppNotif] No mobile screen for route: $url');
    }
  }
}
