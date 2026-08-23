import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'salon_profile_repository.dart';

class SalonProfileRepositoryImpl implements SalonProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final AuthBloc _authBloc;

  SalonProfileRepositoryImpl({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
    required AuthBloc authBloc,
  })  : _firestore = firestore,
        _storage = storage,
        _authBloc = authBloc;

  //============================================================================
  // GET SALON PROFILE
  //============================================================================

  @override
  Future<SalonModel> getSalonProfile(String salonId) async {
    try {
      final doc = await _firestore.collection('salons').doc(salonId).get();

      if (!doc.exists) {
        throw Exception('Salon not found');
      }

      return SalonModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get salon profile: $e');
    }
  }

  //============================================================================
  // UPDATE BASIC INFO
  //============================================================================

  @override
  Future<void> updateBasicInfo({
    required String salonId,
    required String salonName,
    String? description,
    required String address,
  }) async {
    try {
      await _firestore.collection('salons').doc(salonId).update({
        'salonName': salonName,
        'description': description,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update basic info: $e');
    }
  }

  //============================================================================
  // UPDATE CONTACT INFO
  //============================================================================

  @override
  Future<void> updateContactInfo({
    required String salonId,
    required String phoneNumber,
    String? whatsappNumber,
    String? instagram,
    String? facebook,
  }) async {
    try {
      await _firestore.collection('salons').doc(salonId).update({
        'phoneNumber': phoneNumber,
        'whatsappNumber': whatsappNumber,
        'instagram': instagram,
        'facebook': facebook,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update contact info: $e');
    }
  }

  //============================================================================
  // UPLOAD IMAGE (FIXED WITH METADATA)
  //============================================================================

  @override
  Future<String> uploadImage({
    required String salonId,
    required String imagePath,
    required bool isPrimary,
    Function(double)? onProgress,
  }) async {
    try {
      final file = File(imagePath);

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('Image file not found');
      }

      // Create storage path
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = isPrimary
          ? 'primary_$timestamp.jpg'
          : 'gallery_$timestamp.jpg';
      final path = 'salons/$salonId/${isPrimary ? 'primary' : 'gallery'}/$fileName';

      // Create reference
      final storageRef = _storage.ref().child(path);

      // --- CRITICAL FIX: ADD METADATA ---
      // This tells Firebase "This is an image", which passes your security rules.
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': salonId,
          'type': isPrimary ? 'primary' : 'gallery',
        },
      );

      // Upload with progress tracking AND metadata
      final uploadTask = storageRef.putFile(file, metadata);

      // Listen to progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        if (snapshot.totalBytes > 0) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress?.call(progress);
        }
      });

      // Wait for upload to complete
      final snapshot = await uploadTask;

      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      // Helper for debugging permission errors specifically
      if (e.toString().contains('403') || e.toString().contains('unauthorized')) {
        throw Exception('Permission denied. Please check your internet connection and try again.');
      }
      throw Exception('Failed to upload image: $e');
    }
  }

  //============================================================================
  // UPDATE PRIMARY IMAGE
  //============================================================================

  @override
  Future<void> updatePrimaryImage(String salonId, String imageUrl) async {
    try {
      await _firestore.collection('salons').doc(salonId).update({
        'primaryImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update primary image: $e');
    }
  }

  //============================================================================
  // ADD GALLERY IMAGE
  //============================================================================

  @override
  Future<void> addGalleryImage(String salonId, String imageUrl) async {
    try {
      await _firestore.collection('salons').doc(salonId).update({
        'imageGallery': FieldValue.arrayUnion([imageUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add gallery image: $e');
    }
  }

  //============================================================================
  // DELETE IMAGE
  //============================================================================

  @override
  Future<void> deleteImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      // Don't throw error if image doesn't exist
      // (it might already be deleted)
      debugPrint('Warning: Failed to delete image from storage: $e');
    }
  }

  //============================================================================
  // DELETE PRIMARY IMAGE
  //============================================================================

  @override
  Future<void> deletePrimaryImage(String salonId) async {
    try {
      await _firestore.collection('salons').doc(salonId).update({
        'primaryImage': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete primary image: $e');
    }
  }

  //============================================================================
  // DELETE GALLERY IMAGE
  //============================================================================

  @override
  Future<void> deleteGalleryImage(String salonId, int index) async {
    try {
      // Get current gallery
      final doc = await _firestore.collection('salons').doc(salonId).get();
      final data = doc.data() as Map<String, dynamic>;
      final gallery = List<String>.from(data['imageGallery'] ?? []);

      // Remove image at index
      if (index >= 0 && index < gallery.length) {
        gallery.removeAt(index);

        // Update Firestore
        await _firestore.collection('salons').doc(salonId).update({
          'imageGallery': gallery,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      throw Exception('Failed to delete gallery image: $e');
    }
  }

  //============================================================================
  // UPDATE BUSINESS HOURS
  //============================================================================

  @override
  Future<void> updateBusinessHours({
    required String salonId,
    required String openingTime,
    required String closingTime,
  }) async {
    try {
      await _firestore.collection('salons').doc(salonId).update({
        'openingTime': openingTime,
        'closingTime': closingTime,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update business hours: $e');
    }
  }

  //============================================================================
  // UPDATE AMENITIES
  //============================================================================

  @override
  Future<void> updateAmenities({
    required String salonId,
    required List<String> amenities,
  }) async {
    try {
      await _firestore.collection('salons').doc(salonId).update({
        'amenities': amenities,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update amenities: $e');
    }
  }

  //============================================================================
  // 🎬 NEW: VIDEO METHODS
  //============================================================================

  @override
  Future<List<SalonVideoModel>> getSalonVideos(String salonId) async {
    final querySnapshot = await _firestore
        .collection('salon_videos')
        .where('salonId', isEqualTo: salonId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => SalonVideoModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<int> getVideoCount(String salonId) async {
    final querySnapshot = await _firestore
        .collection('salon_videos')
        .where('salonId', isEqualTo: salonId)
        .count()
        .get();

    return querySnapshot.count ?? 0;
  }

  @override
  Future<String> uploadVideo({
    required String salonId,
    required String videoPath,
    Function(double)? onProgress,
  }) async {
    final file = File(videoPath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = _storage.ref().child('salon_videos/$salonId/$fileName');

    final uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'video/mp4'),
    );

    uploadTask.snapshotEvents.listen((event) {
      final progress = event.bytesTransferred / event.totalBytes;
      onProgress?.call(progress);
    });

    await uploadTask;
    return await ref.getDownloadURL();
  }

  @override
  Future<String> uploadVideoThumbnail({
    required String salonId,
    required String videoId,
    required String thumbnailPath,
  }) async {
    final file = File(thumbnailPath);
    final fileName = '${videoId}_thumb.jpg';
    final ref = _storage.ref().child('salon_videos/$salonId/thumbnails/$fileName');

    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await ref.getDownloadURL();
  }

  @override
  Future<SalonVideoModel> createVideoRecord({
    required String salonId,
    required String videoUrl,
    required String thumbnailUrl,
    required int durationSeconds,
    String? caption,
  }) async {
    // Get salon data for denormalization
    final salonDoc = await _firestore.collection('salons').doc(salonId).get();
    final salonData = salonDoc.data()!;

    // Get owner ID
    final authState = _authBloc.state;
    if (authState is! Authenticated) {
      throw Exception('User not authenticated');
    }
    final ownerId = authState.user.uid;

    // Create video document
    final videoRef = _firestore.collection('salon_videos').doc();

    final video = SalonVideoModel(
      id: videoRef.id,
      salonId: salonId,
      salonName: salonData['salonName'] as String,
      salonImage: salonData['primaryImage'] as String?,
      salonAddress: salonData['address'] as String?,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: caption,
      durationSeconds: durationSeconds,
      createdAt: DateTime.now(),
      ownerId: ownerId,
    );

    await videoRef.set(video.toFirestore());

    return video;
  }

  @override
  Future<void> updateVideoCaption({
    required String videoId,
    required String caption,
  }) async {
    await _firestore.collection('salon_videos').doc(videoId).update({
      'caption': caption,
    });
  }

  @override
  Future<void> deleteVideo(String videoId) async {
    // Get video document first
    final videoDoc = await _firestore.collection('salon_videos').doc(videoId).get();

    if (!videoDoc.exists) {
      throw Exception('Video not found');
    }

    final videoData = videoDoc.data()!;
    final videoUrl = videoData['videoUrl'] as String;
    final thumbnailUrl = videoData['thumbnailUrl'] as String;

    // Delete video file from Storage
    try {
      final videoRef = _storage.refFromURL(videoUrl);
      await videoRef.delete();
    } catch (e) {
      debugPrint('Error deleting video file: $e');
    }

    // Delete thumbnail from Storage
    try {
      final thumbRef = _storage.refFromURL(thumbnailUrl);
      await thumbRef.delete();
    } catch (e) {
      debugPrint('Error deleting thumbnail: $e');
    }

    // Delete Firestore document
    await _firestore.collection('salon_videos').doc(videoId).delete();
  }

  @override
  Future<void> deleteVideoFile(String videoUrl) async {
    try {
      final ref = _storage.refFromURL(videoUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting video file: $e');
    }
  }
}