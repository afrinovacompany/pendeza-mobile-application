import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:firebase_app_check/firebase_app_check.dart'; // 🔥 Import this
import 'app.dart';
import 'app/services/service_locator.dart';
import 'app/services/notification_service.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 1. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔥 2. ACTIVATE APP CHECK (Debug Provider) - Updated to new parameter names to avoid deprecation warnings
  // This tells Firebase: "I am a developer, please trust this device if I give you the token."
  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidDebugProvider(),
    providerApple: AppleDebugProvider(),
  );

  await initializeDependencies();
  NotificationService().init();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('sw')],
      path: 'assets/language',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      saveLocale: true,
      child: const App(),
    ),
  );
}