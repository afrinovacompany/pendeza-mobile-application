import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../../../app/services/auth_service.dart';
import '../../../../app/services/firestore_service.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';


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
    );
  }

  @override
  Future<void> updateUserName({required String uid, required String newName}) {
    return _firestoreService.updateUserName(uid: uid, newName: newName);
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
      await createUserProfile(userCredential!.user!);
    }
  }

  @override
  Future<void> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    // Only responsible for signing in. BLoC handles the rest.
    await _authService.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    // Only responsible for signing in. BLoC handles the rest.
    await _authService.signInWithGoogle();
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
      verificationCompleted: (credential) {},
      codeAutoRetrievalTimeout: (id) {},
    );
  }

  @override
  Future<void> verifyOtp(
      {required String verificationId, required String smsCode}) async {
    // Only responsible for verifying. BLoC handles the rest.
    await _authService.verifyOtp(
      verificationId: verificationId,
      smsCode: smsCode,
    );
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
  }) {
    return _firestoreService.createSalon(
      ownerId: ownerId,
      salonName: salonName,
      address: address,
      serviceCategories: serviceCategories,
    );
  }

  @override
  Future<SalonModel?> getSalonForOwner({required String ownerId}) {
    return _firestoreService.getSalonForOwner(ownerId: ownerId);
  }
}



