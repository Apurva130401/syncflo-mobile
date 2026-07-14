import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Top-level background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM] Background message: ${message.messageId}');
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize Firebase, request permissions, get token, and set up listeners.
  /// Call this once after Firebase.initializeApp() and after user is logged in.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permission (Android 13+ and iOS)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] User denied notification permission');
      return;
    }

    // Set up local notification channel for Android foreground messages
    await _setupLocalNotifications();

    // Get and register the FCM token
    await _registerToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToSupabase(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  /// Set up the local notification plugin for showing foreground notifications
  Future<void> _setupLocalNotifications() async {
    const androidChannel = AndroidNotificationChannel(
      'syncflo_messages',
      'SyncFlo Messages',
      description: 'New message notifications from SyncFlo Dashboard',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Create the notification channel on Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[LocalNotif] Tapped notification: ${response.payload}');
        // Future: navigate to specific conversation using payload
      },
    );
  }

  /// Get the FCM token and save it to Supabase
  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Device token: ${token.substring(0, 20)}...');
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  /// Save/update the FCM token in the device_tokens table
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      // Upsert: if a row with the same user_id and platform exists, update it
      await client.from('device_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'last_used_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id, platform',
      );

      debugPrint('[FCM] Token saved to device_tokens table');
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
      // Fallback: try insert if upsert fails (unique constraint might not exist)
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user == null) return;

        // Delete old tokens for this user+platform, then insert new one
        await client.from('device_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('platform', Platform.isAndroid ? 'android' : 'ios');

        await client.from('device_tokens').insert({
          'user_id': user.id,
          'token': token,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'last_used_at': DateTime.now().toUtc().toIso8601String(),
        });

        debugPrint('[FCM] Token saved via fallback insert');
      } catch (e2) {
        debugPrint('[FCM] Fallback insert also failed: $e2');
      }
    }
  }

  /// Show a local notification when a message arrives while the app is in the foreground
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM] Foreground message: ${message.notification?.title}');

    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'SyncFlo Dashboard',
      notification.body ?? 'You have a new message',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'syncflo_messages',
          'SyncFlo Messages',
          channelDescription: 'New message notifications from SyncFlo Dashboard',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
      ),
      payload: message.data['conversation_id'],
    );
  }

  /// Handle when the user taps a notification (app in background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    // Future: navigate to the specific conversation
    // final conversationId = message.data['conversation_id'];
  }

  /// Remove the device token when user logs out
  Future<void> removeToken() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      await client.from('device_tokens')
          .delete()
          .eq('user_id', user.id)
          .eq('platform', Platform.isAndroid ? 'android' : 'ios');

      debugPrint('[FCM] Token removed from device_tokens');
    } catch (e) {
      debugPrint('[FCM] Error removing token: $e');
    }
  }

  /// Show a manual local notification (e.g. for human takeover auto-resume alerts)
  Future<void> showLocalNotification(int id, String title, String body, {String? payload}) async {
    await _localNotifications.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'syncflo_messages',
          'SyncFlo Messages',
          channelDescription: 'New message notifications from SyncFlo Dashboard',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
        ),
      ),
      payload: payload,
    );
  }
}
