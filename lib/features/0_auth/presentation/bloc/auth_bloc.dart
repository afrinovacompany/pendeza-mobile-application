import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../app/services/service_locator.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../../../app/utils/logger.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<firebase.User?>? _userSubscription;

  // Prevent race conditions
  bool _isProcessing = false;
  String? _lastProcessedUid;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? sl<AuthRepository>(),
        super(AuthInitial()) {

    // 1. New Handler: Fired immediately on creation, but is async.
    on<AppStarted>(_onAppStarted);

    // 2. Event Handlers
    on<AuthStateChanged>(_onAuthStateChanged);
    on<SignOutRequested>(_onSignOutRequested);
    on<UpdateUserRoleRequested>(_onUpdateUserRoleRequested);
    on<CompleteClientProfile>(_onCompleteClientProfile);
    on<CompleteOwnerProfile>(_onCompleteOwnerProfile);

    // 3. Trigger initial state check immediately (non-blocking).
    add(AppStarted());
  }

  /// Handles the AppStarted event to set up the stream listener.
  /// This ensures that the heavy I/O from Firebase is executed asynchronously
  /// AFTER the BLoC is fully registered and the main thread is unblocked.
  Future<void> _onAppStarted(
      AppStarted event,
      Emitter<AuthState> emit,
      ) async {
    // Only set up the listener once.
    if (_userSubscription != null) return;

    _userSubscription = _authRepository.authStateChanges
        .distinct((prev, next) => prev?.uid == next?.uid)
        .listen((firebaseUser) {
      if (!_isProcessing) {
        // Now, the listener will fire the AuthStateChanged event.
        // This is where the heavy I/O (Firestore read) is triggered.
        add(AuthStateChanged(firebaseUser));
      }
    });
  }

  Future<void> _onAuthStateChanged(
      AuthStateChanged event,
      Emitter<AuthState> emit,
      ) async {
    final firebaseUser = event.user;

    // Prevent race conditions
    if (_isProcessing && _lastProcessedUid == firebaseUser?.uid) {
      return;
    }

    _isProcessing = true;
    _lastProcessedUid = firebaseUser?.uid;

    try {
      if (firebaseUser == null) {
        emit(Unauthenticated());
        return;
      }

      // Only show loading if coming from initial or unauthenticated state
      if (state is AuthInitial || state is Unauthenticated) {
        emit(AuthLoading());
      }

      // --- CRITICAL I/O BLOCK: This is now asynchronous, preventing jank. ---
      var userModel = await _authRepository.getUserProfile(firebaseUser.uid);
      // ----------------------------------------------------------------------


      if (userModel == null) {
        log.i('Creating new user profile for ${firebaseUser.uid}');
        await _authRepository.createUserProfile(firebaseUser);
        userModel = await _authRepository.getUserProfile(firebaseUser.uid);

        if (userModel == null) {
          emit(AuthError('Failed to create user profile'));
          return;
        }

        // New user always needs role selection
        emit(RoleSelectionRequired(userModel));
        return;
      }

      // Existing user - update FCM token in background (non-blocking)
      _authRepository.updateUserFcmToken(uid: firebaseUser.uid).catchError((e) {
        log.w('Failed to update FCM token: $e');
      });

      // Determine auth state based on profile completeness
      await _emitAuthStateForUser(userModel, emit);

    } catch (e, s) {
      log.e('Error in _onAuthStateChanged', error: e, stackTrace: s);
      emit(AuthError('Authentication error. Please try again.'));
    } finally {
      _isProcessing = false;
    }
  }

  /// Centralized logic to determine which state to emit based on user profile
  Future<void> _emitAuthStateForUser(
      UserModel userModel,
      Emitter<AuthState> emit,
      ) async {
    // No role selected yet
    if (userModel.role == null) {
      emit(RoleSelectionRequired(userModel));
      return;
    }

    // Client role - check if profile is complete
    if (userModel.role == 'client') {
      final isProfileComplete = userModel.fullName.isNotEmpty &&
          userModel.fullName != 'New User';

      if (isProfileComplete) {
        emit(Authenticated(userModel));
      } else {
        emit(ClientProfileSetupRequired(userModel));
      }
      return;
    }

    // Owner role - check if salon exists
    if (userModel.role == 'owner') {
      try {
        final salon = await _authRepository.getSalonForOwner(
          ownerId: userModel.uid,
        );

        if (salon != null) {
          emit(Authenticated(userModel));
        } else {
          emit(OwnerProfileSetupRequired(userModel));
        }
      } catch (e) {
        log.e('Error checking salon: $e');
        emit(OwnerProfileSetupRequired(userModel));
      }
      return;
    }

    // Unknown role - force re-selection
    emit(RoleSelectionRequired(userModel));
  }

  Future<void> _onUpdateUserRoleRequested(
      UpdateUserRoleRequested event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! RoleSelectionRequired) return;

    final currentUserModel = (state as RoleSelectionRequired).user;
    emit(AuthLoading());

    try {
      await _authRepository.updateUserRole(
        uid: currentUserModel.uid,
        role: event.role,
      );

      // Fetch updated user and emit appropriate state
      final updatedUser = await _authRepository.getUserProfile(currentUserModel.uid);
      if (updatedUser != null) {
        await _emitAuthStateForUser(updatedUser, emit);
      }
    } catch (e) {
      log.e('Error updating role: $e');
      emit(AuthError('Failed to update role. Please try again.'));
      emit(RoleSelectionRequired(currentUserModel)); // Restore previous state
    }
  }

  Future<void> _onCompleteClientProfile(
      CompleteClientProfile event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! ClientProfileSetupRequired) return;

    final currentUser = (state as ClientProfileSetupRequired).user;
    emit(AuthLoading());

    try {
      await _authRepository.updateUserName(
        uid: event.uid,
        newName: event.fullName,
      );

      // Fetch updated user and emit authenticated state
      final updatedUser = await _authRepository.getUserProfile(event.uid);
      if (updatedUser != null) {
        emit(Authenticated(updatedUser));
      }
    } catch (e) {
      log.e('Error completing client profile: $e');
      emit(AuthError('Failed to save profile. Please try again.'));
      emit(ClientProfileSetupRequired(currentUser)); // Restore previous state
    }
  }

  Future<void> _onCompleteOwnerProfile(
      CompleteOwnerProfile event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! OwnerProfileSetupRequired) return;

    final currentUser = (state as OwnerProfileSetupRequired).user;
    emit(AuthLoading());

    try {
      await _authRepository.createSalon(
        ownerId: event.ownerId,
        salonName: event.salonName,
        address: event.address,
        serviceCategories: event.serviceCategories,
      );

      // Emit authenticated state
      emit(Authenticated(currentUser));
    } catch (e) {
      log.e('Error completing owner profile: $e');
      emit(AuthError('Failed to create salon. Please try again.'));
      emit(OwnerProfileSetupRequired(currentUser)); // Restore previous state
    }
  }

  Future<void> _onSignOutRequested(
      SignOutRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      await _authRepository.signOut();
      _lastProcessedUid = null;
      // State will be updated by authStateChanges listener
    } catch (e) {
      log.e('Error signing out: $e');
      emit(AuthError('Failed to sign out'));
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}
