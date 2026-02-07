import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/2_client_profile/domain/repositories/profile_repository.dart';
import '../../../../app/helpers/image_compressor_helper.dart';
import '../../data/models/profile_stats.dart';

/// ============================================================================
/// PROFILE REPOSITORY IMPLEMENTATION - FIXED VERSION
/// ============================================================================
///
/// 🔥 FIXES APPLIED:
///
/// 1. Storage Path: Changed from 'users/{userId}/profile_pic.jpg' to
///    'profile_pictures/{userId}/profile_pic.jpg' to match Firebase Storage rules
///
/// 2. Aggregate Queries: Using regular queries with client-side counting
///    as a fallback when aggregate queries fail due to permissions
///
/// 3. Better error handling and logging
/// ============================================================================

class ProfileRepositoryImpl implements ProfileRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<ProfileStats> getUserStats(String userId) async {
    try {
      // Try aggregate queries first (more efficient)
      return await _getUserStatsWithAggregate(userId);
    } catch (e) {
      // Fallback to regular queries if aggregate fails (permission issues)
      log.w('ProfileRepo: Aggregate query failed, falling back to regular queries', error: e);
      return await _getUserStatsWithRegularQueries(userId);
    }
  }

  /// Primary method: Use aggregate queries (more efficient)
  Future<ProfileStats> _getUserStatsWithAggregate(String userId) async {
    // 1. Count Bookings
    final bookingsCountQuery = await _db
        .collection('appointments')
        .where('clientId', isEqualTo: userId)
        .count()
        .get();

    // 2. Count Reviews
    final reviewsCountQuery = await _db
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .count()
        .get();

    // 3. Count Favorites (subcollection)
    final favoritesCountQuery = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .count()
        .get();

    log.d('ProfileRepo: Stats loaded via aggregate - '
        'bookings: ${bookingsCountQuery.count}, '
        'reviews: ${reviewsCountQuery.count}, '
        'favorites: ${favoritesCountQuery.count}');

    return ProfileStats(
      totalBookings: bookingsCountQuery.count ?? 0,
      totalReviews: reviewsCountQuery.count ?? 0,
      totalFavorites: favoritesCountQuery.count ?? 0,
    );
  }

  /// Fallback method: Use regular queries with client-side counting
  Future<ProfileStats> _getUserStatsWithRegularQueries(String userId) async {
    try {
      // 1. Count Bookings
      final bookingsSnapshot = await _db
          .collection('appointments')
          .where('clientId', isEqualTo: userId)
          .limit(1000)
          .get();
      final bookingsCount = bookingsSnapshot.docs.length;

      // 2. Count Reviews
      final reviewsSnapshot = await _db
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .limit(1000)
          .get();
      final reviewsCount = reviewsSnapshot.docs.length;

      // 3. Count Favorites
      final favoritesSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .limit(1000)
          .get();
      final favoritesCount = favoritesSnapshot.docs.length;

      log.d('ProfileRepo: Stats loaded via regular queries - '
          'bookings: $bookingsCount, '
          'reviews: $reviewsCount, '
          'favorites: $favoritesCount');

      return ProfileStats(
        totalBookings: bookingsCount,
        totalReviews: reviewsCount,
        totalFavorites: favoritesCount,
      );
    } catch (e, s) {
      log.e('ProfileRepo: Failed to fetch stats for $userId', error: e, stackTrace: s);
      return const ProfileStats();
    }
  }

  @override
  Future<String> updateProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      // 1. Compress the image to save bandwidth and storage cost
      final compressedFile = await ImageCompressionHelper.compressProfilePicture(imageFile);
      final fileToUpload = compressedFile ?? imageFile;

      // ================================================================
      // 🔥 FIX: Use correct path that matches Firebase Storage rules!
      //
      // Your storage rules allow writes to:
      //   match /profile_pictures/{userId}/{allPaths=**}
      //
      // But the old code was uploading to:
      //   users/{userId}/profile_pic.jpg
      //
      // This path mismatch caused:
      // 1. Upload might fail due to permission denied
      // 2. Or upload to wrong location that isn't persisted properly
      // ================================================================
      final ref = _storage.ref().child('profile_pictures/$userId/profile_pic.jpg');

      log.i('ProfileRepo: Uploading profile image to: profile_pictures/$userId/profile_pic.jpg');

      final uploadTask = await ref.putFile(fileToUpload);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      log.i('ProfileRepo: Upload successful. URL: $downloadUrl');

      // 3. Update Firestore User Document
      await _db.collection('users').doc(userId).update({
        'profilePictureUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log.i('ProfileRepo: Updated user document with new profile picture URL');

      return downloadUrl;
    } catch (e, s) {
      log.e('ProfileRepo: Failed to upload image', error: e, stackTrace: s);
      throw Exception('Failed to upload image. Please try again.');
    }
  }

  @override
  Future<void> updateProfileData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Add timestamp
      final updateData = Map<String, dynamic>.from(data);
      updateData['updatedAt'] = FieldValue.serverTimestamp();

      await _db.collection('users').doc(userId).update(updateData);
      log.i('ProfileRepo: Updated profile data for $userId');
    } catch (e, s) {
      log.e('ProfileRepo: Failed to update profile data', error: e, stackTrace: s);
      throw Exception('Failed to update profile.');
    }
  }

  @override
  Future<void> updateAppSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _db.collection('users').doc(userId).update({
        'settings': settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log.i('ProfileRepo: Updated app settings for $userId');
    } catch (e) {
      log.e('ProfileRepo: Failed to update settings', error: e);
    }
  }
}