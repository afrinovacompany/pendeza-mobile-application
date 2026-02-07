import 'package:equatable/equatable.dart';
import '../../data/models/review_model.dart';




/// Base class for all review states
abstract class ReviewsState extends Equatable {
  const ReviewsState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any reviews are loaded
class ReviewsInitial extends ReviewsState {
  const ReviewsInitial();
}

/// Loading reviews
class ReviewsLoading extends ReviewsState {
  const ReviewsLoading();
}

/// Successfully loaded reviews
class ReviewsLoaded extends ReviewsState {
  final List<ReviewModel> reviews;
  final String salonId;
  final double averageRating;
  final int totalReviews;
  final Map<int, int> ratingDistribution;
  final String sortBy;

  const ReviewsLoaded({
    required this.reviews,
    required this.salonId,
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
    this.sortBy = 'recent',
  });

  /// Check if there are any reviews
  bool get hasReviews => reviews.isNotEmpty;

  /// Get reviews with owner replies only
  List<ReviewModel> get reviewsWithReplies =>
      reviews.where((r) => r.hasOwnerReply).toList();

  /// Get verified booking reviews only
  List<ReviewModel> get verifiedReviews =>
      reviews.where((r) => r.isVerifiedBooking).toList();

  @override
  List<Object?> get props => [
    reviews,
    salonId,
    averageRating,
    totalReviews,
    ratingDistribution,
    sortBy,
  ];

  /// Copy with updated fields
  ReviewsLoaded copyWith({
    List<ReviewModel>? reviews,
    String? salonId,
    double? averageRating,
    int? totalReviews,
    Map<int, int>? ratingDistribution,
    String? sortBy,
  }) {
    return ReviewsLoaded(
      reviews: reviews ?? this.reviews,
      salonId: salonId ?? this.salonId,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      ratingDistribution: ratingDistribution ?? this.ratingDistribution,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

/// Empty state when salon has no reviews
class ReviewsEmpty extends ReviewsState {
  final String salonId;
  final String message;

  const ReviewsEmpty({
    required this.salonId,
    this.message = 'No reviews yet. Be the first to review!',
  });

  @override
  List<Object?> get props => [salonId, message];
}

/// Error loading reviews
class ReviewsError extends ReviewsState {
  final String message;
  final String? errorCode;

  const ReviewsError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

/// --- USER REVIEW STATES ---

/// Checking if user can write a review
class CheckingEligibility extends ReviewsState {
  final String salonId;

  const CheckingEligibility({required this.salonId});

  @override
  List<Object?> get props => [salonId];
}

/// User is eligible to write a review
class EligibleToReview extends ReviewsState {
  final String salonId;
  final bool hasExistingReview;
  final ReviewModel? existingReview;

  const EligibleToReview({
    required this.salonId,
    this.hasExistingReview = false,
    this.existingReview,
  });

  @override
  List<Object?> get props => [salonId, hasExistingReview, existingReview];
}

/// User is NOT eligible to write a review
class NotEligibleToReview extends ReviewsState {
  final String salonId;
  final String reason;

  const NotEligibleToReview({
    required this.salonId,
    this.reason = 'You must complete a booking at this salon to leave a review',
  });

  @override
  List<Object?> get props => [salonId, reason];
}

/// Submitting a review
class SubmittingReview extends ReviewsState {
  const SubmittingReview();
}

/// Review submitted successfully
class ReviewSubmitted extends ReviewsState {
  final ReviewModel review;
  final String message;

  const ReviewSubmitted({
    required this.review,
    this.message = 'Review submitted successfully!',
  });

  @override
  List<Object?> get props => [review, message];
}

/// Updating a review
class UpdatingReview extends ReviewsState {
  final String reviewId;

  const UpdatingReview({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

/// Review updated successfully
class ReviewUpdated extends ReviewsState {
  final String reviewId;
  final String message;

  const ReviewUpdated({
    required this.reviewId,
    this.message = 'Review updated successfully!',
  });

  @override
  List<Object?> get props => [reviewId, message];
}

/// Deleting a review
class DeletingReview extends ReviewsState {
  final String reviewId;

  const DeletingReview({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

/// Review deleted successfully
class ReviewDeleted extends ReviewsState {
  final String reviewId;
  final String message;

  const ReviewDeleted({
    required this.reviewId,
    this.message = 'Review deleted successfully',
  });

  @override
  List<Object?> get props => [reviewId, message];
}

/// --- OWNER REPLY STATES ---

/// Adding owner reply
class AddingOwnerReply extends ReviewsState {
  final String reviewId;

  const AddingOwnerReply({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

/// Owner reply added successfully
class OwnerReplyAdded extends ReviewsState {
  final String reviewId;
  final String message;

  const OwnerReplyAdded({
    required this.reviewId,
    this.message = 'Reply posted successfully',
  });

  @override
  List<Object?> get props => [reviewId, message];
}

/// Deleting owner reply
class DeletingOwnerReply extends ReviewsState {
  final String reviewId;

  const DeletingOwnerReply({required this.reviewId});

  @override
  List<Object?> get props => [reviewId];
}

/// Owner reply deleted successfully
class OwnerReplyDeleted extends ReviewsState {
  final String reviewId;
  final String message;

  const OwnerReplyDeleted({
    required this.reviewId,
    this.message = 'Reply deleted successfully',
  });

  @override
  List<Object?> get props => [reviewId, message];
}