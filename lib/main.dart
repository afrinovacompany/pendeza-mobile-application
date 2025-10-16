import 'package:flutter/material.dart';
import 'app.dart';
import 'app/services/service_locator.dart'; // The new App Root widget
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // STEP 1: Ensure that Flutter's widget bindings are ready.
  // This is required before any async operations in main.
  WidgetsFlutterBinding.ensureInitialized();

  // STEP 2: Initialize Firebase.
  // This MUST happen before we initialize our own dependencies (GetIt)
  // because our services (like AuthService) depend on Firebase being ready.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // STEP 3: Now that Firebase is ready, initialize our services.
  await initializeDependencies();

  // STEP 4: Run the main application widget.
  runApp(const App());
}
