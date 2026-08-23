import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../data/models/user_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';

/// An abstract interface for authentication and user profile operations.
abstract class AuthRepository {
  Stream<firebase.User?> get authStateChanges;

  firebase.User? get currentUser;

  Future<UserModel?> getUserProfile(String uid);

  Future<void> createUserProfile(firebase.User user);

  Future<void> updateUserProfile({
    required String uid,
    String? newName,
    String? profilePictureUrl,
    String? phoneNumber,
    Gender? gender,
  });

  /// Complete client profile with all mandatory fields
  Future<void> completeClientProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required Gender gender,
    String? profilePictureUrl,
  });

  Future<void> updateUserFcmToken({required String uid});

  Future<void> signUpWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signInWithGoogle();

  Future<void> signInWithApple();

  /// Requests a Briq OTP and returns the sessionId for later verification.
  Future<String> requestPhoneOtp({required String phoneNumber});

  /// Verifies the Briq OTP, signs in with the custom token, and ensures a
  /// Firestore user document exists.
  Future<void> verifyOtp({
    required String sessionId,
    required String smsCode,
    String? phoneNumber,
  });

  Future<void> updateUserRole({required String uid, required String role});

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});

  // --- NEW SALON METHODS ---

  /// Creates a new salon document for a salon owner.
  /// UPDATED: Now supports Phase 2 fields (Business types, Region, District)
  Future<SalonModel> createSalon({
    required String ownerId,
    required String salonName,
    required String address,
    required List<String> serviceCategories,
    // NEW OPTIONAL FIELDS
    List<String>? businessTypeIds,
    List<String>? businessTypeNames,
    String? region,
    String? district,
  });

  Future<SalonModel?> getSalonForOwner({required String ownerId});
}