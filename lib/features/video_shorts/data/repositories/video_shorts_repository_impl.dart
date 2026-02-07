import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';
import '../../domain/repositories/video_shorts_repository.dart';

class VideoShortsRepositoryImpl implements VideoShortsRepository {
  final FirebaseFirestore _firestore;

  VideoShortsRepositoryImpl({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  @override
  Future<List<SalonVideoModel>> getApprovedVideos({int limit = 20}) async {
    try {
      final querySnapshot = await _firestore
          .collection('salon_videos')
          .where('status', isEqualTo: 'approved')
          .orderBy('approvedAt', descending: true)
          .limit(limit)
          .get();

      final videos = querySnapshot.docs
          .map((doc) => SalonVideoModel.fromFirestore(doc))
          .where((video) => !video.isExpired) // Filter out expired videos
          .toList();

      return videos;
    } catch (e) {
      debugPrint('VideoShortsRepository: Error fetching approved videos: $e');
      return [];
    }
  }

  @override
  Future<List<SalonVideoModel>> getSalonApprovedVideos(String salonId) async {
    try {
      final querySnapshot = await _firestore
          .collection('salon_videos')
          .where('salonId', isEqualTo: salonId)
          .where('status', isEqualTo: 'approved')
          .orderBy('approvedAt', descending: true)
          .get();

      final videos = querySnapshot.docs
          .map((doc) => SalonVideoModel.fromFirestore(doc))
          .where((video) => !video.isExpired)
          .toList();

      return videos;
    } catch (e) {
      debugPrint('VideoShortsRepository: Error fetching salon videos: $e');
      return [];
    }
  }

  @override
  Stream<List<SalonVideoModel>> watchApprovedVideos({int limit = 20}) {
    return _firestore
        .collection('salon_videos')
        .where('status', isEqualTo: 'approved')
        .orderBy('approvedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SalonVideoModel.fromFirestore(doc))
          .where((video) => !video.isExpired)
          .toList();
    });
  }
}
