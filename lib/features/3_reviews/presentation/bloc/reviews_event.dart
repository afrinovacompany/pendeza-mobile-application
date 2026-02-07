import 'package:equatable/equatable.dart';

/// Base class for all review events
abstract class ReviewsEvent extends Equatable {
  const ReviewsEvent();

  @override
  List<Object?> get props => [];
}

/// Load reviews for a specific salon
class LoadReviews extends ReviewsEvent {
  final String salonId;
  final String sortBy; // 'recent', 'highest', 'lowest'

  const LoadReviews({
    required this.salonId,
    this.sortBy = 'recent',
  });

  @override
  List<Object?> get props => [salonId, sortBy];
}

/// Refresh reviews for a salon
class RefreshReviews extends ReviewsEvent {
  final String salonId;

  const RefreshReviews({required this.salonId});

  @override
  List<Object?> get props => [salonId];
}

/// Sort reviews by different criteria
class SortReviews extends ReviewsEvent {
  final String sortBy; // 'recent', 'highest', 'lowest'

  const SortReviews({required this.sortBy});

  @override
  List<Object?> get props => [sortBy];
}

/// Check if user can write a review (has completed booking)
class CheckReviewEligibility extends ReviewsEvent {
  final String salonId;
  final String userId;

  const CheckReviewEligibility({
    required this.salonId,
    required this.userId,
  });

  @override
  List<Object?> get props => [salonId, userId];
}

/// Load user's existing review for a salon (if any)
class LoadUserReview extends ReviewsEvent {
  final String salonId;
  final String userId;

  const LoadUserReview({
    required this.salonId,
    required this.userId,
  });

  @override
  List<Object?> get props => [salonId, userId];
}

/// Submit a new review
class SubmitReview extends ReviewsEvent {
  final String salonId;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final double rating;
  final String comment;

  const SubmitReview({
    required this.salonId,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.rating,
    required this.comment,
  });

  @override
  List<Object?> get props => [
    salonId,
    userId,
    userName,
    userProfilePicture,
    rating,
    comment,
  ];
}

/// Update an existing review
class UpdateReview extends ReviewsEvent {
  final String reviewId;
  final String userId;
  final double rating;
  final String comment;

  const UpdateReview({
    required this.reviewId,
    required this.userId,
    required this.rating,
    required this.comment,
  });

  @override
  List<Object?> get props => [reviewId, userId, rating, comment];
}

/// Delete a review
class DeleteReview extends ReviewsEvent {
  final String reviewId;
  final String userId;

  const DeleteReview({
    required this.reviewId,
    required this.userId,
  });

  @override
  List<Object?> get props => [reviewId, userId];
}

/// --- OWNER REPLY EVENTS ---

/// Add or update owner's reply to a review
class AddOwnerReply extends ReviewsEvent {
  final String reviewId;
  final String salonId;
  final String ownerId;
  final String replyText;

  const AddOwnerReply({
    required this.reviewId,
    required this.salonId,
    required this.ownerId,
    required this.replyText,
  });

  @override
  List<Object?> get props => [reviewId, salonId, ownerId, replyText];
}

/// Delete owner's reply
class DeleteOwnerReply extends ReviewsEvent {
  final String reviewId;
  final String ownerId;

  const DeleteOwnerReply({
    required this.reviewId,
    required this.ownerId,
  });

  @override
  List<Object?> get props => [reviewId, ownerId];
}

/// --- HELPFUL VOTING (Future feature) ---

/// Mark a review as helpful
class MarkReviewHelpful extends ReviewsEvent {
  final String reviewId;
  final String userId;

  const MarkReviewHelpful({
    required this.reviewId,
    required this.userId,
  });

  @override
  List<Object?> get props => [reviewId, userId];
}