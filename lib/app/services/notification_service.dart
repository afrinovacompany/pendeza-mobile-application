import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/app/config/app_router.dart';

// This must be a top-level function (outside the class)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You can initialize Firebase here if needed for background logic
  // await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
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
    AndroidInitializationSettings(
        '@mipmap/ic_launcher'); // Ensure this icon exists

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
    // This ensures heads-up notifications work on Android 8+
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      description:
      'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 5. Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      log.d('Got a message whilst in the foreground!');
      log.d('Message data: ${message.data}');

      if (message.notification != null) {
        log.d('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
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
    log.i("NotificationService initialized");
  }

  /// Display a local notification when a message arrives in foreground
  void _showLocalNotification(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription:
            'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        // Pass the route or data as payload
        payload: message.data['route'],
      );
    }
  }

  /// Handle tap on notification (Background/Terminated)
  void _handleBackgroundInteraction(RemoteMessage message) {
    log.i("Notification interaction detected");
    if (message.data.containsKey('route')) {
      _navigate(message.data['route']);
    }
  }

  /// Handle tap on local notification (Foreground)
  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      _navigate(payload);
    }
  }

  /// Navigation Logic using GoRouter
  void _navigate(String route) {
    log.i("Navigating to route from notification: $route");
    // Use a slight delay to ensure the router is ready if app just launched
    Future.delayed(const Duration(milliseconds: 500), () {
      final router = AppRouter.router;
      router.push(route);
    });
  }

  /// Helper to subscribe to topics (e.g., "all_users", "promotions")
  Future<void> subscribeToTopic(String topic) async {
    await _fcm.subscribeToTopic(topic);
    log.i("Subscribed to topic: $topic");
  }

  /// Helper to unsubscribe
  Future<void> unsubscribeFromTopic(String topic) async {
    await _fcm.unsubscribeFromTopic(topic);
  }

  /// Send push notification to users by role
  ///
  /// This uses your EXISTING Cloud Function: send_admin_notification
  /// No need to deploy anything new - it's already deployed!
  ///
  /// [title] - The notification title
  /// [body] - The notification message body
  /// [role] - Target role: null/'all' for all users, 'client' for clients, 'owner' for owners
  /// [data] - Optional additional data to include with notification
  Future<void> sendNotificationToRole({
    required String title,
    required String body,
    String? role, // null = all users, 'client', 'owner'
    Map<String, dynamic>? data,
  }) async {
    try {
      log.i('Sending notification via Cloud Function to role: ${role ?? "all"}');

      // Map role to targetAudience format expected by Cloud Function
      String targetAudience;
      if (role == null || role == 'all') {
        targetAudience = 'all';
      } else if (role == 'client') {
        targetAudience = 'clients'; // Note: plural form for Cloud Function
      } else if (role == 'owner') {
        targetAudience = 'owners'; // Note: plural form for Cloud Function
      } else {
        targetAudience = role;
      }

      // Call the existing Cloud Function: send_admin_notification
      // IMPORTANT: Specify the region where your functions are deployed
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable(
        'send_admin_notification',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 60), // Longer timeout for large sends
        ),
      );

      final result = await callable.call({
        'title': title,
        'body': body,
        'targetAudience': targetAudience,
        'imageUrl': null, // Optional: add if you support images
        'route': data?['route'], // Optional: navigation route
        'customData': data, // Optional: additional data
        'priority': 'high',
        'saveToInbox': true, // Save to notification_inbox collection
      });

      // 🔥 FIX: Properly convert the response to Map<String, dynamic>
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

  /// Alternative: Send notification to topic
  ///
  /// Users must subscribe to topics first using subscribeToTopic()
  Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      log.i('Sending notification to topic: $topic');

      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable(
        'send_admin_notification',
      );

      final result = await callable.call({
        'title': title,
        'body': body,
        'targetAudience': 'topic:$topic',
        'customData': data,
        'priority': 'high',
        'saveToInbox': true,
      });

      // 🔥 FIX: Properly convert the response
      final response = _convertToMap(result.data);
      log.i('Notification sent to topic successfully: $response');
    } catch (e, stackTrace) {
      log.e('Error sending notification to topic: $e',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// 🔥 Helper method to safely convert dynamic map to Map<String, dynamic>
  /// This fixes the type cast error: '_Map<Object?, Object?>' is not a subtype of type 'Map<String, dynamic>'
  Map<String, dynamic> _convertToMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {};
  }
}