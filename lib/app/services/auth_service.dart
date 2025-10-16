import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart'; // Assumed to exist for logging
import 'package:google_sign_in/google_sign_in.dart';

/// A service class to handle all Firebase Authentication operations.
///
/// This class abstracts the `FirebaseAuth` calls into a clean, reusable service
/// that can be injected and used throughout the application.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  // Initialize GoogleSignIn. For simplicity in a Firebase app, we don't need
  // to pass clientId or serverClientId here unless strictly necessary for web/server-side code.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
  User? get currentUser => _firebaseAuth.currentUser;

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
    try {
      // 1. Trigger the Google Sign-In flow.
      // This is the simplest method for Firebase integration.
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        log.i('Google sign in cancelled by user.');
        return null; // The user canceled the sign-in
      }

      // 2. Obtain the Google Authentication details (tokens)
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential for Firebase using the tokens
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
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
      log.e('An error occurred during Google sign in.', error: e, stackTrace: s);
      // For web, sometimes the sign-in is handled differently, or specific errors occur.
      // You might add platform-specific handling here if needed.
      return null;
    }
  }

  /// Initiates phone number verification and sends an OTP.
  ///
  /// This method uses callbacks to communicate the result back to the UI layer,
  /// which is responsible for handling navigation and showing messages.
  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      );
      log.i('OTP code sent to $phoneNumber');
    } catch (e, s) {
      log.e('Error during phone number verification.', error: e, stackTrace: s);
    }
  }

  /// Verifies the OTP code sent to the user's phone and signs them in.
  Future<UserCredential?> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      log.i('Successfully verified OTP and signed in: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e, s) {
      log.e('An error occurred during OTP verification (FirebaseAuth).', error: e, stackTrace: s);
      return null;
    } catch (e, s) {
      log.e('An error occurred during OTP verification (General).', error: e, stackTrace: s);
      return null;
    }
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
      // Also sign out from Google to allow account switching next time.
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      log.i('User signed out successfully.');
    } catch (e, s) {
      log.e('An error occurred during sign out.', error: e, stackTrace: s);
    }
  }
}
