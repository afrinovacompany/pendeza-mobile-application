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
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => SalonVideoModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('VideoShortsRepository: Error fetching videos: $e');
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
      debugPrint('VideoShortsRepository: Error fetching salon videos: $e');
      return [];
    }
  }

  @override
  Stream<List<SalonVideoModel>> watchApprovedVideos({int limit = 20}) {
    return _firestore
        .collection('salon_videos')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SalonVideoModel.fromFirestore(doc))
          .toList();
    });
  }
}
