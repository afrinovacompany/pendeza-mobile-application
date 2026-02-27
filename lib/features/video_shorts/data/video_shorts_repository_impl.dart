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
      log.i('[VideoShortsRepo] Fetching videos. Sorting by: createdAt DESC');

      final querySnapshot = await _firestore
          .collection('salon_videos')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      log.d('[VideoShortsRepo] Firestore returned ${querySnapshot.docs.length} documents');

      final videos = querySnapshot.docs.map((doc) {
        try {
          return SalonVideoModel.fromFirestore(doc);
        } catch (e) {
          log.e('[VideoShortsRepo] Parsing Error on doc ${doc.id}: $e');
          return null;
        }
      }).whereType<SalonVideoModel>().toList();

      log.i('[VideoShortsRepo] Successfully returning ${videos.length} videos');
      return videos;
    } catch (e, stack) {
      log.e('[VideoShortsRepo] Critical fetch failure', error: e, stackTrace: stack);
      return [];
    }
  }

  @override
  Future<List<SalonVideoModel>> getSalonApprovedVideos(String salonId) async {
    try {
      final querySnapshot = await _firestore
          .collection('salon_videos')
          .where('salonId', isEqualTo: salonId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => SalonVideoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      log.e('[VideoShortsRepo] Error fetching salon videos', error: e);
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
      log.e('[VideoShortsRepo] Error fetching single video', error: e);
      return null;
    }
  }
}
