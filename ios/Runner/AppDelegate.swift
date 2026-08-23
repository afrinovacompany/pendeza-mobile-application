import Flutter
import UIKit
import FirebaseCore
import FirebaseMessaging

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Dart owns the Firebase DEFAULT app (main.dart Firebase.initializeApp).
        // Do not call FirebaseApp.configure() here: a second native init can
        // crash on launch if GoogleService-Info.plist is missing from the bundle
        // or its GOOGLE_APP_ID does not match DefaultFirebaseOptions.ios.

        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        attachMessagingDelegateIfFirebaseReady()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
        GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    }

    // MARK: - APNs Token Handling

    override func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        if FirebaseApp.app() != nil {
            attachMessagingDelegateIfFirebaseReady()
            Messaging.messaging().apnsToken = deviceToken
        }
        super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }

    override func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
        super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }

    // MARK: - Handle Notification When App is in Foreground

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo

        // Log notification for debugging
        print("Received notification in foreground: \(userInfo)")

        // Show notification banner even when app is in foreground
        if #available(iOS 14.0, *) {
            completionHandler([[.banner, .badge, .sound]])
        } else {
            completionHandler([[.alert, .badge, .sound]])
        }
    }

    // MARK: - Handle Notification Tap

    override func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Log notification tap for debugging
        print("User tapped notification: \(userInfo)")

        // Let Flutter handle the notification
        super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }

    private func attachMessagingDelegateIfFirebaseReady() {
        guard FirebaseApp.app() != nil else { return }
        Messaging.messaging().delegate = self
    }
}

// MARK: - Firebase Messaging Delegate

extension AppDelegate: MessagingDelegate {

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // Log FCM token for debugging
        print("Firebase FCM Token: \(fcmToken ?? "nil")")

        // Notify Flutter about token refresh
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}
