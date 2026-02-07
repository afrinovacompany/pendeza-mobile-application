// profile_state.dart
import 'package:equatable/equatable.dart';
import '../../data/models/profile_stats.dart';


abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

/// The main state for the profile screen.
class ProfileLoaded extends ProfileState {
  final ProfileStats stats;
  // We don't store the User object here because AuthBloc is the source of truth for User.
  // We only store the "Extra" data that AuthBloc doesn't care about (stats).

  const ProfileLoaded({required this.stats});

  @override
  List<Object?> get props => [stats];
}

/// A specific loading state for image uploading (so we can show a progress spinner on the avatar)
class ProfileImageUploading extends ProfileState {
  final ProfileStats? previousStats; // Keep showing stats while uploading
  const ProfileImageUploading({this.previousStats});
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

class ProfileUpdateSuccess extends ProfileState {
  final String message;
  const ProfileUpdateSuccess(this.message);
}