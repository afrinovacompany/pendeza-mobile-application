import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/utils/logger.dart';
import '../../data/models/review_model.dart';
import '../../data/repositories/reviews_repository_impl.dart';


/// Implementation of ReviewsRepository with Firestore backend.
///
/// Key features:
/// - ✅ ANY authenticated user can review (NO booking verification)
/// - One review per user per salon (can edit anytime)
/// - Owner replies supported
/// - Real-time rating aggregation
class ReviewsRepositoryImpl implements ReviewsRepository {
  final FirestoreService _firestoreService;

  ReviewsRepositoryImpl({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService;

  @override
  Future<ReviewModel> createReview({
    required String salonId,
    required String userId,
    required String userName,
    String? userProfilePicture,
    required double rating,
    required String comment,
  }) async {
    try {
      // 1. Check if user has already reviewed this salon
      final existingReview = await getUserReviewForSalon(
        salonId: salonId,
        userId: userId,
      );

      if (existingReview != null) {
        throw Exception('You have already reviewed this salon. You can edit your existing review.');
      }

      // ✅ REMOVED: Booking verification check
      // Any authenticated user can now review

      // 2. Create the review
      final review = ReviewModel.create(
        salonId: salonId,
        userId: userId,
        userName: userName,
        userProfilePicture: userProfilePicture,
        rating: rating,
        comment: comment,
        isVerifiedBooking: false, // Changed to false - no verification needed
        appointmentId: null, // No appointment required
      );

      // 3. Save to Firestore
      final createdReview = await _firestoreService.createReview(review);

      log.i('Review created successfully for salon $salonId by user $userId');
      return createdReview;
    } catch (e, s) {
      log.e('Error creating review', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> updateReview({
    required String reviewId,
    required String userId,
    required double rating,
    required String comment,
  }) async {
    try {
      await _firestoreService.updateReview(
        reviewId: reviewId,
        userId: userId,
        rating: rating,
        comment: comment,
      );

      log.i('Review $reviewId updated successfully');
    } catch (e, s) {
      log.e('Error updating review', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteReview({
    required String reviewId,
    required String userId,
  }) async {
    try {
      await _firestoreService.deleteReview(
        reviewId: reviewId,
        userId: userId,
      );

      log.i('Review $reviewId deleted successfully');
    } catch (e, s) {
      log.e('Error deleting review', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<List<ReviewModel>> getReviewsForSalon({
    required String salonId,
    String sortBy = 'recent',
    int? limit,
  }) async {
    try {
      final reviews = await _firestoreService.getReviewsForSalon(
        salonId: salonId,
        sortBy: sortBy,
        limit: limit,
      );

      log.d('Retrieved ${reviews.length} reviews for salon $salonId');
      return reviews;
    } catch (e, s) {
      log.e('Error getting reviews for salon', error: e, stackTrace: s);
      return [];
    }
  }

  @override
  Future<ReviewModel?> getUserReviewForSalon({
    required String salonId,
    required String userId,
  }) async {
    try {
      return await _firestoreService.getUserReviewForSalon(
        salonId: salonId,
        userId: userId,
      );
    } catch (e, s) {
      log.e('Error getting user review', error: e, stackTrace: s);
      return null;
    }
  }

  @override
  Future<bool> hasUserReviewedSalon({
    required String salonId,
    required String userId,
  }) async {
    try {
      final review = await getUserReviewForSalon(
        salonId: salonId,
        userId: userId,
      );
      return review != null;
    } catch (e, s) {
      log.e('Error checking if user reviewed salon', error: e, stackTrace: s);
      return false;
    }
  }

  @override
  Future<bool> canUserReviewSalon({
    required String salonId,
    required String userId,
  }) async {
    // ✅ SIMPLIFIED: All authenticated users can review
    // No booking check needed
    return true;
  }

  @override
  Future<String?> getCompletedAppointmentId({
    required String salonId,
    required String userId,
  }) async {
    try {
      return await _firestoreService.getCompletedAppointmentIdForReview(
        salonId: salonId,
        userId: userId,
      );
    } catch (e, s) {
      log.e('Error getting completed appointment', error: e, stackTrace: s);
      return null;
    }
  }

  //============================================================================
  // OWNER REPLY METHODS
  //============================================================================

  @override
  Future<void> addOwnerReply({
    required String reviewId,
    required String salonId,
    required String ownerId,
    required String replyText,
  }) async {
    try {
      // Verify that this user is actually the salon owner
      final salon = await _firestoreService.getSalonById(salonId);
      if (salon == null || salon.ownerId != ownerId) {
        throw Exception('Only the salon owner can reply to reviews');
      }

      await _firestoreService.addOwnerReplyToReview(
        reviewId: reviewId,
        ownerId: ownerId,
        replyText: replyText,
      );

      log.i('Owner reply added to review $reviewId');
    } catch (e, s) {
      log.e('Error adding owner reply', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteOwnerReply({
    required String reviewId,
    required String ownerId,
  }) async {
    try {
      await _firestoreService.deleteOwnerReply(
        reviewId: reviewId,
        ownerId: ownerId,
      );

      log.i('Owner reply deleted from review $reviewId');
    } catch (e, s) {
      log.e('Error deleting owner reply', error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // RATING AGGREGATION
  //============================================================================

  @override
  Future<double> getAverageRating({required String salonId}) async {
    try {
      final reviews = await getReviewsForSalon(salonId: salonId);

      if (reviews.isEmpty) return 0.0;

      final totalRating = reviews.fold<double>(
        0.0,
            (sum, review) => sum + review.rating,
      );

      final average = totalRating / reviews.length;
      return double.parse(average.toStringAsFixed(1)); // Round to 1 decimal
    } catch (e, s) {
      log.e('Error calculating average rating', error: e, stackTrace: s);
      return 0.0;
    }
  }

  @override
  Future<int> getReviewCount({required String salonId}) async {
    try {
      final reviews = await getReviewsForSalon(salonId: salonId);
      return reviews.length;
    } catch (e, s) {
      log.e('Error getting review count', error: e, stackTrace: s);
      return 0;
    }
  }

  @override
  Future<Map<int, int>> getRatingDistribution({required String salonId}) async {
    try {
      final reviews = await getReviewsForSalon(salonId: salonId);

      final distribution = <int, int>{
        5: 0,
        4: 0,
        3: 0,
        2: 0,
        1: 0,
      };

      for (final review in reviews) {
        final stars = review.starCount;
        distribution[stars] = (distribution[stars] ?? 0) + 1;
      }

      return distribution;
    } catch (e, s) {
      log.e('Error getting rating distribution', error: e, stackTrace: s);
      return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    }
  }

  //============================================================================
  // HELPFUL VOTING (Future feature)
  //============================================================================

  @override
  Future<void> markReviewHelpful({
    required String reviewId,
    required String userId,
  }) async {
    try {
      await _firestoreService.incrementReviewHelpfulCount(reviewId: reviewId);
      log.i('Review $reviewId marked as helpful by user $userId');
    } catch (e, s) {
      log.e('Error marking review as helpful', error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // REAL-TIME UPDATES
  //============================================================================

  @override
  Stream<List<ReviewModel>> watchReviewsForSalon({
    required String salonId,
    String sortBy = 'recent',
  }) {
    try {
      return _firestoreService.watchReviewsForSalon(
        salonId: salonId,
        sortBy: sortBy,
      );
    } catch (e, s) {
      log.e('Error watching reviews', error: e, stackTrace: s);
      return Stream.value([]);
    }
  }
}