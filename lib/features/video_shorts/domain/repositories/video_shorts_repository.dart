import 'package:pendeza/shared/models/salon_video_model.dart';

/// Repository interface for fetching video shorts (client side)
abstract class VideoShortsRepository {
  /// Get all approved videos for client feed
  /// Ordered by most recent first
  /// Only returns videos that are approved and not expired
  Future<List<SalonVideoModel>> getApprovedVideos({int limit = 20});

  /// Get approved videos for a specific salon
  Future<List<SalonVideoModel>> getSalonApprovedVideos(String salonId);

  /// Stream of approved videos (for real-time updates)
  Stream<List<SalonVideoModel>> watchApprovedVideos({int limit = 20});
}
