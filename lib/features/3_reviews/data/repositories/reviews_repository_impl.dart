
import '../models/review_model.dart';

/// Abstract repository interface for managing salon reviews.
///
/// This repository handles:
/// - Creating new reviews (with verification check)
/// - Updating existing reviews
/// - Deleting reviews
/// - Fetching reviews for a salon
/// - Owner replies to reviews
/// - Rating aggregation
abstract class ReviewsRepository {
  /// Create a new review for a salon
  ///
  /// Checks if user has completed booking before allowing review
  /// Returns the created review with ID
  Future<ReviewModel> createReview({
    required String salonId,
    required String userId,
    required String userName,
    String? userProfilePicture,
    required double rating,
    required String comment,
  });

  /// Update an existing review
  ///
  /// Only the review author can update their review
  Future<void> updateReview({
    required String reviewId,
    required String userId,
    required double rating,
    required String comment,
  });

  /// Delete a review
  ///
  /// Only the review author can delete their review
  Future<void> deleteReview({
    required String reviewId,
    required String userId,
  });

  /// Get all reviews for a specific salon
  ///
  /// [sortBy]: 'recent', 'highest', 'lowest'
  Future<List<ReviewModel>> getReviewsForSalon({
    required String salonId,
    String sortBy = 'recent',
    int? limit,
  });

  /// Get a specific user's review for a salon
  ///
  /// Returns null if user hasn't reviewed this salon yet
  Future<ReviewModel?> getUserReviewForSalon({
    required String salonId,
    required String userId,
  });

  /// Check if user has already reviewed a salon
  Future<bool> hasUserReviewedSalon({
    required String salonId,
    required String userId,
  });

  /// Check if user is eligible to review (has completed booking)
  Future<bool> canUserReviewSalon({
    required String salonId,
    required String userId,
  });

  /// Get the completed appointment ID for verification
  ///
  /// Returns null if no completed appointments found
  Future<String?> getCompletedAppointmentId({
    required String salonId,
    required String userId,
  });

  /// --- OWNER REPLY METHODS ---

  /// Add or update owner's reply to a review
  ///
  /// Only salon owner can reply
  Future<void> addOwnerReply({
    required String reviewId,
    required String salonId,
    required String ownerId,
    required String replyText,
  });

  /// Delete owner's reply
  Future<void> deleteOwnerReply({
    required String reviewId,
    required String ownerId,
  });

  /// --- RATING AGGREGATION ---

  /// Calculate and get average rating for a salon
  Future<double> getAverageRating({required String salonId});

  /// Get total review count for a salon
  Future<int> getReviewCount({required String salonId});

  /// Get rating distribution (how many 5-star, 4-star, etc.)
  Future<Map<int, int>> getRatingDistribution({required String salonId});

  /// --- HELPFUL VOTING (for future) ---

  /// Mark a review as helpful
  Future<void> markReviewHelpful({
    required String reviewId,
    required String userId,
  });

  /// --- REAL-TIME UPDATES ---

  /// Stream reviews for real-time updates
  Stream<List<ReviewModel>> watchReviewsForSalon({
    required String salonId,
    String sortBy = 'recent',
  });
}