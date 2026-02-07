import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:pendeza/app/utils/logger.dart';

/// 🔥 ALL-IN-ONE FIX FOR REVIEWS NOT SHOWING 🔥
///
/// Usage:
/// ```dart
/// await QuickReviewsFix.fix();
/// ```
class QuickReviewsFix {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Run the complete fix: cleanup old reviews + import to correct location
  static Future<void> fix() async {
    log.i('🚀 Starting COMPLETE reviews fix...\n');

    // Step 1: Clean up old reviews
    log.i('📍 STEP 1: Cleaning up old reviews from wrong location');
    await _cleanupTopLevelReviews();

    // Step 2: Re-import to correct location
    log.i('\n📍 STEP 2: Re-importing reviews to correct location');
    await _importReviewsToSubCollections();

    // Step 3: Verify
    log.i('\n📍 STEP 3: Verifying fix');
    await _verifyReviewsLocation();

    log.i('\n🎉 COMPLETE! Reviews should now be visible in your app!');
  }

  //============================================================================
  // STEP 1: CLEANUP
  //============================================================================

  static Future<void> _cleanupTopLevelReviews() async {
    try {
      final snapshot = await _firestore.collection('reviews').get();

      if (snapshot.docs.isEmpty) {
        log.i('✅ No cleanup needed - top-level reviews collection is empty');
        return;
      }

      log.i('🗑️  Deleting ${snapshot.docs.length} reviews from wrong location...');

      // Delete in batches
      final batches = <WriteBatch>[];
      var currentBatch = _firestore.batch();
      var operationCount = 0;

      for (final doc in snapshot.docs) {
        currentBatch.delete(doc.reference);
        operationCount++;

        if (operationCount >= 500) {
          batches.add(currentBatch);
          currentBatch = _firestore.batch();
          operationCount = 0;
        }
      }

      if (operationCount > 0) {
        batches.add(currentBatch);
      }

      for (var batch in batches) {
        await batch.commit();
      }

      log.i('✅ Cleanup complete! Deleted ${snapshot.docs.length} reviews');
    } catch (e, s) {
      log.e('❌ Cleanup error', error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // STEP 2: RE-IMPORT TO CORRECT LOCATION
  //============================================================================

  static Future<void> _importReviewsToSubCollections() async {
    final user = _auth.currentUser;
    if (user == null) {
      log.e('❌ ERROR: You must be logged in to import reviews');
      return;
    }

    final String currentUserId = user.uid;
    int reviewSuccessCount = 0;

    try {
      // Load JSON
      final reviewJsonString = await rootBundle.loadString('assets/data/reviews_mega.json');
      final List<dynamic> reviewsData = json.decode(reviewJsonString);

      log.i('📦 Found ${reviewsData.length} reviews to import');

      // Get list of existing salons
      final salonsSnapshot = await _firestore.collection('salons').get();
      final validSalonIds = salonsSnapshot.docs.map((doc) => doc.id).toSet();

      log.i('🏪 Found ${validSalonIds.length} salons in database');

      for (var reviewJson in reviewsData) {
        try {
          final data = Map<String, dynamic>.from(reviewJson);
          final reviewId = data['reviewId'] as String?;
          final salonId = data['salonId'] as String?;

          // Skip if salon doesn't exist
          if (salonId == null || !validSalonIds.contains(salonId)) {
            continue;
          }

          // Map fields
          data['userId'] = currentUserId;

          // reviewText → comment
          if (data.containsKey('reviewText')) {
            data['comment'] = data['reviewText'];
            data.remove('reviewText');
          }

          // response → ownerReply
          if (data['response'] != null && data['response'] != '') {
            data['ownerReply'] = data['response'];
            data['ownerUserId'] = currentUserId;
          }
          data.remove('response');

          // responseDate → ownerRepliedAt
          if (data['responseDate'] != null) {
            try {
              data['ownerRepliedAt'] = Timestamp.fromDate(DateTime.parse(data['responseDate']));
            } catch (e) {
              // Skip if date parsing fails
            }
            data.remove('responseDate');
          }

          // helpful → helpfulCount
          if (data['helpful'] != null) {
            data['helpfulCount'] = data['helpful'];
          } else {
            data['helpfulCount'] = 0;
          }
          data.remove('helpful');

          // reviewDate → createdAt
          if (data['reviewDate'] is String) {
            try {
              final date = DateTime.parse(data['reviewDate']);
              data['createdAt'] = Timestamp.fromDate(date);
            } catch (e) {
              data['createdAt'] = Timestamp.now();
            }
          } else {
            data['createdAt'] = Timestamp.now();
          }
          data.remove('reviewDate');

          // Defaults
          data['isVerifiedBooking'] = false;
          data.remove('reviewId');

          // 🔥 THE KEY FIX: Write to salon sub-collection 🔥
          final reviewRef = _firestore
              .collection('salons')
              .doc(salonId)
              .collection('reviews');

          if (reviewId != null) {
            await reviewRef.doc(reviewId).set(data);
          } else {
            await reviewRef.add(data);
          }

          reviewSuccessCount++;

          // Log progress every 10 reviews
          if (reviewSuccessCount % 10 == 0) {
            log.i('📝 Imported $reviewSuccessCount reviews...');
          }
        } catch (e) {
          log.e('❌ Error importing single review: $e');
        }
      }

      log.i('✅ Successfully imported $reviewSuccessCount reviews to correct location');
    } catch (e, s) {
      log.e('❌ Fatal error importing reviews', error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // STEP 3: VERIFY
  //============================================================================

  static Future<void> _verifyReviewsLocation() async {
    try {
      // Get a random salon
      final salonsSnapshot = await _firestore
          .collection('salons')
          .limit(1)
          .get();

      if (salonsSnapshot.docs.isEmpty) {
        log.w('⚠️ No salons found to verify');
        return;
      }

      final salonId = salonsSnapshot.docs.first.id;
      final salonName = salonsSnapshot.docs.first.data()['salonName'] ?? 'Unknown';

      // Check reviews in sub-collection
      final reviewsSnapshot = await _firestore
          .collection('salons')
          .doc(salonId)
          .collection('reviews')
          .get();

      if (reviewsSnapshot.docs.isEmpty) {
        log.w('⚠️ No reviews found for salon: $salonName');
      } else {
        log.i('✅ SUCCESS! Found ${reviewsSnapshot.docs.length} reviews for salon: $salonName');
        log.i('   Path: salons/$salonId/reviews');
      }
    } catch (e, s) {
      log.e('❌ Error verifying', error: e, stackTrace: s);
    }
  }
}