import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';

abstract class VideoShortsState extends Equatable {
  const VideoShortsState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class VideoShortsInitial extends VideoShortsState {
  const VideoShortsInitial();
}

/// Loading videos
class VideoShortsLoading extends VideoShortsState {
  const VideoShortsLoading();
}

/// Videos loaded successfully
class VideoShortsLoaded extends VideoShortsState {
  final List<SalonVideoModel> videos;

  const VideoShortsLoaded(this.videos);

  @override
  List<Object?> get props => [videos];

  /// Check if there are any videos to show
  bool get hasVideos => videos.isNotEmpty;

  /// Get unique salons from videos (for story circles)
  List<SalonStory> get salonStories {
    final Map<String, SalonStory> salonMap = {};
    
    for (final video in videos) {
      if (!salonMap.containsKey(video.salonId)) {
        salonMap[video.salonId] = SalonStory(
          salonId: video.salonId,
          salonName: video.salonName,
          salonImage: video.salonImage,
          videos: [video],
        );
      } else {
        salonMap[video.salonId]!.videos.add(video);
      }
    }
    
    return salonMap.values.toList();
  }
}

/// Error loading videos
class VideoShortsError extends VideoShortsState {
  final String message;

  const VideoShortsError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Helper class to group videos by salon (for story circles)
class SalonStory {
  final String salonId;
  final String salonName;
  final String? salonImage;
  final List<SalonVideoModel> videos;

  SalonStory({
    required this.salonId,
    required this.salonName,
    this.salonImage,
    required this.videos,
  });

  /// Get the latest video (for thumbnail)
  SalonVideoModel get latestVideo => videos.first;

  /// Get thumbnail URL for story circle
  String get thumbnailUrl => latestVideo.thumbnailUrl;
}
