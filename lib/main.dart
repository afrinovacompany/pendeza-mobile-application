import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';   // ← NEW
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'app/services/service_locator.dart';
import 'app/services/notification_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // 1. Initialize Firebase (Dart owns the DEFAULT app; skip if native already did)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // 2. App Check: debug providers stay on debug/profile only.
  // iOS store/release uses App Attest. Android release is unchanged.
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: AndroidDebugProvider(),
      providerApple: kReleaseMode
          ? AppleAppAttestProvider()
          : AppleDebugProvider(),
    );
  } catch (e) {
    debugPrint('Firebase App Check activate failed: $e');
  }

  // 🔥 3. Crashlytics - catches even native crashes before Dart starts
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

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