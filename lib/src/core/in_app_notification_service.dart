import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../widgets/in_app_notification_banner.dart';
import '../widgets/in_app_notification_modal.dart';
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

    // Listen for auth changes to clean up listeners on logout
    client.auth.onAuthStateChange.listen((data) {
      if (data.session == null) {
        dispose();
      }
    });
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

  /// Handles routing or deep linking action when notification banner is tapped
  void _handleNotificationAction(AppNotification notification) {
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

    if (url.startsWith('/')) {
      Navigator.of(context).pushNamed(url);
    }
  }
}
