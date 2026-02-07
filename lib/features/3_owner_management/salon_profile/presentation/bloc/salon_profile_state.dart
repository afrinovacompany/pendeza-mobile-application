import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';

abstract class SalonProfileState extends Equatable {
  const SalonProfileState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class SalonProfileInitial extends SalonProfileState {
  const SalonProfileInitial();
}

/// Loading salon profile (Full screen loader)
class SalonProfileLoading extends SalonProfileState {
  const SalonProfileLoading();
}

/// Salon profile loaded successfully
class SalonProfileLoaded extends SalonProfileState {
  final SalonModel salon;
  final List<SalonVideoModel> videos;  // 🆕 Added videos

  const SalonProfileLoaded(
    this.salon, {
    this.videos = const [],
  });

  @override
  List<Object?> get props => [salon, videos];

  /// Copy with helper for updating just videos
  SalonProfileLoaded copyWith({
    SalonModel? salon,
    List<SalonVideoModel>? videos,
  }) {
    return SalonProfileLoaded(
      salon ?? this.salon,
      videos: videos ?? this.videos,
    );
  }
}

/// Error loading salon profile
class SalonProfileError extends SalonProfileState {
  final String message;

  const SalonProfileError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Uploading image or updating data - KEEPS UI VISIBLE
class SalonProfileUploading extends SalonProfileState {
  final SalonModel salon;
  final List<SalonVideoModel> videos;  // 🆕 Preserve videos during upload
  final double progress;
  final String? uploadType; // 'primary', 'gallery', or 'video'

  const SalonProfileUploading(
    this.salon,
    this.progress, {
    this.videos = const [],
    this.uploadType,
  });

  @override
  List<Object?> get props => [salon, videos, progress, uploadType];
}

/// Success state for operations (Triggers Snackbars)
class SalonProfileOperationSuccess extends SalonProfileState {
  final SalonModel salon;
  final List<SalonVideoModel> videos;  // 🆕 Preserve videos
  final String message;

  const SalonProfileOperationSuccess(
    this.salon,
    this.message, {
    this.videos = const [],
  });

  @override
  List<Object?> get props => [salon, videos, message];
}

//============================================================================
// 🎬 NEW: VIDEO-SPECIFIC STATES
//============================================================================

/// Loading videos separately
class SalonVideosLoading extends SalonProfileState {
  final SalonModel salon;

  const SalonVideosLoading(this.salon);

  @override
  List<Object?> get props => [salon];
}

/// Video upload in progress
class SalonVideoUploading extends SalonProfileState {
  final SalonModel salon;
  final List<SalonVideoModel> videos;
  final double progress;
  final String stage; // 'compressing', 'uploading_video', 'uploading_thumbnail', 'saving'

  const SalonVideoUploading({
    required this.salon,
    required this.videos,
    required this.progress,
    required this.stage,
  });

  @override
  List<Object?> get props => [salon, videos, progress, stage];

  String get stageText {
    switch (stage) {
      case 'compressing':
        return 'Compressing video...';
      case 'uploading_video':
        return 'Uploading video...';
      case 'uploading_thumbnail':
        return 'Creating thumbnail...';
      case 'saving':
        return 'Saving...';
      default:
        return 'Processing...';
    }
  }
}

/// Video operation error (doesn't affect main profile)
class SalonVideoError extends SalonProfileState {
  final SalonModel salon;
  final List<SalonVideoModel> videos;
  final String message;

  const SalonVideoError({
    required this.salon,
    required this.videos,
    required this.message,
  });

  @override
  List<Object?> get props => [salon, videos, message];
}
