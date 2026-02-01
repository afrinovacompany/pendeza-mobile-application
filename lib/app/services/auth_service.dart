import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart'; // Assumed to exist for logging
import 'package:google_sign_in/google_sign_in.dart';

/// A service class to handle all Firebase Authentication operations.
class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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

  /// Initiates phone number verification and sends an OTP.
  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String, int?) codeSent,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 120), // Give more time

      // 🔥 CRITICAL: This prevents the web redirect issue
      verificationCompleted: (credential) async {
        log.i("Phone verification auto-completed");
        verificationCompleted(credential);
      },

      verificationFailed: (e) {
        log.e("Phone verification failed: ${e.code} - ${e.message}");
        verificationFailed(e);
      },

      codeSent: (String verificationId, int? resendToken) {
        log.i("SMS code sent successfully");
        codeSent(verificationId, resendToken);
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        log.i("Auto retrieval timeout");
        codeAutoRetrievalTimeout(verificationId);
      },
    );
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