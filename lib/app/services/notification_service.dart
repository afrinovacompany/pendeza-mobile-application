import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

// This must be a top-level function (outside the class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📱 Background message: ${message.messageId}");
  // Handle background message
  if (message.notification != null) {
    print("📱 Background notification: ${message.notification!.title}");
  }
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize the Notification Service
  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Request Permissions (Critical for Android 13+ and iOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      log.i('User granted notification permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      log.i('User granted provisional permission');
    } else {
      log.w('User declined or has not accepted permission');
      return;
    }

    // 2. Setup Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Setup Local Notifications (For Foreground Display)
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationTap(response.payload);
      },
    );

    // 4. Create Android Notification Channel (High Importance)
    // ✅ FIXED: Enable BigPicture style and long text
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications with images.',
      importance: Importance.max,
      // REMOVED: priority: Priority.high,  ← not a valid parameter here
      enableVibration: true,
      playSound: true,
      enableLights: true,
      ledColor: Colors.blue,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log.d('📱 Got a message whilst in the foreground!');

      // Extract image URL from various possible fields
      String? imageUrl;
      if (message.data.containsKey('imageUrl')) {
        imageUrl = message.data['imageUrl'];
      } else if (message.data.containsKey('fcm_image')) {
        imageUrl = message.data['fcm_image'];
      } else if (message.data.containsKey('image')) {
        imageUrl = message.data['image'];
      }

      if (imageUrl != null) {
        log.d('🖼️ Image URL found: $imageUrl');
      }

      if (message.notification != null) {
        log.d('📱 Notification: ${message.notification!.title}');
        _showLocalNotification(message, imageUrl);
      }
    });

    // 6. Handle interaction when app opens from terminated state
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleBackgroundInteraction(message);
      }
    });

    // 7. Handle interaction when app opens from background state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundInteraction);

    _isInitialized = true;
    log.i("✅ NotificationService initialized");
  }

  /// Display a local notification when a message arrives in foreground
  /// ✅ FIXED: Properly handles images with BigPictureStyle
  Future<void> _showLocalNotification(RemoteMessage message, [String? imageUrl]) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null) {
      try {
        // ✅ Download image for BigPictureStyle if URL exists
        BigPictureStyleInformation? bigPictureStyle;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          try {
            final http.Response response = await http.get(Uri.parse(imageUrl));
            if (response.statusCode == 200) {
              final Uint8List imageBytes = response.bodyBytes;

              bigPictureStyle = BigPictureStyleInformation(
                ByteArrayAndroidBitmap(imageBytes),
                largeIcon: ByteArrayAndroidBitmap(imageBytes),
                contentTitle: notification.title,
                summaryText: notification.body,
                hideExpandedLargeIcon: false,
              );
              log.d('🖼️ Downloaded image for BigPictureStyle: ${imageBytes.length} bytes');
            }
          } catch (e) {
            log.e('❌ Failed to download notification image: $e');
          }
        }

        // ✅ Create notification details with proper style
        NotificationDetails notificationDetails = NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications with images.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            largeIcon: imageUrl != null
                ? const DrawableResourceAndroidBitmap('@mipmap/ic_launcher')
                : null,
            styleInformation: bigPictureStyle ??
                BigTextStyleInformation(notification.body ?? ''),  // ✅ use styleInformation
            silent: false,  // ✅ bool, not String
            ticker: notification.title,
            visibility: NotificationVisibility.public,
            enableLights: true,
            enableVibration: true,
            playSound: true,
            color: Colors.blue,
            ledColor: Colors.blue,
            ledOnMs: 1000,
            ledOffMs: 500,
          ),          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            attachments: imageUrl != null
                ? [DarwinNotificationAttachment(imageUrl)]
                : null,
          ),
        );

        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          notificationDetails,
          payload: message.data['route'] ?? jsonEncode(message.data),
        );

        log.d('✅ Local notification shown with ${imageUrl != null ? 'image' : 'text only'}');
      } catch (e) {
        log.e('❌ Error showing local notification: $e');

        // ✅ Fallback to simple notification
        await _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          payload: message.data['route'],
        );
      }
    }
  }

  /// Handle tap on notification (Background/Terminated)
  void _handleBackgroundInteraction(RemoteMessage message) {
    log.i("📱 Notification interaction detected");

    // Check for route in multiple places
    String? route;
    if (message.data.containsKey('route')) {
      route = message.data['route'];
    } else if (message.data.containsKey('actionRoute')) {
      route = message.data['actionRoute'];
    }

    if (route != null) {
      _navigate(route);
    }
  }

  /// Handle tap on local notification (Foreground)
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      try {
        // Try to parse JSON payload
        final Map<String, dynamic> data = jsonDecode(payload);
        if (data.containsKey('route')) {
          _navigate(data['route']);
        }
      } catch (e) {
        // Assume payload is direct route string
        _navigate(payload);
      }
    }
  }

  /// Navigation Logic using GoRouter
  void _navigate(String route) {
    log.i("📍 Navigating to: $route");
    // Use a slight delay to ensure the router is ready if app just launched
    Future.delayed(const Duration(milliseconds: 500), () {
      final router = AppRouter.router;
      router.push(route);
    });
  }

  /// Helper to subscribe to topics (e.g., "all_users", "promotions")
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    log.i("📌 Subscribed to topic: $topic");
  }

  /// Helper to unsubscribe
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
    log.i("📌 Unsubscribed from topic: $topic");
  }

  /// Get FCM token
  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      log.e('❌ Error getting FCM token: $e');
      return null;
    }
  }

  /// Send push notification to users by role
  Future<void> sendNotificationToRole({
    required String title,
    required String body,
    String? role,
    Map<String, dynamic>? data,
  }) async {
    try {
      log.i('📤 Sending notification via Cloud Function to role: ${role ?? "all"}');

      String targetAudience;
      if (role == null || role == 'all') {
        targetAudience = 'all';
      } else if (role == 'client') {
        targetAudience = 'clients';
      } else if (role == 'owner') {
        targetAudience = 'owners';
      } else {
        targetAudience = role;
      }

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable(
        'send_admin_notification',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60),
        ),
      );

      final result = await callable.call({
        'title': title,
        'body': body,
        'targetAudience': targetAudience,
        'imageUrl': data?['imageUrl'],  // ✅ Pass image URL
        'route': data?['route'],
        'customData': data,
        'priority': 'high',
        'saveToInbox': true,
      });

      final response = _convertToMap(result.data);

      if (response['success'] == true) {
        final analytics = response['analytics'] != null
            ? _convertToMap(response['analytics'])
            : null;
        log.i('✅ Notification sent successfully!');
        if (analytics != null) {
          log.i('   Tokens found: ${analytics['tokensFound']}');
          log.i('   Sent: ${analytics['sent']}');
          log.i('   Failed: ${analytics['failed']}');
        }
      } else {
        log.w('⚠️ Notification sent but with warnings: ${response['message']}');
      }
    } catch (e, stackTrace) {
      log.e('❌ Error sending notification: $e', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Helper method to safely convert dynamic map to Map<String, dynamic>
  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }
}