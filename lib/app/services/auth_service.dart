import 'dart:convert';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../utils/logger.dart'; // Assumed to exist for logging

/// User dismissed a social sign-in sheet. BLoC should return to the previous
/// state without showing an error.
class AuthCancelledException implements Exception {
  const AuthCancelledException();

  @override
  String toString() => 'cancelled';
}

/// Typed failure from Briq OTP request/verify so the BLoC can map codes to UI.
class PhoneAuthException implements Exception {
  final String code;
  final String message;
  final String? recoveryHint;
  final int? cooldownSeconds;

  const PhoneAuthException({
    required this.code,
    required this.message,
    this.recoveryHint,
    this.cooldownSeconds,
  });

  @override
  String toString() => message;
}

/// A service class to handle all Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // FIX 1: Use the singleton instance instead of the constructor
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // Track initialization status to avoid calling initialize() multiple times
  bool _isGoogleSignInInitialized = false;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

  /// Helper to ensure Google Sign-In is initialized (Required in v7)
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    try {
      await _googleSignIn.initialize();
      _isGoogleSignInInitialized = true;
    } catch (e) {
      log.e('Failed to initialize Google Sign-In', error: e);
    }
  }

  /// Signs up a new user with an email and password.
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      log.i('Successfully signed up user: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e, s) {
      if (e.code == 'weak-password') {
        log.w('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        log.w('The account already exists for that email.');
      } else {
        log.e('An unknown FirebaseAuthException occurred during sign up.', error: e, stackTrace: s);
      }
      return null;
    } catch (e, s) {
      log.e('An unexpected error occurred during sign up.', error: e, stackTrace: s);
      return null;
    }
  }

  /// Signs in a user with an email and password.
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      log.i('Successfully signed in user: ${credential.user?.uid}');
      return credential;
    } on FirebaseAuthException catch (e, s) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        log.w('Invalid credentials provided.');
      } else {
        log.e('An unknown FirebaseAuthException occurred during sign in.', error: e, stackTrace: s);
      }
      return null;
    } catch (e, s) {
      log.e('An unexpected error occurred during sign in.', error: e, stackTrace: s);
      return null;
    }
  }

  /// Signs in a user with their Google account and signs them into Firebase.
  Future<UserCredential?> signInWithGoogle() async {
    // FIX 2: Ensure initialization is called before use
    await _ensureGoogleSignInInitialized();

    try {
      // FIX 3: Use authenticate() instead of signIn()
      // Note: In v7, this throws an exception if cancelled or failed,
      // instead of returning null.
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // 2. Obtain the Google Authentication details (tokens)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // FIX 4: Remove accessToken.
      // v7 separates Authorization (accessToken) from Authentication (idToken).
      // For Firebase Auth, the idToken is sufficient to prove identity.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null, // explicitly null as it's not available or needed for basic auth
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the Google credential
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      log.i('Successfully signed in with Google: ${userCredential.user?.uid}');
      return userCredential;

    } on FirebaseAuthException catch (e, s) {
      log.e('FirebaseAuth error during Google sign in.', error: e, stackTrace: s);
      return null;
    } catch (e, s) {
      // Detect cancellation if it comes as a specific error (platform dependent),
      // otherwise just log it.
      log.e('An error occurred during Google sign in.', error: e, stackTrace: s);
      return null;
    }
  }

  /// Signs in with Apple and then into Firebase.
  ///
  /// Apple only returns given/family name on the first authorization. We write
  /// that name onto the Firebase user so Firestore profile creation can use it.
  Future<UserCredential> signInWithApple() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw FirebaseAuthException(
        code: 'operation-not-allowed',
        message: 'Sign in with Apple is only available on iOS.',
      );
    }

    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message: 'Apple did not return an identity token.',
        );
      }

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);

      final fullName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');

      final user = userCredential.user;
      if (user != null &&
          fullName.isNotEmpty &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(fullName);
        await user.reload();
      }

      final signedIn = _firebaseAuth.currentUser ?? user;
      log.i('Successfully signed in with Apple: ${signedIn?.uid}');
      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e, s) {
      if (e.code == AuthorizationErrorCode.canceled) {
        log.i('Apple sign in cancelled by user');
        throw const AuthCancelledException();
      }
      log.e('Apple authorization failed: ${e.code}', error: e, stackTrace: s);
      rethrow;
    } on AuthCancelledException {
      rethrow;
    } on FirebaseAuthException catch (e, s) {
      log.e('FirebaseAuth error during Apple sign in.', error: e, stackTrace: s);
      rethrow;
    } catch (e, s) {
      log.e('An error occurred during Apple sign in.', error: e, stackTrace: s);
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Requests a Briq OTP for [phoneNumber] via the `request_briq_otp` callable.
  ///
  /// Returns the `sessionId` that must be sent back to `verify_briq_otp`.
  Future<String> requestPhoneOtp({required String phoneNumber}) async {
    try {
      final callable = _functions.httpsCallable(
        'request_briq_otp',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call({'phoneNumber': phoneNumber});
      final data = _asMap(result.data);

      if (data['success'] == false) {
        throw _exceptionFromPayload(data, fallback: 'Failed to send verification code.');
      }

      final sessionId =
          data['sessionId']?.toString() ?? data['session_id']?.toString();
      if (sessionId == null || sessionId.isEmpty) {
        throw const PhoneAuthException(
          code: 'unknown',
          message: 'Failed to send verification code. Please try again.',
          recoveryHint: 'Check your connection and try again',
        );
      }

      log.i('Briq OTP sent for $phoneNumber');
      return sessionId;
    } on PhoneAuthException {
      rethrow;
    } on FirebaseFunctionsException catch (e, s) {
      log.e('request_briq_otp failed: ${e.code} - ${e.message}',
          error: e, stackTrace: s);
      throw _mapFunctionsError(e);
    } catch (e, s) {
      log.e('Unexpected error requesting Briq OTP', error: e, stackTrace: s);
      throw const PhoneAuthException(
        code: 'network',
        message: 'Failed to send verification code. Please try again.',
        recoveryHint: 'Check your connection and try again',
      );
    }
  }

  /// Verifies the Briq OTP via `verify_briq_otp`, then signs into Firebase
  /// with the returned custom token.
  Future<UserCredential> verifyPhoneOtp({
    required String sessionId,
    required String smsCode,
    String? phoneNumber,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'verify_briq_otp',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final payload = <String, dynamic>{
        'sessionId': sessionId,
        'otp': smsCode,
        'code': smsCode,
      };
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        payload['phoneNumber'] = phoneNumber;
      }

      final result = await callable.call(payload);
      final data = _asMap(result.data);

      if (data['success'] == false) {
        throw _exceptionFromPayload(
          data,
          fallback: 'The verification code is incorrect. Please try again.',
        );
      }

      final customToken =
          data['customToken']?.toString() ?? data['custom_token']?.toString();
      if (customToken == null || customToken.isEmpty) {
        throw const PhoneAuthException(
          code: 'unknown',
          message: 'Verification succeeded but sign-in failed. Please try again.',
        );
      }

      final userCredential =
          await _firebaseAuth.signInWithCustomToken(customToken);
      log.i(
          'Successfully signed in with Briq custom token: ${userCredential.user?.uid}');
      return userCredential;
    } on PhoneAuthException {
      rethrow;
    } on FirebaseFunctionsException catch (e, s) {
      log.e('verify_briq_otp failed: ${e.code} - ${e.message}',
          error: e, stackTrace: s);
      throw _mapFunctionsError(e);
    } on FirebaseAuthException catch (e, s) {
      log.e('signInWithCustomToken failed: ${e.code}', error: e, stackTrace: s);
      throw PhoneAuthException(
        code: e.code,
        message: e.message ?? 'Sign-in failed. Please try again.',
      );
    } catch (e, s) {
      log.e('Unexpected error verifying Briq OTP', error: e, stackTrace: s);
      throw const PhoneAuthException(
        code: 'unknown',
        message: 'Failed to verify the code. Please try again.',
        recoveryHint: 'Check the code and try again, or request a new one',
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data == null) return {};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }

  PhoneAuthException _exceptionFromPayload(
    Map<String, dynamic> data, {
    required String fallback,
  }) {
    final rawCode = (data['code'] ?? data['errorCode'] ?? 'unknown').toString();
    final cooldown = data['cooldownSeconds'] ?? data['retryAfter'];
    return PhoneAuthException(
      code: _normalizeErrorCode(rawCode, data['message']?.toString() ?? fallback),
      message: data['message']?.toString() ?? fallback,
      cooldownSeconds: cooldown is num ? cooldown.toInt() : null,
    );
  }

  PhoneAuthException _mapFunctionsError(FirebaseFunctionsException e) {
    final details = _asMap(e.details);
    final detailCode =
        (details['code'] ?? details['errorCode'] ?? '').toString();
    final cooldown = details['cooldownSeconds'] ?? details['retryAfter'];
    final cooldownSeconds = cooldown is num ? cooldown.toInt() : null;
    final message = e.message ?? 'Something went wrong. Please try again.';
    final code = _normalizeErrorCode(
      detailCode.isNotEmpty ? detailCode : e.code,
      message,
      httpsCode: e.code,
    );

    switch (code) {
      case 'invalid-phone-number':
        return PhoneAuthException(
          code: code,
          message: 'Please enter a valid phone number with country code.',
          recoveryHint: 'Use a Tanzania number starting with 6 or 7',
        );
      case 'invalid-otp':
        return PhoneAuthException(
          code: code,
          message: 'The verification code is incorrect. Please check and try again.',
          recoveryHint: 'Double-check the 6-digit code from your SMS',
        );
      case 'session-expired':
        return const PhoneAuthException(
          code: 'session-expired',
          message: 'Verification code has expired. Please request a new code.',
          recoveryHint: 'Tap "Resend" to get a new verification code',
        );
      case 'cooldown':
        return PhoneAuthException(
          code: code,
          message: cooldownSeconds != null
              ? 'Please wait $cooldownSeconds seconds before requesting another code.'
              : 'Too many attempts. Please wait a moment and try again.',
          recoveryHint: 'Wait before requesting a new code',
          cooldownSeconds: cooldownSeconds,
        );
      case 'quota-exceeded':
        return const PhoneAuthException(
          code: 'quota-exceeded',
          message: 'SMS quota exceeded. Please try again later.',
        );
      case 'network':
        return PhoneAuthException(
          code: 'network',
          message: 'Network error. Please check your internet connection.',
          recoveryHint: 'Check your connection and try again',
        );
      default:
        return PhoneAuthException(
          code: code,
          message: message,
          cooldownSeconds: cooldownSeconds,
        );
    }
  }

  String _normalizeErrorCode(
    String rawCode,
    String message, {
    String? httpsCode,
  }) {
    final combined =
        '${rawCode.toLowerCase()} ${httpsCode ?? ''} ${message.toLowerCase()}';

    if (combined.contains('invalid-phone') ||
        combined.contains('invalid_phone') ||
        (httpsCode == 'invalid-argument' && combined.contains('phone'))) {
      return 'invalid-phone-number';
    }
    if (combined.contains('invalid-otp') ||
        combined.contains('invalid_otp') ||
        combined.contains('wrong-otp') ||
        combined.contains('incorrect-otp') ||
        combined.contains('invalid-verification-code') ||
        (combined.contains('otp') &&
            (combined.contains('invalid') ||
                combined.contains('incorrect') ||
                combined.contains('wrong')))) {
      return 'invalid-otp';
    }
    if (combined.contains('expired') ||
        combined.contains('session-expired') ||
        combined.contains('invalid-session') ||
        httpsCode == 'not-found') {
      return 'session-expired';
    }
    if (combined.contains('cooldown') ||
        combined.contains('rate') ||
        combined.contains('too-many') ||
        combined.contains('too_many') ||
        httpsCode == 'resource-exhausted') {
      return 'cooldown';
    }
    if (combined.contains('quota')) {
      return 'quota-exceeded';
    }
    if (combined.contains('network') ||
        httpsCode == 'unavailable' ||
        httpsCode == 'deadline-exceeded') {
      return 'network';
    }
    return rawCode.isNotEmpty ? rawCode : 'unknown';
  }

  /// Sends a password reset email to the given email address.
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      log.i('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e, s) {
      log.e('FirebaseAuth error while sending password reset email.', error: e, stackTrace: s);
    } catch (e, s) {
      log.e('An error occurred while sending password reset email.', error: e, stackTrace: s);
    }
  }

  /// Signs out the current user and disconnects Google Sign-In session.
  Future<void> signOut() async {
    try {
      await _ensureGoogleSignInInitialized();
      // Also sign out from Google to allow account switching next time.
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      log.i('User signed out successfully.');
    } catch (e, s) {
      log.e('An error occurred during sign out.', error: e, stackTrace: s);
    }
  }
}