import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase show User;


/// The base class for all events related to authentication.
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// --- NEW EVENT FOR DEFERRED INITIALIZATION ---
/// Fired immediately upon BLoC instantiation to begin listening to the stream.
/// This defers the initial Firebase check until the app starts and is ready to show a loading screen.
class AppStarted extends AuthEvent {}
/// -------------------------------------------


/// Fired by the stream listener when the Firebase auth state changes.
class AuthStateChanged extends AuthEvent {
  final firebase.User? user;
  const AuthStateChanged(this.user);

  @override
  List<Object?> get props => [user];
}

/// Fired when the user requests to sign out.
class SignOutRequested extends AuthEvent {}

/// Fired when the user selects a role during onboarding.
class UpdateUserRoleRequested extends AuthEvent {
  final String role;
  const UpdateUserRoleRequested(this.role);

  @override
  List<Object> get props => [role];
}

/// --- NEW EVENTS FOR PROFILE SETUP ---

/// Fired from the client setup screen to save the user's name.
class CompleteClientProfile extends AuthEvent {
  final String uid;
  final String fullName;

  const CompleteClientProfile({required this.uid, required this.fullName});

  @override
  List<Object> get props => [uid, fullName];
}

/// Fired from the owner setup screen to create the salon document.
class CompleteOwnerProfile extends AuthEvent {
  final String ownerId;
  final String salonName;
  final String address;
  final List<String> serviceCategories;

  const CompleteOwnerProfile({
    required this.ownerId,
    required this.salonName,
    required this.address,
    required this.serviceCategories,
  });

  @override
  List<Object> get props => [ownerId, salonName, address, serviceCategories];
}
