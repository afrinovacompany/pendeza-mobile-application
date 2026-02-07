import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/utils/logger.dart';
import '../../data/repositories/reviews_repository_impl.dart';
import 'reviews_event.dart';
import 'reviews_state.dart';

/// BLoC for managing reviews feature.
///
/// This BLoC handles:
/// - Loading and displaying reviews
/// - ✅ Creating, updating, deleting reviews (NO booking verification)
/// - Owner replies to reviews
/// - Rating aggregation
/// - Sorting and filtering
class ReviewsBloc extends Bloc<ReviewsEvent, ReviewsState> {
  final ReviewsRepository _reviewsRepository;

  ReviewsBloc({
    required ReviewsRepository reviewsRepository,
  })  : _reviewsRepository = reviewsRepository,
        super(const ReviewsInitial()) {
    // Register event handlers
    on<LoadReviews>(_onLoadReviews);
    on<RefreshReviews>(_onRefreshReviews);
    on<SortReviews>(_onSortReviews);
    on<CheckReviewEligibility>(_onCheckReviewEligibility);
    on<LoadUserReview>(_onLoadUserReview);
    on<SubmitReview>(_onSubmitReview);
    on<UpdateReview>(_onUpdateReview);
    on<DeleteReview>(_onDeleteReview);
    on<AddOwnerReply>(_onAddOwnerReply);
    on<DeleteOwnerReply>(_onDeleteOwnerReply);
    on<MarkReviewHelpful>(_onMarkReviewHelpful);
  }

  //============================================================================
  // LOAD REVIEWS
  //============================================================================

  Future<void> _onLoadReviews(
      LoadReviews event,
      Emitter<ReviewsState> emit,
      ) async {
    try {
      emit(const ReviewsLoading());

      log.i('Loading reviews for salon: ${event.salonId}');

      // Load reviews
      final reviews = await _reviewsRepository.getReviewsForSalon(
        salonId: event.salonId,
        sortBy: event.sortBy,
      );

      // If no reviews, emit empty state
      if (reviews.isEmpty) {
        emit(ReviewsEmpty(salonId: event.salonId));
        return;
      }

      // Calculate aggregated data
      final averageRating = await _reviewsRepository.getAverageRating(
        salonId: event.salonId,
      );

      final ratingDistribution =
      await _reviewsRepository.getRatingDistribution(
        salonId: event.salonId,
      );

      emit(ReviewsLoaded(
        reviews: reviews,
        salonId: event.salonId,
        averageRating: averageRating,
        totalReviews: reviews.length,
        ratingDistribution: ratingDistribution,
        sortBy: event.sortBy,
      ));

      log.i('Loaded ${reviews.length} reviews with avg rating $averageRating');
    } catch (e, s) {
      log.e('Error loading reviews', error: e, stackTrace: s);
      emit(ReviewsError(
        message: 'Failed to load reviews. Please try again.',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // REFRESH REVIEWS
  //============================================================================

  Future<void> _onRefreshReviews(
      RefreshReviews event,
      Emitter<ReviewsState> emit,
      ) async {
    final currentState = state;

    try {
      // Keep current sort if available
      String sortBy = 'recent';
      if (currentState is ReviewsLoaded) {
        sortBy = currentState.sortBy;
      }

      // Reload without showing loading state (smoother UX)
      final reviews = await _reviewsRepository.getReviewsForSalon(
        salonId: event.salonId,
        sortBy: sortBy,
      );

      if (reviews.isEmpty) {
        emit(ReviewsEmpty(salonId: event.salonId));
        return;
      }

      final averageRating = await _reviewsRepository.getAverageRating(
        salonId: event.salonId,
      );

      final ratingDistribution =
      await _reviewsRepository.getRatingDistribution(
        salonId: event.salonId,
      );

      emit(ReviewsLoaded(
        reviews: reviews,
        salonId: event.salonId,
        averageRating: averageRating,
        totalReviews: reviews.length,
        ratingDistribution: ratingDistribution,
        sortBy: sortBy,
      ));

      log.i('Refreshed ${reviews.length} reviews');
    } catch (e, s) {
      log.e('Error refreshing reviews', error: e, stackTrace: s);
      emit(ReviewsError(message: 'Failed to refresh reviews'));
    }
  }

  //============================================================================
  // SORT REVIEWS
  //============================================================================

  Future<void> _onSortReviews(
      SortReviews event,
      Emitter<ReviewsState> emit,
      ) async {
    final currentState = state;
    if (currentState is! ReviewsLoaded) return;

    try {
      final reviews = await _reviewsRepository.getReviewsForSalon(
        salonId: currentState.salonId,
        sortBy: event.sortBy,
      );

      emit(currentState.copyWith(
        reviews: reviews,
        sortBy: event.sortBy,
      ));

      log.i('Sorted reviews by: ${event.sortBy}');
    } catch (e, s) {
      log.e('Error sorting reviews', error: e, stackTrace: s);
    }
  }

  //============================================================================
  // CHECK REVIEW ELIGIBILITY - ✅ SIMPLIFIED (NO BOOKING CHECK)
  //============================================================================

  Future<void> _onCheckReviewEligibility(
      CheckReviewEligibility event,
      Emitter<ReviewsState> emit,
      ) async {
    try {
      emit(CheckingEligibility(salonId: event.salonId));

      log.i('Checking review eligibility for user ${event.userId}');

      // ✅ SIMPLIFIED: Just check if user already has a review
      // All authenticated users are eligible to review
      final existingReview = await _reviewsRepository.getUserReviewForSalon(
        salonId: event.salonId,
        userId: event.userId,
      );

      // All authenticated users are eligible
      emit(EligibleToReview(
        salonId: event.salonId,
        hasExistingReview: existingReview != null,
        existingReview: existingReview,
      ));

      log.i('User eligible - ${existingReview != null ? "has existing review" : "can write new review"}');
    } catch (e, s) {
      log.e('Error checking eligibility', error: e, stackTrace: s);
      emit(ReviewsError(
        message: 'Failed to check review eligibility',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // LOAD USER REVIEW
  //============================================================================

  Future<void> _onLoadUserReview(
      LoadUserReview event,
      Emitter<ReviewsState> emit,
      ) async {
    try {
      final review = await _reviewsRepository.getUserReviewForSalon(
        salonId: event.salonId,
        userId: event.userId,
      );

      if (review != null) {
        emit(EligibleToReview(
          salonId: event.salonId,
          hasExistingReview: true,
          existingReview: review,
        ));
      } else {
        emit(EligibleToReview(
          salonId: event.salonId,
          hasExistingReview: false,
        ));
      }
    } catch (e, s) {
      log.e('Error loading user review', error: e, stackTrace: s);
    }
  }

  //============================================================================
  // SUBMIT REVIEW - ✅ REMOVED BOOKING ERROR MESSAGE
  //============================================================================

  Future<void> _onSubmitReview(
      SubmitReview event,
      Emitter<ReviewsState> emit,
      ) async {
    try {
      emit(const SubmittingReview());

      log.i('Submitting review for salon ${event.salonId}');

      final review = await _reviewsRepository.createReview(
        salonId: event.salonId,
        userId: event.userId,
        userName: event.userName,
        userProfilePicture: event.userProfilePicture,
        rating: event.rating,
        comment: event.comment,
      );

      emit(ReviewSubmitted(review: review));

      log.i('Review submitted successfully');

      // Auto-refresh reviews list
      add(LoadReviews(salonId: event.salonId));
    } catch (e, s) {
      log.e('Error submitting review', error: e, stackTrace: s);

      String errorMessage = 'Failed to submit review';
      if (e.toString().contains('already reviewed')) {
        errorMessage = 'You have already reviewed this salon. You can edit your existing review.';
      }
      // ✅ REMOVED: booking completion error message

      emit(ReviewsError(
        message: errorMessage,
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // UPDATE REVIEW
  //============================================================================

  Future<void> _onUpdateReview(
      UpdateReview event,
      Emitter<ReviewsState> emit,
      ) async {
    try {
      emit(UpdatingReview(reviewId: event.reviewId));

      log.i('Updating review ${event.reviewId}');

      await _reviewsRepository.updateReview(
        reviewId: event.reviewId,
        userId: event.userId,
        rating: event.rating,
        comment: event.comment,
      );

      emit(ReviewUpdated(reviewId: event.reviewId));

      log.i('Review updated successfully');

      // Auto-refresh reviews list if we have salon context
      final currentState = state;
      if (currentState is ReviewsLoaded) {
        add(LoadReviews(salonId: currentState.salonId));
      }
    } catch (e, s) {
      log.e('Error updating review', error: e, stackTrace: s);
      emit(ReviewsError(
        message: 'Failed to update review. Please try again.',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // DELETE REVIEW
  //============================================================================

  Future<void> _onDeleteReview(
      DeleteReview event,
      Emitter<ReviewsState> emit,
      ) async {
    try {
      emit(DeletingReview(reviewId: event.reviewId));

      log.i('Deleting review ${event.reviewId}');

      await _reviewsRepository.deleteReview(
        reviewId: event.reviewId,
        userId: event.userId,
      );

      emit(ReviewDeleted(reviewId: event.reviewId));

      log.i('Review deleted successfully');

      // Auto-refresh reviews list if we have salon context
      final currentState = state;
      if (currentState is ReviewsLoaded) {
        add(LoadReviews(salonId: currentState.salonId));
      }
    } catch (e, s) {
      log.e('Error deleting review', error: e, stackTrace: s);
      emit(ReviewsError(
        message: 'Failed to delete review. Please try again.',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // OWNER REPLY
  //============================================================================

  Future<void> _onAddOwnerReply(
      AddOwnerReply event,
      Emitter<ReviewsState> emit,
      ) async {
    try {
      emit(AddingOwnerReply(reviewId: event.reviewId));

      log.i('Adding owner reply to review ${event.reviewId}');

      await _reviewsRepository.addOwnerReply(
        reviewId: event.reviewId,
        salonId: event.salonId,
        ownerId: event.ownerId,
        replyText: event.replyText,
      );

      emit(OwnerReplyAdded(reviewId: event.reviewId));

      log.i('Owner reply added successfully');

      // Auto-refresh to show the reply
      add(LoadReviews(salonId: event.salonId));
    } catch (e, s) {
      log.e('Error adding owner reply', error: e, stackTrace: s);

      String errorMessage = 'Failed to add reply';
      if (e.toString().contains('salon owner')) {
        errorMessage = 'Only the salon owner can reply to reviews';
      }

      emit(ReviewsError(
        message: errorMessage,
        errorCode: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteOwnerReply(
      DeleteOwnerReply event,
      Emitter<ReviewsState> emit,
      ) async {
    try {
      emit(DeletingOwnerReply(reviewId: event.reviewId));

      log.i('Deleting owner reply from review ${event.reviewId}');

      await _reviewsRepository.deleteOwnerReply(
        reviewId: event.reviewId,
        ownerId: event.ownerId,
      );

      emit(OwnerReplyDeleted(reviewId: event.reviewId));

      log.i('Owner reply deleted successfully');

      // Auto-refresh
      final currentState = state;
      if (currentState is ReviewsLoaded) {
        add(LoadReviews(salonId: currentState.salonId));
      }
    } catch (e, s) {
      log.e('Error deleting owner reply', error: e, stackTrace: s);
      emit(ReviewsError(
        message: 'Failed to delete reply. Please try again.',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // HELPFUL VOTING (Future feature)
  //============================================================================

  Future<void> _onMarkReviewHelpful(
      MarkReviewHelpful event,
      Emitter<ReviewsState> emit,
      ) async {
    try {
      await _reviewsRepository.markReviewHelpful(
        reviewId: event.reviewId,
        userId: event.userId,
      );

      log.i('Review ${event.reviewId} marked as helpful');

      // Optionally refresh to show updated count
      final currentState = state;
      if (currentState is ReviewsLoaded) {
        add(LoadReviews(salonId: currentState.salonId));
      }
    } catch (e, s) {
      log.e('Error marking review as helpful', error: e, stackTrace: s);
    }
  }
}