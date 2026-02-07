import 'package:pendeza/shared/models/salon_video_model.dart';

/// Repository interface for fetching video shorts (client-side)
abstract class VideoShortsRepository {
  /// Get all approved videos for the story widget
  /// Returns videos ordered by createdAt descending
  /// Only returns videos that are approved and not expired
  Future<List<SalonVideoModel>> getApprovedVideos({int limit = 20});

  /// Get approved videos for a specific salon
  Future<List<SalonVideoModel>> getSalonApprovedVideos(String salonId);

  /// Get a single video by ID
  Future<SalonVideoModel?> getVideo(String videoId);
}
