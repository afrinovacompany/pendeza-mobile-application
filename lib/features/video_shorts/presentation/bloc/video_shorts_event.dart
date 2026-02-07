import 'package:equatable/equatable.dart';

abstract class VideoShortsEvent extends Equatable {
  const VideoShortsEvent();

  @override
  List<Object?> get props => [];
}

/// Load all approved videos for the story widget
class LoadVideoShorts extends VideoShortsEvent {
  const LoadVideoShorts();
}

/// Refresh videos
class RefreshVideoShorts extends VideoShortsEvent {
  const RefreshVideoShorts();
}

/// Load videos for a specific salon
class LoadSalonVideoShorts extends VideoShortsEvent {
  final String salonId;

  const LoadSalonVideoShorts(this.salonId);

  @override
  List<Object?> get props => [salonId];
}
