// auth_bloc.dart
// IMPROVED VERSION - Fixes race conditions, error handling, and state management
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import '../../../../app/services/service_locator.dart';
import '../../../../app/utils/logger.dart';
import '../../data/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription<firebase.User?>? _userSubscription;

  // ============================================================================
  // STATE TRACKING - Improved synchronization
  // ============================================================================

  /// Mutex-like flag to prevent concurrent auth state processing
  bool _isProcessing = false;

  /// Track the last successfully processed UID to prevent duplicate processing
  String? _lastProcessedUid;

  /// Store guest user data for migration when they sign up
  UserModel? _currentGuestUser;

  /// Track the previous state for proper error recovery
  AuthState? _previousNonErrorState;

  // ============================================================================
  // PHONE AUTH STATE
  // ============================================================================

  String? _phoneVerificationId;
  int? _phoneResendToken;
  DateTime? _phoneVerificationTimestamp;

  /// Phone verification codes typically expire after 2 minutes
  static const Duration _phoneVerificationTimeout = Duration(minutes: 2);

  // ============================================================================
  // RETRY CONFIGURATION
  // ============================================================================

  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);
  static const double _retryBackoffMultiplier = 2.0;

  AuthBloc({AuthRepository? authRepository})
      : _authRepository = authRepository ?? sl<AuthRepository>(),
        super(AuthInitial()) {
    // Register all event handlers
    on<AppStarted>(_onAppStarted);
    on<ContinueAsGuest>(_onContinueAsGuest);
    on<RequestAuthentication>(_onRequestAuthentication);
    on<ConvertGuestToUser>(_onConvertGuestToUser);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<SignOutRequested>(_onSignOutRequested);
    on<UpdateUserRoleRequested>(_onUpdateUserRoleRequested);
    on<CompleteClientProfile>(_onCompleteClientProfile);
    on<CompleteOwnerProfile>(_onCompleteOwnerProfile);
    on<SignUpRequested>(_onSignUpRequested);
    on<SignInRequested>(_onSignInRequested);
    on<GoogleSignInRequested>(_onGoogleSignInRequested);
    on<PhoneSignInRequested>(_onPhoneSignInRequested);
    on<OtpVerificationRequested>(_onOtpVerificationRequested);
    on<ReloadUser>(_onReloadUser);

    // NEW: Handler to clear error state
    on<ClearAuthError>(_onClearAuthError);

    add(AppStarted());
  }

  // ============================================================================
  // HELPER: Safe State Emission
  // ============================================================================

  /// Emits a state and tracks non-error states for recovery
  void _safeEmit(Emitter<AuthState> emit, AuthState newState) {
    if (newState is! AuthError && newState is! AuthLoading) {
      _previousNonErrorState = newState;
    }
    emit(newState);
  }

  /// Returns the appropriate fallback state based on context
  AuthState get _fallbackState {
    if (_currentGuestUser != null) {
      return GuestMode(_currentGuestUser!);
    }
    if (_previousNonErrorState != null && _previousNonErrorState is! AuthError) {
      return _previousNonErrorState!;
    }
    return Unauthenticated();
  }

  // ============================================================================
  // HELPER: Retry with Exponential Backoff
  // ============================================================================

  /// Fetches user profile with retry logic and exponential backoff
  Future<UserModel?> _fetchUserProfileWithRetry(String uid) async {
    Duration delay = _initialRetryDelay;

    for (int attempt = 1; attempt <= _maxRetries; attempt++) {
      try {
        log.d('Fetching user profile (attempt $attempt/$_maxRetries) for UID: $uid');

        final userModel = await _authRepository.getUserProfile(uid);

        if (userModel != null) {
          log.i('User profile fetched successfully on attempt $attempt');
          return userModel;
        }

        // Profile doesn't exist yet, wait before retry
        if (attempt < _maxRetries) {
          log.d('Profile not found, waiting ${delay.inMilliseconds}ms before retry');
          await Future.delayed(delay);
          delay = Duration(
            milliseconds: (delay.inMilliseconds * _retryBackoffMultiplier).toInt(),
          );
        }
      } catch (e, s) {
        log.e('Error fetching profile on attempt $attempt', error: e, stackTrace: s);

        if (attempt < _maxRetries) {
          await Future.delayed(delay);
          delay = Duration(
            milliseconds: (delay.inMilliseconds * _retryBackoffMultiplier).toInt(),
          );
        }
      }
    }

    log.w('Failed to fetch user profile after $_maxRetries attempts');
    return null;
  }

  // ============================================================================
  // HELPER: Error Message Mapping
  // ============================================================================

  /// Converts Firebase exceptions to user-friendly messages
  String _mapFirebaseError(dynamic error) {
    if (error is firebase.FirebaseAuthException) {
      switch (error.code) {
      // Sign Up Errors
        case 'email-already-in-use':
          return 'This email is already registered. Try signing in instead.';
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters with numbers and symbols.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'operation-not-allowed':
          return 'This sign-in method is not enabled. Please contact support.';

      // Sign In Errors
        case 'user-not-found':
          return 'No account found with this email. Would you like to sign up?';
        case 'wrong-password':
          return 'Incorrect password. Please try again or reset your password.';
        case 'user-disabled':
          return 'This account has been disabled. Please contact support.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please wait a few minutes and try again.';
        case 'invalid-credential':
          return 'Invalid email or password. Please check and try again.';

      // Phone Auth Errors
        case 'invalid-phone-number':
          return 'Please enter a valid phone number with country code.';
        case 'invalid-verification-code':
          return 'The verification code is incorrect. Please check and try again.';
        case 'session-expired':
          return 'Verification code has expired. Please request a new code.';
        case 'quota-exceeded':
          return 'SMS quota exceeded. Please try again later.';

      // Network Errors
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';

      // Google Sign In Errors
        case 'account-exists-with-different-credential':
          return 'An account already exists with this email using a different sign-in method.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
          return 'Sign-in was cancelled. Please try again.';

        default:
          log.w('Unhandled Firebase error code: ${error.code}');
          return error.message ?? 'Authentication failed. Please try again.';
      }
    }

    // Generic error
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (errorString.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  // ============================================================================
  // APP INITIALIZATION
  // ============================================================================

  Future<void> _onAppStarted(
      AppStarted event,
      Emitter<AuthState> emit,
      ) async {
    // Prevent duplicate subscription
    if (_userSubscription != null) {
      log.w('AppStarted called but subscription already exists');
      return;
    }

    log.i('App started - initializing auth state');

    // Set up auth state listener with debounce to prevent rapid-fire events
    _userSubscription = _authRepository.authStateChanges
        .distinct((prev, next) => prev?.uid == next?.uid)
        .asyncMap((user) async {
      // Small debounce to let rapid changes settle
      await Future.delayed(const Duration(milliseconds: 100));
      return user;
    })
        .listen(
          (firebaseUser) {
        // Only process if not already processing
        if (!_isProcessing) {
          add(AuthStateChanged(firebaseUser));
        } else {
          log.d('Skipping auth state change - already processing');
        }
      },
      onError: (error) {
        log.e('Auth state stream error', error: error);
      },
    );

    // Check current user immediately
    final currentUser = _authRepository.currentUser;

    if (currentUser != null) {
      log.i('Existing user found: ${currentUser.uid}');
      add(AuthStateChanged(currentUser));
    } else {
      log.i('No existing user - entering guest mode');
      _safeEmit(emit, AuthLoading());
      // Brief delay for splash screen visibility
      await Future.delayed(const Duration(milliseconds: 300));
      add(ContinueAsGuest());
    }
  }

  // ============================================================================
  // GUEST MODE HANDLERS
  // ============================================================================

  Future<void> _onContinueAsGuest(
      ContinueAsGuest event,
      Emitter<AuthState> emit,
      ) async {
    try {
      log.i('User continuing as guest');
      _currentGuestUser = UserModel.guest();
      _safeEmit(emit, GuestMode(_currentGuestUser!));
    } catch (e, s) {
      log.e('Error creating guest user', error: e, stackTrace: s);
      _safeEmit(emit, const AuthError('Failed to enter guest mode. Please restart the app.'));
    }
  }

  Future<void> _onRequestAuthentication(
      RequestAuthentication event,
      Emitter<AuthState> emit,
      ) async {
    log.i('Authentication required for: ${event.triggeredBy}');

    _safeEmit(emit, AuthenticationRequired(
      triggeredBy: event.triggeredBy,
      returnRoute: event.returnRoute,
      returnData: event.returnData,
      guestUser: _currentGuestUser,
    ));
  }

  Future<void> _onConvertGuestToUser(
      ConvertGuestToUser event,
      Emitter<AuthState> emit,
      ) async {
    final previousGuestUser = _currentGuestUser;
    _safeEmit(emit, AuthLoading());

    try {
      log.i('Converting guest to authenticated user');

      await _authRepository.signUpWithEmailAndPassword(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );

      // TODO: Implement guest data migration here
      // await sl<GuestDataMigrationService>().migrateGuestData(newUserId);

      _currentGuestUser = null;
      log.i('Guest conversion successful');
      // Auth state change listener will handle the rest

    } catch (e, s) {
      log.e('Error converting guest to user', error: e, stackTrace: s);

      // Restore guest user on failure
      _currentGuestUser = previousGuestUser;

      _safeEmit(emit, AuthError(_mapFirebaseError(e)));

      // Return to guest mode after brief delay for error visibility
      await Future.delayed(const Duration(seconds: 2));
      if (_currentGuestUser != null) {
        _safeEmit(emit, GuestMode(_currentGuestUser!));
      }
    }
  }

  // ============================================================================
  // EMAIL/PASSWORD AUTH HANDLERS
  // ============================================================================

  Future<void> _onSignUpRequested(
      SignUpRequested event,
      Emitter<AuthState> emit,
      ) async {
    _safeEmit(emit, AuthLoading());

    try {
      log.i('Sign up requested for: ${event.email}');

      await _authRepository.signUpWithEmailAndPassword(
        fullName: event.fullName,
        email: event.email,
        password: event.password,
      );

      // Clear guest user on successful signup
      _currentGuestUser = null;

      log.i('Sign up successful - waiting for auth state change');
      // Auth state change listener will handle navigation

    } catch (e, s) {
      log.e('Error during sign up', error: e, stackTrace: s);
      _safeEmit(emit, AuthError(_mapFirebaseError(e)));
      // Don't auto-transition - let user dismiss error or retry
    }
  }

  Future<void> _onSignInRequested(
      SignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    _safeEmit(emit, AuthLoading());

    try {
      log.i('Sign in requested for: ${event.email}');

      await _authRepository.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Clear guest user on successful sign in
      _currentGuestUser = null;

      log.i('Sign in successful');
      // Auth state change listener will handle navigation

    } catch (e, s) {
      log.e('Error during sign in', error: e, stackTrace: s);
      _safeEmit(emit, AuthError(_mapFirebaseError(e)));
      // Don't auto-transition - let user dismiss error or retry
    }
  }

  Future<void> _onGoogleSignInRequested(
      GoogleSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    _safeEmit(emit, AuthLoading());

    try {
      log.i('Google sign in requested');

      await _authRepository.signInWithGoogle();

      // Clear guest user on successful sign in
      _currentGuestUser = null;

      log.i('Google sign in successful');
      // Auth state change listener will handle navigation

    } catch (e, s) {
      log.e('Error during Google sign in', error: e, stackTrace: s);

      // Check if user cancelled
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('cancel') || errorString.contains('aborted')) {
        log.i('Google sign in cancelled by user');
        // Return to previous state without showing error
        _safeEmit(emit, _fallbackState);
        return;
      }

      _safeEmit(emit, AuthError(_mapFirebaseError(e)));
    }
  }

  // ============================================================================
  // PHONE AUTH HANDLERS - Improved with expiration tracking
  // ============================================================================

  Future<void> _onPhoneSignInRequested(
      PhoneSignInRequested event,
      Emitter<AuthState> emit,
      ) async {
    _safeEmit(emit, AuthLoading());

    try {
      log.i('Phone sign in requested for: ${event.phoneNumber}');

      await _authRepository.signInWithPhone(
        phoneNumber: event.phoneNumber,
        codeSent: (String verificationId, int? resendToken) {
          _phoneVerificationId = verificationId;
          _phoneResendToken = resendToken;
          _phoneVerificationTimestamp = DateTime.now();

          log.i('SMS code sent successfully');

          _safeEmit(emit, PhoneVerificationCodeSent(
            verificationId: verificationId,
            phoneNumber: event.phoneNumber,
          ));
        },
        verificationFailed: (firebase.FirebaseAuthException e) {
          log.e('Phone verification failed: ${e.code} - ${e.message}');
          _safeEmit(emit, AuthError(_mapFirebaseError(e)));
        },
      );
    } catch (e, s) {
      log.e('Error during phone sign in', error: e, stackTrace: s);
      _safeEmit(emit, AuthError(_mapFirebaseError(e)));
    }
  }

  Future<void> _onOtpVerificationRequested(
      OtpVerificationRequested event,
      Emitter<AuthState> emit,
      ) async {
    // Check if verification has expired
    if (_phoneVerificationTimestamp != null) {
      final elapsed = DateTime.now().difference(_phoneVerificationTimestamp!);
      if (elapsed > _phoneVerificationTimeout) {
        log.w('Phone verification code has expired');
        _safeEmit(emit, const AuthError(
          'Verification code has expired. Please request a new code.',
        ));
        return;
      }
    }

    _safeEmit(emit, AuthLoading());

    try {
      log.i('OTP verification requested');

      await _authRepository.verifyOtp(
        verificationId: event.verificationId,
        smsCode: event.smsCode,
      );

      // Clear phone auth state
      _phoneVerificationId = null;
      _phoneResendToken = null;
      _phoneVerificationTimestamp = null;
      _currentGuestUser = null;

      log.i('OTP verification successful');
      // Auth state change listener will handle navigation

    } catch (e, s) {
      log.e('Error during OTP verification', error: e, stackTrace: s);
      _safeEmit(emit, AuthError(_mapFirebaseError(e)));
      // Don't clear verification state - user might want to retry
    }
  }

  // ============================================================================
  // AUTH STATE CHANGE HANDLER - Core fix for race conditions
  // ============================================================================

  Future<void> _onAuthStateChanged(
      AuthStateChanged event,
      Emitter<AuthState> emit,
      ) async {
    final firebaseUser = event.user;

    // Handle sign out
    if (firebaseUser == null) {
      log.i('Auth state changed: User signed out');
      _lastProcessedUid = null;
      _isProcessing = false;

      if (_currentGuestUser != null) {
        _safeEmit(emit, GuestMode(_currentGuestUser!));
      } else {
        // Create new guest user for signed out state
        _currentGuestUser = UserModel.guest();
        _safeEmit(emit, GuestMode(_currentGuestUser!));
      }
      return;
    }

    // Prevent duplicate processing of same user
    if (firebaseUser.uid == _lastProcessedUid && state is! AuthLoading) {
      log.d('Skipping duplicate auth state change for UID: ${firebaseUser.uid}');
      return;
    }

    // Prevent concurrent processing
    if (_isProcessing) {
      log.d('Already processing auth state, queuing for later');
      // Queue this for later processing
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isProcessing) {
          add(AuthStateChanged(firebaseUser));
        }
      });
      return;
    }

    _isProcessing = true;
    log.i('Processing auth state change for UID: ${firebaseUser.uid}');

    _safeEmit(emit, AuthLoading());

    try {
      // Fetch user profile with retry logic
      UserModel? userModel = await _fetchUserProfileWithRetry(firebaseUser.uid);

      // If profile doesn't exist, create it
      if (userModel == null) {
        log.i('Creating new user profile for ${firebaseUser.uid}');

        await _authRepository.createUserProfile(firebaseUser);

        // Fetch the newly created profile with retry
        userModel = await _fetchUserProfileWithRetry(firebaseUser.uid);

        if (userModel == null) {
          log.e('Failed to create/fetch user profile after retries');
          _safeEmit(emit, const AuthError(
            'Failed to set up your profile. Please check your connection and try again.',
          ));
          _isProcessing = false;
          return;
        }
      }

      // Update last processed UID
      _lastProcessedUid = firebaseUser.uid;

      // Update FCM token in background (non-blocking)
      _authRepository.updateUserFcmToken(uid: firebaseUser.uid).catchError((e) {
        log.w('Failed to update FCM token: $e');
        return null; // Prevent unhandled exception
      });

      // Determine and emit appropriate state
      await _emitAuthStateForUser(userModel, emit);

    } catch (e, s) {
      log.e('Error in _onAuthStateChanged', error: e, stackTrace: s);
      _safeEmit(emit, AuthError(_mapFirebaseError(e)));

      // Don't auto-transition on error - let user retry
    } finally {
      _isProcessing = false;
    }
  }

  // ============================================================================
  // RELOAD USER HANDLER
  // ============================================================================

  Future<void> _onReloadUser(
      ReloadUser event,
      Emitter<AuthState> emit,
      ) async {
    final firebaseUser = _authRepository.currentUser;
    if (firebaseUser == null) {
      log.w('No current user to reload');
      _safeEmit(emit, _fallbackState);
      return;
    }

    _safeEmit(emit, AuthLoading());

    try {
      final userModel = await _fetchUserProfileWithRetry(firebaseUser.uid);

      if (userModel == null) {
        _safeEmit(emit, const AuthError('Failed to reload user profile. Please try again.'));
        return;
      }

      // Update FCM token in background
      _authRepository.updateUserFcmToken(uid: firebaseUser.uid).catchError((e) {
        log.w('Failed to update FCM token during reload: $e');
        return null;
      });

      await _emitAuthStateForUser(userModel, emit);

    } catch (e, s) {
      log.e('Error reloading user', error: e, stackTrace: s);
      _safeEmit(emit, AuthError(_mapFirebaseError(e)));
    }
  }

  // ============================================================================
  // CLEAR ERROR HANDLER
  // ============================================================================

  Future<void> _onClearAuthError(
      ClearAuthError event,
      Emitter<AuthState> emit,
      ) async {
    if (state is AuthError) {
      _safeEmit(emit, _fallbackState);
    }
  }

  // ============================================================================
  // USER STATE DETERMINATION
  // ============================================================================

  Future<void> _emitAuthStateForUser(
      UserModel userModel,
      Emitter<AuthState> emit,
      ) async {
    log.d('Determining state for user: ${userModel.uid}, role: ${userModel.role}');

    // Admin check - admins bypass all onboarding
    if (userModel.isAdmin) {
      log.i('User is admin - granting full access');
      _safeEmit(emit, Authenticated(userModel));
      return;
    }

    // No role selected yet
    if (userModel.role == null) {
      log.i('User needs to select a role');
      _safeEmit(emit, RoleSelectionRequired(userModel));
      return;
    }

    // Client role - check if profile is complete
    if (userModel.role == 'client') {
      if (!userModel.hasCompleteMandatoryFields) {
        log.i('Client needs to complete profile setup');
        _safeEmit(emit, ClientProfileSetupRequired(userModel));
        return;
      }

      log.i('Client is fully authenticated');
      _safeEmit(emit, Authenticated(userModel));
      return;
    }

    // Owner role - check if salon is created
    if (userModel.role == 'owner') {
      try {
        final salon = await _authRepository.getSalonForOwner(
          ownerId: userModel.uid,
        );

        if (salon != null) {
          log.i('Owner is fully authenticated with salon: ${salon.id}');
          _safeEmit(emit, Authenticated(userModel));
        } else {
          log.i('Owner needs to set up salon');
          _safeEmit(emit, OwnerProfileSetupRequired(userModel));
        }
      } catch (e) {
        log.e('Error checking salon: $e');
        // Assume setup needed if we can't verify
        _safeEmit(emit, OwnerProfileSetupRequired(userModel));
      }
      return;
    }

    // Unknown role - require selection
    log.w('Unknown role "${userModel.role}" - requiring role selection');
    _safeEmit(emit, RoleSelectionRequired(userModel));
  }

  // ============================================================================
  // ONBOARDING HANDLERS
  // ============================================================================

  Future<void> _onUpdateUserRoleRequested(
      UpdateUserRoleRequested event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! RoleSelectionRequired) {
      log.w('UpdateUserRoleRequested called in invalid state: $state');
      return;
    }

    final currentUserModel = (state as RoleSelectionRequired).user;
    _safeEmit(emit, AuthLoading());

    try {
      log.i('Updating user role to: ${event.role}');

      await _authRepository.updateUserRole(
        uid: currentUserModel.uid,
        role: event.role,
      );

      final updatedUser = await _fetchUserProfileWithRetry(currentUserModel.uid);

      if (updatedUser != null) {
        await _emitAuthStateForUser(updatedUser, emit);
      } else {
        _safeEmit(emit, const AuthError('Failed to update role. Please try again.'));
        _safeEmit(emit, RoleSelectionRequired(currentUserModel));
      }
    } catch (e, s) {
      log.e('Error updating role', error: e, stackTrace: s);
      _safeEmit(emit, AuthError(_mapFirebaseError(e)));

      // Return to role selection after delay
      await Future.delayed(const Duration(seconds: 2));
      _safeEmit(emit, RoleSelectionRequired(currentUserModel));
    }
  }

  Future<void> _onCompleteClientProfile(
      CompleteClientProfile event,
      Emitter<AuthState> emit,
      ) async {
    if (state is! ClientProfileSetupRequired) {
      log.w('CompleteClientProfile called in invalid state: $state');
      return;
    }

    final currentUser = (state as ClientProfileSetupRequired).user;
    _safeEmit(emit, AuthLoading());

    try {
      log.i('Completing client profile for: ${event.uid}');

      await _authRepository.completeClientProfile(
        uid: event.uid,
        fullName: event.fullName,
        phoneNumber: event.phoneNumber,
        gender: event.gender,
        profilePictureUrl: event.profilePictureUrl,
      );

      final updatedUser = await _fetchUserProfileWithRetry(event.uid);

      if (updatedUser != null) {
        log.i('Client profile completed successfully');
        _safeEmit(emit, Authenticated(updatedUser));
      } else {
        _safeEmit(emit, const AuthError('Profile saved but failed to reload. Please restart the app.'));
      }
    } catch (e, s) {
      log.e('Error completing client profile', error: e, stackTrace: s);
      _safeEmit(emit, AuthError(_mapFirebaseError(e)));

      // Return to setup screen after delay
      await Future.delayed(const Duration(seconds: 2));
      _safeEmit(emit, ClientProfileSetupRequired(currentUser));
    }
  }

  Future<void> _onCompleteOwnerProfile(
      CompleteOwnerProfile event,
      Emitter<AuthState> emit,
      ) async {
    UserModel? currentUser;
    if (state is OwnerProfileSetupRequired) {
      currentUser = (state as OwnerProfileSetupRequired).user;
    } else if (state is RoleSelectionRequired) {
      currentUser = (state as RoleSelectionRequired).user;
    } else if (state is Authenticated) {
      currentUser = (state as Authenticated).user;
    }

    if (currentUser == null) {
      log.w('CompleteOwnerProfile called with no current user');
      return;
    }

    _safeEmit(emit, AuthLoading());

    try {
      log.i('Creating salon for owner: ${event.ownerId}');

      await _authRepository.createSalon(
        ownerId: event.ownerId,
        salonName: event.salonName,
        address: event.address,
        serviceCategories: event.serviceCategories,
        businessTypeIds: event.businessTypeIds,
        businessTypeNames: event.businessTypeNames,
        region: event.region,
        district: event.district,
      );

      final updatedUser = await _fetchUserProfileWithRetry(currentUser.uid);

      log.i('Owner profile completed successfully');
      _safeEmit(emit, Authenticated(updatedUser ?? currentUser));

    } catch (e, s) {
      log.e('Error completing owner profile', error: e, stackTrace: s);
      _safeEmit(emit, AuthError(_mapFirebaseError(e)));

      // Return to setup screen after delay
      await Future.delayed(const Duration(seconds: 2));
      _safeEmit(emit, OwnerProfileSetupRequired(currentUser));
    }
  }

  // ============================================================================
  // SIGN OUT
  // ============================================================================

  Future<void> _onSignOutRequested(
      SignOutRequested event,
      Emitter<AuthState> emit,
      ) async {
    // Prevent sign out if already in appropriate state
    if (state is Unauthenticated || state is AuthLoading) {
      log.d('Sign out requested in invalid state: $state');
      return;
    }

    // If already in guest mode, no need to sign out
    if (state is GuestMode) {
      log.d('Already in guest mode, no sign out needed');
      return;
    }

    _safeEmit(emit, AuthLoading());

    try {
      log.i('Signing out user');

      await _authRepository.signOut();

      // Reset state
      _lastProcessedUid = null;
      _phoneVerificationId = null;
      _phoneResendToken = null;
      _phoneVerificationTimestamp = null;

      // Create fresh guest user
      _currentGuestUser = UserModel.guest();
      _safeEmit(emit, GuestMode(_currentGuestUser!));

      log.i('Sign out successful');

    } catch (e, s) {
      log.e('Error signing out', error: e, stackTrace: s);
      _safeEmit(emit, const AuthError('Failed to sign out. Please try again.'));

      // Try to determine current state
      final currentUser = _authRepository.currentUser;
      if (currentUser != null) {
        add(AuthStateChanged(currentUser));
      } else {
        _currentGuestUser = UserModel.guest();
        _safeEmit(emit, GuestMode(_currentGuestUser!));
      }
    }
  }

  // ============================================================================
  // PUBLIC HELPERS
  // ============================================================================

  /// Check if phone verification code is still valid
  bool get isPhoneVerificationValid {
    if (_phoneVerificationTimestamp == null) return false;
    final elapsed = DateTime.now().difference(_phoneVerificationTimestamp!);
    return elapsed < _phoneVerificationTimeout;
  }

  /// Get remaining time for phone verification (for UI countdown)
  Duration? get phoneVerificationRemainingTime {
    if (_phoneVerificationTimestamp == null) return null;
    final elapsed = DateTime.now().difference(_phoneVerificationTimestamp!);
    final remaining = _phoneVerificationTimeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  @override
  Future<void> close() {
    log.i('Closing AuthBloc');
    _userSubscription?.cancel();
    return super.close();
  }
}