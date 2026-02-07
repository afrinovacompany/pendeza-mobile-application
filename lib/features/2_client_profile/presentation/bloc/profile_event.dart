// profile_event.dart
import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

/// Triggered when the profile screen is opened.
/// Fetches stats and ensures data is fresh.
class LoadProfile extends ProfileEvent {
  final String userId;
  final bool forceRefresh;

  const LoadProfile({required this.userId, this.forceRefresh = false});

  @override
  List<Object?> get props => [userId, forceRefresh];
}

/// Triggered when user selects a new photo from gallery/camera.
class UpdateProfileImage extends ProfileEvent {
  final String userId;
  final File imageFile;

  const UpdateProfileImage({required this.userId, required this.imageFile});

  @override
  List<Object?> get props => [userId, imageFile];
}

/// Triggered when user edits name, phone, gender, etc.
class UpdateProfileInfo extends ProfileEvent {
  final String userId;
  final Map<String, dynamic> data; // e.g. {'fullName': 'New Name'}

  const UpdateProfileInfo({required this.userId, required this.data});

  @override
  List<Object?> get props => [userId, data];
}