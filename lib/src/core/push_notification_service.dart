import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'active_chat.dart';
import 'app_router.dart';
import 'notification_prefs.dart';

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

  static const _messagesChannelId = 'syncflo_messages';
  static const _callsChannelId = 'syncflo_calls';
  static const _tokenPrefKey = 'fcm_token';

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

    // On iOS the system would show its own banner for foreground pushes on top of our local one.
    await _messaging.setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false);

    // Set up local notification channels for foreground messages
    await _setupLocalNotifications();

    // Get and register the FCM token
    await _registerToken();

    // Listen for token refresh
    _messaging.onTokenRefresh.listen(_saveTokenToSupabase);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Check if app was opened from a terminated state via a push
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // ...or via one of our own local notifications
    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _openAfterFrame(launch?.notificationResponse?.payload);
    }
  }

  /// Set up the local notification plugin for showing foreground notifications
  Future<void> _setupLocalNotifications() async {
    const messagesChannel = AndroidNotificationChannel(
      _messagesChannelId,
      'SyncFlo Messages',
      description: 'New message notifications from SyncFlo Dashboard',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );
    const callsChannel = AndroidNotificationChannel(
      _callsChannelId,
      'AI Calls',
      description: 'Incoming and finished WhatsApp AI calls',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final android = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(messagesChannel);
    await android?.createNotificationChannel(callsChannel);

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    // Permission is already requested through Firebase above.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: darwinSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[LocalNotif] Tapped notification: ${response.payload}');
        AppRouter.openPayload(response.payload);
      },
    );
  }

  /// Get the FCM token and save it to Supabase
  Future<void> _registerToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Device token registered (${token.length} chars)');
        await _saveTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
    }
  }

  String get _platform => Platform.isAndroid ? 'android' : 'ios';

  /// Save the FCM token in the device_tokens table.
  ///
  /// The table is unique on (user_id, token) and its RLS only allows select/insert/delete,
  /// so we insert-ignore-duplicates (never UPDATE) and remove the token this device used
  /// before, so the dashboard doesn't keep pushing to stale tokens.
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final previous = prefs.getString(_tokenPrefKey);
      if (previous != null && previous != token) {
        await client.from('device_tokens').delete().eq('user_id', user.id).eq('token', previous);
      }

      await client.from('device_tokens').upsert(
        {
          'user_id': user.id,
          'token': token,
          'platform': _platform,
          'last_used_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,token',
        ignoreDuplicates: true,
      );
      await prefs.setString(_tokenPrefKey, token);
      debugPrint('[FCM] Token saved to device_tokens table');
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
    }
  }

  /// Show a local notification when a push arrives while the app is in the foreground.
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final conversationId = (data['conversationId'] ?? data['conversation_id'])?.toString();
    final type = data['type']?.toString() ?? '';
    final isCall = type.contains('call');

    // Don't alert for the chat that is already open on screen.
    if (conversationId != null && conversationId == ActiveChat.conversationId) return;

    if (isCall ? !await NotificationPrefs.calls() : !await NotificationPrefs.messages()) return;

    await showLocalNotification(
      // Same id as the realtime alert for this chat, so the two replace each other instead of doubling up.
      conversationId != null ? conversationId.hashCode : notification.hashCode,
      notification.title ?? 'SyncFlo Dashboard',
      notification.body ?? 'You have a new message',
      payload: isCall ? 'calls' : (conversationId != null ? 'chat:$conversationId' : null),
      channelId: isCall ? _callsChannelId : _messagesChannelId,
    );
  }

  /// Handle when the user taps a push (app in background)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('[FCM] Notification tapped: ${message.data}');
    final data = message.data;
    final conversationId = (data['conversationId'] ?? data['conversation_id'])?.toString();
    final type = data['type']?.toString() ?? '';
    if (type.contains('call')) {
      _openAfterFrame('calls');
    } else if (conversationId != null && conversationId.isNotEmpty) {
      _openAfterFrame('chat:$conversationId');
    }
  }

  /// Waits for the first frame so the navigator exists on a cold start.
  void _openAfterFrame(String? payload) {
    if (payload == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () => AppRouter.openPayload(payload));
    });
  }

  /// Remove this device's token when the user logs out
  Future<void> removeToken() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) return;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenPrefKey);
      var query = client.from('device_tokens').delete().eq('user_id', user.id);
      query = token != null ? query.eq('token', token) : query.eq('platform', _platform);
      await query;
      await prefs.remove(_tokenPrefKey);

      // Let the next login on this device re-initialize cleanly.
      _initialized = false;
      debugPrint('[FCM] Token removed from device_tokens');
    } catch (e) {
      debugPrint('[FCM] Error removing token: $e');
    }
  }

  /// Show a local notification (foreground alerts, takeover warnings, AI call updates).
  Future<void> showLocalNotification(
    int id,
    String title,
    String body, {
    String? payload,
    String channelId = _messagesChannelId,
  }) async {
    final isCalls = channelId == _callsChannelId;
    await _localNotifications.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          isCalls ? 'AI Calls' : 'SyncFlo Messages',
          channelDescription:
              isCalls ? 'Incoming and finished WhatsApp AI calls' : 'New message notifications from SyncFlo Dashboard',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@drawable/ic_notification',
          playSound: await NotificationPrefs.sound(),
        ),
        iOS: DarwinNotificationDetails(
          presentSound: await NotificationPrefs.sound(),
        ),
      ),
      payload: payload,
    );
  }
}
