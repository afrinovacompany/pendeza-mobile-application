

import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';




/// The base class for all states related to authentication.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// The initial state of the BLoC before any checks have been made.
class AuthInitial extends AuthState {}

/// State indicating that an authentication-related process is in progress.
class AuthLoading extends AuthState {}

/// State indicating the user is not signed in.
class Unauthenticated extends AuthState {}

/// State indicating the user is authenticated with Firebase but has not selected a role.
class RoleSelectionRequired extends AuthState {
  final UserModel user;
  const RoleSelectionRequired(this.user);

  @override
  List<Object> get props => [user];
}

/// --- NEW STATES FOR PROFILE SETUP ---

/// State indicating the user has selected the 'client' role but hasn't finished setup.
class ClientProfileSetupRequired extends AuthState {
  final UserModel user;
  const ClientProfileSetupRequired(this.user);

  @override
  List<Object> get props => [user];
}

/// State indicating the user has selected the 'owner' role but hasn't finished setup.
class OwnerProfileSetupRequired extends AuthState {
  final UserModel user;
  const OwnerProfileSetupRequired(this.user);

  @override
  List<Object> get props => [user];
}

/// State indicating the user is fully authenticated and all onboarding is complete.
class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);

  @override
  List<Object> get props => [user];
}

/// State indicating an error occurred during an authentication process.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}
