import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';
import '../domain/video_shorts_repository.dart';

class VideoShortsRepositoryImpl implements VideoShortsRepository {
  final FirebaseFirestore _firestore;

  VideoShortsRepositoryImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  @override
  Future<List<SalonVideoModel>> getApprovedVideos({int limit = 20}) async {
    try {
      final now = DateTime.now();
      log.i('🚀 [VideoShortsRepo] Fetching videos. Sorting by: createdAt DESC');

      // We switch the order field from 'approvedAt' to 'createdAt'
      // This ensures videos appear even if 'approvedAt' is null.
      final querySnapshot = await _firestore
          .collection('salon_videos')
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      log.d('📊 [VideoShortsRepo] Firestore returned ${querySnapshot.docs.length} documents');

      final videos = querySnapshot.docs.map((doc) {
        try {
          return SalonVideoModel.fromFirestore(doc);
        } catch (e) {
          log.e('❌ [VideoShortsRepo] Parsing Error on doc ${doc.id}: $e');
          return null;
        }
      }).whereType<SalonVideoModel>().toList();

      // Filter out expired videos client-side
      final activeVideos = videos.where((video) {
        if (video.expiresAt == null) return true;
        return video.expiresAt!.isAfter(now);
      }).toList();

      log.i('✅ [VideoShortsRepo] Successfully returning ${activeVideos.length} active videos');
      return activeVideos;
    } catch (e, stack) {
      log.e('🔥 [VideoShortsRepo] Critical fetch failure', error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Future<List<SalonVideoModel>> getSalonApprovedVideos(String salonId) async {
    try {
      final now = DateTime.now();
      final querySnapshot = await _firestore
          .collection('salon_videos')
          .where('salonId', isEqualTo: salonId)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SalonVideoModel.fromFirestore(doc))
          .where((video) {
        if (video.expiresAt == null) return true;
        return video.expiresAt!.isAfter(now);
      })
          .toList();
    } catch (e) {
      log.e('❌ [VideoShortsRepo] Error fetching salon videos', error: e);
      return [];
    }
  }

  @override
  Future<SalonVideoModel?> getVideo(String videoId) async {
    try {
      final doc = await _firestore.collection('salon_videos').doc(videoId).get();
      if (!doc.exists) return null;
      return SalonVideoModel.fromFirestore(doc);
    } catch (e) {
      log.e('❌ [VideoShortsRepo] Error fetching single video', error: e);
      return null;
    }
  }
}