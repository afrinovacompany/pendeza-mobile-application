import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import '../../data/models/review_model.dart';
import '../bloc/reviews_bloc.dart';
import '../bloc/reviews_event.dart';
import '../bloc/reviews_state.dart';
import '../widgets/rating_stars_widget.dart';
import '../../../../shared/widgets/custom_snackbar.dart'; // Import the new snackbar

/// Screen for writing a new review or editing an existing one.
class WriteReviewScreen extends StatefulWidget {
  final SalonModel salon;
  final ReviewModel? existingReview; // If editing

  const WriteReviewScreen({
    super.key,
    required this.salon,
    this.existingReview,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  double _rating = 0;
  bool _isSubmitting = false;

  bool get isEditMode => widget.existingReview != null;

  @override
  void initState() {
    super.initState();

    // Pre-fill if editing
    if (isEditMode) {
      _rating = widget.existingReview!.rating;
      _commentController.text = widget.existingReview!.comment;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => sl<ReviewsBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEditMode ? 'Edit Review' : 'Write a Review'),
          centerTitle: true,
        ),
        body: BlocConsumer<ReviewsBloc, ReviewsState>(
          listener: (context, state) {
            if (state is ReviewSubmitted || state is ReviewUpdated) {
              // SUCCESS SNACKBAR
              CustomSnackBar.show(
                context,
                message: state is ReviewSubmitted ? state.message : (state as ReviewUpdated).message,
                type: SnackBarType.success,
              );

              // Go back
              context.pop();
            }

            if (state is ReviewsError) {
              // ERROR SNACKBAR
              CustomSnackBar.show(
                context,
                message: state.message,
                type: SnackBarType.error,
              );

              setState(() {
                _isSubmitting = false;
              });
            }

            if (state is SubmittingReview || state is UpdatingReview) {
              setState(() {
                _isSubmitting = true;
              });
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.padL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Salon info card
                    _buildSalonInfoCard(theme),

                    const SizedBox(height: AppConstants.padXL),

                    // Rating input
                    RatingInput(
                      initialRating: _rating,
                      label: 'How was your experience?',
                      onRatingChanged: (rating) {
                        setState(() {
                          _rating = rating;
                        });
                      },
                    ),

                    const SizedBox(height: AppConstants.padXL),

                    // Comment input
                    _buildCommentField(theme),

                    const SizedBox(height: AppConstants.padXXL),

                    // Submit button
                    _buildSubmitButton(context, theme),

                    // Cancel button
                    const SizedBox(height: AppConstants.padM),
                    _buildCancelButton(context, theme),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  //============================================================================
  // SALON INFO CARD
  //============================================================================

  Widget _buildSalonInfoCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: AppConstants.radiusL,
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.store_rounded,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.salon.salonName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.salon.address,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //============================================================================
  // COMMENT FIELD
  //============================================================================

  Widget _buildCommentField(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share your thoughts (optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.padM),
        TextFormField(
          controller: _commentController,
          maxLines: 6,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Tell others about your experience...',
            border: OutlineInputBorder(
              borderRadius: AppConstants.radiusL,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppConstants.radiusL,
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  //============================================================================
  // SUBMIT BUTTON
  //============================================================================

  Widget _buildSubmitButton(BuildContext context, ThemeData theme) {
    final canSubmit = _rating > 0 && !_isSubmitting;

    return ElevatedButton(
      onPressed: canSubmit ? () => _handleSubmit(context) : null,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: AppConstants.radiusL,
        ),
      ),
      child: _isSubmitting
          ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
          : Text(
        isEditMode ? 'Update Review' : 'Submit Review',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  //============================================================================
  // CANCEL BUTTON
  //============================================================================

  Widget _buildCancelButton(BuildContext context, ThemeData theme) {
    return TextButton(
      onPressed: _isSubmitting ? null : () => context.pop(),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: const Text('Cancel'),
    );
  }

  //============================================================================
  // SUBMIT HANDLER
  //============================================================================

  void _handleSubmit(BuildContext context) {
    if (_rating == 0) {
      // WARNING SNACKBAR
      CustomSnackBar.show(
        context,
        message: 'Please select a star rating',
        type: SnackBarType.warning,
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated) {
      // ERROR SNACKBAR
      CustomSnackBar.show(
        context,
        message: 'You must be signed in to leave a review',
        type: SnackBarType.error,
      );
      return;
    }

    final user = authState.user;

    if (isEditMode) {
      // Update existing review
      context.read<ReviewsBloc>().add(
        UpdateReview(
          reviewId: widget.existingReview!.id,
          userId: user.uid,
          rating: _rating,
          comment: _commentController.text.trim(),
        ),
      );
    } else {
      // Submit new review
      context.read<ReviewsBloc>().add(
        SubmitReview(
          salonId: widget.salon.id,
          userId: user.uid,
          userName: user.fullName,
          userProfilePicture: user.profilePictureUrl,
          rating: _rating,
          comment: _commentController.text.trim(),
        ),
      );
    }
  }
}