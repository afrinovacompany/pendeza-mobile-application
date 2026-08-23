// auth_event.dart
// IMPROVED VERSION - Added ClearAuthError event for better error handling
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase show User;
import '../../data/models/user_model.dart'; // For Gender enum

/// The base class for all events related to authentication.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// ============================================================================
// APP LIFECYCLE EVENTS
// ============================================================================

/// Fired immediately upon BLoC instantiation to begin listening to the stream.
class AppStarted extends AuthEvent {}

/// Fired by the stream listener when the Firebase auth state changes.
class AuthStateChanged extends AuthEvent {
  final firebase.User? user;
  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// Fired to force reload the user profile from Firestore (e.g., after updates).
class ReloadUser extends AuthEvent {}

// ============================================================================
// GUEST MODE EVENTS
// ============================================================================

/// Fired when user chooses to continue as guest
class ContinueAsGuest extends AuthEvent {}

/// Fired when a guest user needs to authenticate to access a feature
class RequestAuthentication extends AuthEvent {
  final String triggeredBy; // "booking", "favorite", "review", etc.
  final String? returnRoute;
  final Map<String, dynamic>? returnData;

  const RequestAuthentication({
    required this.triggeredBy,
    this.returnRoute,
    this.returnData,
  });

  @override
  List<Object?> get props => [triggeredBy, returnRoute, returnData];
}

/// Fired when guest decides to create an account
/// This migrates guest data to the new authenticated user
class ConvertGuestToUser extends AuthEvent {
  final String fullName;
  final String email;
  final String password;

  const ConvertGuestToUser({
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [fullName, email, password];
}

// ============================================================================
// EMAIL/PASSWORD AUTH EVENTS
// ============================================================================

/// Fired when user attempts to sign up with email/password
class SignUpRequested extends AuthEvent {
  final String fullName;
  final String email;
  final String password;

  const SignUpRequested({
    required this.fullName,
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [fullName, email, password];
}

/// Fired when user attempts to sign in with email/password
class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

// ============================================================================
// SOCIAL AUTH EVENTS
// ============================================================================

/// Fired when user attempts Google sign-in
class GoogleSignInRequested extends AuthEvent {}

/// Fired when user attempts Apple sign-in (iOS only)
class AppleSignInRequested extends AuthEvent {}

// ============================================================================
// PHONE AUTH EVENTS
// ============================================================================

/// Fired when user attempts phone sign-in
class PhoneSignInRequested extends AuthEvent {
  final String phoneNumber;

  const PhoneSignInRequested(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

/// Fired when OTP verification is submitted
class OtpVerificationRequested extends AuthEvent {
  final String sessionId;
  final String smsCode;

  const OtpVerificationRequested({
    required this.sessionId,
    required this.smsCode,
  });

  @override
  List<Object> get props => [sessionId, smsCode];
}

/// Fired to request a new OTP (resend)
class ResendOtpRequested extends AuthEvent {
  final String phoneNumber;

  const ResendOtpRequested(this.phoneNumber);

  @override
  List<Object> get props => [phoneNumber];
}

// ============================================================================
// ONBOARDING EVENTS
// ============================================================================

/// Fired when the user selects a role during onboarding.
class UpdateUserRoleRequested extends AuthEvent {
  final String role;
  const UpdateUserRoleRequested(this.role);

  @override
  List<Object> get props => [role];
}

/// Fired from the client setup screen to save the user's profile with mandatory fields.
class CompleteClientProfile extends AuthEvent {
  final String uid;
  final String fullName;
  final String phoneNumber;
  final Gender gender;
  final String? profilePictureUrl;

  const CompleteClientProfile({
    required this.uid,
    required this.fullName,
    required this.phoneNumber,
    required this.gender,
    this.profilePictureUrl,
  });

  @override
  List<Object?> get props => [uid, fullName, phoneNumber, gender, profilePictureUrl];
}

/// Fired from the owner setup screen to create the salon document.
class CompleteOwnerProfile extends AuthEvent {
  final String ownerId;
  final String salonName;
  final String address;
  final List<String> serviceCategories;
  final List<String>? businessTypeIds;
  final List<String>? businessTypeNames;
  final String? region;
  final String? district;

  const CompleteOwnerProfile({
    required this.ownerId,
    required this.salonName,
    required this.address,
    required this.serviceCategories,
    this.businessTypeIds,
    this.businessTypeNames,
    this.region,
    this.district,
  });

  @override
  List<Object?> get props => [
    ownerId, salonName, address, serviceCategories,
    businessTypeIds, businessTypeNames, region, district
  ];
}

// ============================================================================
// SIGN OUT EVENT
// ============================================================================

/// Fired when the user requests to sign out.
class SignOutRequested extends AuthEvent {}

// ============================================================================
// ERROR HANDLING EVENTS - NEW
// ============================================================================

/// Fired to clear the current auth error and return to appropriate state.
///
/// This allows the UI to explicitly dismiss error states rather than
/// relying on auto-transitions with arbitrary delays.
///
/// Usage in UI:
/// ```dart
/// // In your error snackbar action or retry button:
/// context.read<AuthBloc>().add(ClearAuthError());
/// ```
class ClearAuthError extends AuthEvent {}

/// Fired to retry the last failed operation.
///
/// This event can be used to implement "Retry" buttons in error states.
/// The bloc will attempt to re-process based on the current context.
class RetryLastOperation extends AuthEvent {}