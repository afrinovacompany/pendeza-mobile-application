// auth_state.dart
// IMPROVED VERSION - Better error handling with error codes and recovery hints
import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

/// The base class for all states related to authentication.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];

  /// Helper to check if this is a loading state
  bool get isLoading => this is AuthLoading;

  /// Helper to check if this is an error state
  bool get isError => this is AuthError;

  /// Helper to check if user is fully authenticated
  bool get isAuthenticated => this is Authenticated;

  /// Helper to check if user is in guest mode
  bool get isGuest => this is GuestMode;

  /// Helper to get the current user if available
  UserModel? get currentUser {
    if (this is Authenticated) return (this as Authenticated).user;
    if (this is GuestMode) return (this as GuestMode).guestUser;
    if (this is RoleSelectionRequired) return (this as RoleSelectionRequired).user;
    if (this is ClientProfileSetupRequired) return (this as ClientProfileSetupRequired).user;
    if (this is OwnerProfileSetupRequired) return (this as OwnerProfileSetupRequired).user;
    return null;
  }
}

// ============================================================================
// INITIAL & LOADING STATES
// ============================================================================

/// The initial state of the BLoC before any checks have been made.
class AuthInitial extends AuthState {}

/// State indicating that an authentication-related process is in progress.
///
/// UI should show loading indicators when this state is active.
class AuthLoading extends AuthState {
  /// Optional message describing what's being loaded
  final String? message;

  const AuthLoading([this.message]);

  @override
  List<Object?> get props => [message];
}

// ============================================================================
// UNAUTHENTICATED STATES
// ============================================================================

/// State indicating the user is not signed in (completely unauthenticated).
///
/// This state is rarely used in the current implementation as users
/// are typically placed in GuestMode instead.
class Unauthenticated extends AuthState {}

/// State indicating the user is browsing as a guest (no authentication required).
///
/// Guests can browse salons, view services, but cannot:
/// - Book appointments
/// - Save favorites (persisted)
/// - Leave reviews
/// - Access owner features
class GuestMode extends AuthState {
  final UserModel guestUser;

  const GuestMode(this.guestUser);

  @override
  List<Object> get props => [guestUser];
}

// ============================================================================
// AUTHENTICATION IN PROGRESS STATES
// ============================================================================

/// State emitted when phone verification code has been sent.
///
/// UI should navigate to OTP input screen when this state is received.
class PhoneVerificationCodeSent extends AuthState {
  final String verificationId;
  final String phoneNumber;

  /// Timestamp when the code was sent (for countdown timer)
  final DateTime sentAt;

  PhoneVerificationCodeSent({
    required this.verificationId,
    required this.phoneNumber,
    DateTime? sentAt,
  }) : sentAt = sentAt ?? DateTime.now();

  @override
  List<Object> get props => [verificationId, phoneNumber, sentAt];

  /// Check if the verification code is still valid (typically 2 minutes)
  bool get isExpired {
    final elapsed = DateTime.now().difference(sentAt);
    return elapsed.inMinutes >= 2;
  }

  /// Get remaining seconds for UI countdown
  int get remainingSeconds {
    final elapsed = DateTime.now().difference(sentAt);
    final remaining = 120 - elapsed.inSeconds; // 2 minutes = 120 seconds
    return remaining > 0 ? remaining : 0;
  }
}

// ============================================================================
// ONBOARDING STATES
// ============================================================================

/// State indicating the user is authenticated with Firebase but has not selected a role.
///
/// UI should show role selection screen (Client vs Owner).
class RoleSelectionRequired extends AuthState {
  final UserModel user;
  const RoleSelectionRequired(this.user);

  @override
  List<Object> get props => [user];
}

/// State indicating the user has selected the 'client' role but hasn't finished setup.
///
/// UI should show client profile setup screen to collect:
/// - Full name (if not from OAuth)
/// - Phone number
/// - Gender
/// - Profile picture (optional)
class ClientProfileSetupRequired extends AuthState {
  final UserModel user;
  const ClientProfileSetupRequired(this.user);

  @override
  List<Object> get props => [user];

  /// Check what fields are still missing
  List<String> get missingFields {
    final missing = <String>[];
    if (user.fullName.isEmpty || user.fullName == 'New User') {
      missing.add('name');
    }
    if (user.phoneNumber == null || user.phoneNumber!.isEmpty) {
      missing.add('phone');
    }
    if (user.gender == null) {
      missing.add('gender');
    }
    return missing;
  }
}

/// State indicating the user has selected the 'owner' role but hasn't finished setup.
///
/// UI should show salon setup screen to collect:
/// - Salon name
/// - Business type(s)
/// - Region/District
/// - Address
/// - Service categories
class OwnerProfileSetupRequired extends AuthState {
  final UserModel user;
  const OwnerProfileSetupRequired(this.user);

  @override
  List<Object> get props => [user];
}

// ============================================================================
// AUTHENTICATED STATES
// ============================================================================

/// State indicating the user is fully authenticated and all onboarding is complete.
///
/// This is the "happy path" state where users have full access to features
/// based on their role (client, owner, or admin).
class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);

  @override
  List<Object> get props => [user];

  /// Check if user is a client
  bool get isClient => user.role == 'client';

  /// Check if user is an owner
  bool get isOwner => user.role == 'owner';

  /// Check if user is an admin
  bool get isAdmin => user.isAdmin;
}

// ============================================================================
// AUTHENTICATION REQUIRED STATE
// ============================================================================

/// State indicating that authentication is required to proceed.
///
/// Used when a guest tries to access protected features like:
/// - Booking an appointment
/// - Saving a favorite
/// - Writing a review
class AuthenticationRequired extends AuthState {
  /// What triggered the auth requirement (for analytics and UX messaging)
  final String triggeredBy;

  /// Where to navigate after successful authentication
  final String? returnRoute;

  /// Optional data to pass to the return route
  final Map<String, dynamic>? returnData;

  /// The current guest user (so we can migrate their data after auth)
  final UserModel? guestUser;

  const AuthenticationRequired({
    required this.triggeredBy,
    this.returnRoute,
    this.returnData,
    this.guestUser,
  });

  @override
  List<Object?> get props => [triggeredBy, returnRoute, returnData, guestUser];

  /// Get user-friendly message based on trigger
  String get userMessage {
    switch (triggeredBy.toLowerCase()) {
      case 'booking':
      case 'book':
        return 'Sign in to book and manage your appointments';
      case 'favorite':
      case 'save':
        return 'Sign in to save your favorite salons';
      case 'review':
        return 'Sign in to share your experience';
      case 'profile':
        return 'Sign in to access your profile';
      case 'wallet':
        return 'Sign in to use your wallet';
      default:
        return 'Sign in to access this feature';
    }
  }
}

// ============================================================================
// ERROR STATE - IMPROVED
// ============================================================================

/// Error codes for categorizing auth errors
enum AuthErrorCode {
  // Network errors
  networkError,
  timeout,

  // Credential errors
  invalidEmail,
  invalidPassword,
  invalidCredentials,
  emailAlreadyInUse,
  weakPassword,

  // Account errors
  userNotFound,
  userDisabled,
  accountExistsWithDifferentCredential,

  // Phone auth errors
  invalidPhoneNumber,
  invalidVerificationCode,
  verificationCodeExpired,
  smsQuotaExceeded,

  // Rate limiting
  tooManyRequests,

  // Profile errors
  profileCreationFailed,
  profileFetchFailed,
  profileUpdateFailed,

  // General errors
  operationNotAllowed,
  cancelled,
  unknown,
}

/// State indicating an error occurred during an authentication process.
///
/// IMPROVED: Now includes error code for programmatic handling and
/// recovery hints for better UX.
class AuthError extends AuthState {
  /// User-friendly error message to display
  final String message;

  /// Error code for programmatic handling
  final AuthErrorCode code;

  /// Whether the error is recoverable (user can retry)
  final bool isRecoverable;

  /// Suggested action for the user
  final String? recoveryHint;

  /// Original exception for logging (not exposed to UI)
  final Object? originalError;

  const AuthError(
      this.message, {
        this.code = AuthErrorCode.unknown,
        this.isRecoverable = true,
        this.recoveryHint,
        this.originalError,
      });

  @override
  List<Object?> get props => [message, code, isRecoverable, recoveryHint];

  /// Factory for network errors
  factory AuthError.network([String? customMessage]) {
    return AuthError(
      customMessage ?? 'Network error. Please check your internet connection.',
      code: AuthErrorCode.networkError,
      isRecoverable: true,
      recoveryHint: 'Check your connection and try again',
    );
  }

  /// Factory for invalid credentials
  factory AuthError.invalidCredentials() {
    return const AuthError(
      'Invalid email or password. Please check and try again.',
      code: AuthErrorCode.invalidCredentials,
      isRecoverable: true,
      recoveryHint: 'Double-check your email and password',
    );
  }

  /// Factory for email already in use
  factory AuthError.emailInUse() {
    return const AuthError(
      'This email is already registered. Try signing in instead.',
      code: AuthErrorCode.emailAlreadyInUse,
      isRecoverable: true,
      recoveryHint: 'Sign in with this email or use a different one',
    );
  }

  /// Factory for too many requests
  factory AuthError.tooManyRequests() {
    return const AuthError(
      'Too many failed attempts. Please wait a few minutes.',
      code: AuthErrorCode.tooManyRequests,
      isRecoverable: true,
      recoveryHint: 'Wait 5 minutes before trying again',
    );
  }

  /// Factory for verification code expired
  factory AuthError.verificationExpired() {
    return const AuthError(
      'Verification code has expired. Please request a new code.',
      code: AuthErrorCode.verificationCodeExpired,
      isRecoverable: true,
      recoveryHint: 'Tap "Resend Code" to get a new verification code',
    );
  }

  /// Factory for profile creation failure
  factory AuthError.profileCreationFailed() {
    return const AuthError(
      'Failed to set up your profile. Please try again.',
      code: AuthErrorCode.profileCreationFailed,
      isRecoverable: true,
      recoveryHint: 'Check your connection and try signing in again',
    );
  }
}