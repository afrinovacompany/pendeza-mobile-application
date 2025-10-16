import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../data/models/user_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';


/// An abstract interface for authentication and user profile operations.
abstract class AuthRepository {
  /// A stream that emits the current FirebaseAuth User whenever the auth state changes.
  Stream<firebase.User?> get authStateChanges;

  /// Gets the current FirebaseAuth User object, if one exists.
  firebase.User? get currentUser;

  /// Fetches the detailed user profile from Firestore using the user's UID.
  Future<UserModel?> getUserProfile(String uid);

  /// Creates a user profile document in Firestore from a Firebase user object.
  Future<void> createUserProfile(firebase.User user);

  /// Updates the full name for a given user UID.
  Future<void> updateUserName({required String uid, required String newName});

  /// --- FIX IS HERE ---
  /// Updates the user's FCM token list in their document.
  Future<void> updateUserFcmToken({required String uid});

  /// Signs up a new user with email and password.
  Future<void> signUpWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
  });

  /// Signs in a user with their email and password.
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Signs in a user with their Google account.
  Future<void> signInWithGoogle();

  /// Initiates phone number verification and sends an OTP.
  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String, int?) codeSent,
    required void Function(firebase.FirebaseAuthException) verificationFailed,
  });

  /// Verifies the OTP code and signs the user in.
  Future<void> verifyOtp({
    required String verificationId,
    required String smsCode,
  });

  /// Updates the user's role in their Firestore document.
  Future<void> updateUserRole({required String uid, required String role});

  /// Signs out the current user from all providers.
  Future<void> signOut();

  /// Sends a password reset email to the given address.
  Future<void> sendPasswordResetEmail({required String email});

  // --- NEW SALON METHODS ---

  /// Creates a new salon document for a salon owner.
  Future<SalonModel> createSalon({
    required String ownerId,
    required String salonName,
    required String address,
    required List<String> serviceCategories,
  });

  /// Fetches the salon profile associated with a given owner's UID.
  Future<SalonModel?> getSalonForOwner({required String ownerId});
}

