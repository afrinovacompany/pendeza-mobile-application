import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../../../app/services/auth_service.dart';
import '../../../../app/services/firestore_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import '../../../../app/utils/logger.dart';

/// ============================================================================
/// AUTH REPOSITORY IMPLEMENTATION - FIXED VERSION
/// ============================================================================
///
/// 🔥 KEY FIX: Google Sign-In no longer overwrites custom profile pictures!
///
/// PROBLEM BEFORE:
/// - User uploads custom profile picture
/// - User logs out and signs in again with Google
/// - Code saw Google photo URL != custom photo URL
/// - Code OVERWROTE custom photo with Google photo
/// - User's custom profile picture was lost!
///
/// FIX APPLIED:
/// - Only use Google photo if user has NO existing profile picture
/// - If user already has a custom photo, preserve it
/// - Added helper method `_isCustomProfilePicture()` to detect custom uploads
/// ============================================================================

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;
  final FirestoreService _firestoreService;

  AuthRepositoryImpl({
    required AuthService authService,
    required FirestoreService firestoreService,
  })  : _authService = authService,
        _firestoreService = firestoreService;

  @override
  Stream<firebase.User?> get authStateChanges => _authService.authStateChanges;

  @override
  firebase.User? get currentUser => _authService.currentUser;

  @override
  Future<UserModel?> getUserProfile(String uid) {
    return _firestoreService.getUserProfile(uid: uid);
  }

  @override
  Future<void> createUserProfile(firebase.User user) {
    return _firestoreService.createUser(
      uid: user.uid,
      email: user.email ?? '',
      fullName: user.displayName ?? 'New User',
      phoneNumber: user.phoneNumber,
      profilePictureUrl: user.photoURL,
    );
  }

  @override
  Future<void> updateUserProfile({
    required String uid,
    String? newName,
    String? profilePictureUrl,
    String? phoneNumber,
    Gender? gender,
  }) {
    return _firestoreService.updateUserProfile(
      uid: uid,
      newName: newName,
      profilePictureUrl: profilePictureUrl,
      phoneNumber: phoneNumber,
      gender: gender,
    );
  }

  @override
  Future<void> completeClientProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required Gender gender,
    String? profilePictureUrl,
  }) {
    return _firestoreService.completeClientProfile(
      uid: uid,
      fullName: fullName,
      phoneNumber: phoneNumber,
      gender: gender,
      profilePictureUrl: profilePictureUrl,
    );
  }

  @override
  Future<void> signUpWithEmailAndPassword({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final userCredential = await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (userCredential?.user != null) {
      await _firestoreService.createUser(
        uid: userCredential!.user!.uid,
        email: userCredential.user!.email ?? '',
        fullName: fullName,
      );
    }
  }

  @override
  Future<void> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ==========================================================================
  // 🔥 FIXED: Google Sign-In now preserves custom profile pictures!
  // ==========================================================================
  @override
  Future<void> signInWithGoogle() async {
    final credential = await _authService.signInWithGoogle();
    if (credential?.user != null) {
      final user = credential!.user!;
      final existingProfile = await getUserProfile(user.uid);

      if (existingProfile == null) {
        // New user - create profile with Google data
        log.i("Creating new profile for Google user: ${user.uid}");
        await createUserProfile(user);
      } else {
        // Existing user - be careful not to overwrite custom data!
        bool needsUpdate = false;
        String? newName;
        String? newPhotoUrl;

        // ================================================================
        // NAME UPDATE LOGIC (unchanged)
        // Only update name if user still has default name
        // ================================================================
        if (user.displayName != null &&
            user.displayName!.isNotEmpty &&
            (existingProfile.fullName.isEmpty ||
                existingProfile.fullName == 'New User')) {
          newName = user.displayName;
          needsUpdate = true;
          log.i("Will update name from Google: $newName");
        }

        // ================================================================
        // 🔥 FIXED: PROFILE PICTURE UPDATE LOGIC
        //
        // OLD (BROKEN) LOGIC:
        //   if (googlePhoto != existingPhoto) → overwrite with Google photo
        //   This ALWAYS overwrote custom photos!
        //
        // NEW (FIXED) LOGIC:
        //   Only use Google photo if user has NO profile picture at all
        //   If user has ANY profile picture (custom or Google), keep it
        // ================================================================

        final existingPhotoUrl = existingProfile.profilePictureUrl;
        final googlePhotoUrl = user.photoURL;

        // Only set Google photo if user has NO existing profile picture
        if (_shouldUseGooglePhoto(existingPhotoUrl, googlePhotoUrl)) {
          newPhotoUrl = googlePhotoUrl;
          needsUpdate = true;
          log.i("Will set Google photo (user had no profile picture)");
        } else {
          log.i("Preserving existing profile picture: $existingPhotoUrl");
        }

        // Apply updates if needed
        if (needsUpdate) {
          log.i("Updating profile from Google Sign-In for user ${user.uid}");
          await updateUserProfile(
            uid: user.uid,
            newName: newName,
            profilePictureUrl: newPhotoUrl,
          );
        } else {
          log.i("No profile updates needed for Google user ${user.uid}");
        }
      }
    }
  }

  /// ========================================================================
  /// Helper: Determine if we should use Google's profile photo
  ///
  /// Returns TRUE only if:
  /// - User has NO existing profile picture, AND
  /// - Google provides a photo URL
  ///
  /// Returns FALSE if:
  /// - User already has a profile picture (custom OR Google)
  /// - Google doesn't provide a photo
  /// ========================================================================
  bool _shouldUseGooglePhoto(String? existingPhotoUrl, String? googlePhotoUrl) {
    // If Google doesn't provide a photo, nothing to use
    if (googlePhotoUrl == null || googlePhotoUrl.isEmpty) {
      return false;
    }

    // If user has no existing photo, use Google's
    if (existingPhotoUrl == null || existingPhotoUrl.isEmpty) {
      return true;
    }

    // User already has a photo - DON'T overwrite it!
    // This preserves custom uploaded photos
    return false;
  }

  /// ========================================================================
  /// Helper: Check if a URL is a custom uploaded profile picture
  /// (Not currently used, but useful for more sophisticated logic)
  /// ========================================================================
  bool _isCustomProfilePicture(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return false;
    }

    // Custom photos are stored in Firebase Storage under these paths:
    // - profile_pictures/{userId}/...
    // - users/{userId}/... (old path, might still exist)
    return photoUrl.contains('profile_pictures') ||
        photoUrl.contains('firebasestorage.googleapis.com');
  }

  /// ========================================================================
  /// Helper: Check if a URL is from Google's servers
  /// (Not currently used, but useful for debugging)
  /// ========================================================================
  bool _isGoogleProfilePicture(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return false;
    }

    // Google profile photos come from these domains
    return photoUrl.contains('googleusercontent.com') ||
        photoUrl.contains('google.com/');
  }

  @override
  Future<void> signInWithPhone({
    required String phoneNumber,
    required void Function(String, int?) codeSent,
    required void Function(firebase.FirebaseAuthException) verificationFailed,
  }) async {
    await _authService.signInWithPhone(
      phoneNumber: phoneNumber,
      codeSent: codeSent,
      verificationFailed: verificationFailed,
      verificationCompleted: (phoneAuthCredential) async {
        log.i("Phone verification auto-completed.");
        final userCredential = await firebase.FirebaseAuth.instance
            .signInWithCredential(phoneAuthCredential);
        final user = userCredential.user;
        if (user != null) {
          final existingProfile = await getUserProfile(user.uid);
          if (existingProfile == null) {
            log.i("Creating profile for auto-verified phone user: ${user.uid}");
            await createUserProfile(user);
          }
        }
      },
      codeAutoRetrievalTimeout: (id) {},
    );
  }

  @override
  Future<void> verifyOtp(
      {required String verificationId, required String smsCode}) async {
    final userCredential = await _authService.verifyOtp(
        verificationId: verificationId, smsCode: smsCode);
    if (userCredential?.user != null) {
      final user = userCredential!.user!;
      final existingProfile = await getUserProfile(user.uid);
      if (existingProfile == null) {
        log.i("Creating profile for manually verified phone user: ${user.uid}");
        await createUserProfile(user);
      }
    }
  }

  @override
  Future<void> updateUserFcmToken({required String uid}) {
    return _firestoreService.updateUserFcmToken(uid: uid);
  }

  @override
  Future<void> updateUserRole({required String uid, required String role}) {
    return _firestoreService.updateUserRole(uid: uid, role: role);
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _authService.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  Future<SalonModel> createSalon({
    required String ownerId,
    required String salonName,
    required String address,
    required List<String> serviceCategories,
    List<String>? businessTypeIds,
    List<String>? businessTypeNames,
    String? region,
    String? district,
  }) {
    return _firestoreService.createSalon(
      ownerId: ownerId,
      salonName: salonName,
      address: address,
      serviceCategories: serviceCategories,
      businessTypeIds: businessTypeIds,
      businessTypeNames: businessTypeNames,
      region: region,
      district: district,
    );
  }

  @override
  Future<SalonModel?> getSalonForOwner({required String ownerId}) {
    return _firestoreService.getSalonForOwner(ownerId: ownerId);
  }
}