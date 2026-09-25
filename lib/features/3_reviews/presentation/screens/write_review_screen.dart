import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
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
    return BlocProvider(
      create: (context) => sl<ReviewsBloc>(),
      child: Scaffold(
        backgroundColor: ClientTheme.background(context),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ClientPageHeader(
                title: isEditMode
                    ? 'client.salon_details.edit_review'.tr()
                    : 'client.salon_details.write_review'.tr(),
                subtitle: widget.salon.salonName,
              ),
              Expanded(
                child: BlocConsumer<ReviewsBloc, ReviewsState>(
                  listener: (context, state) {
                    if (state is ReviewSubmitted || state is ReviewUpdated) {
                      // SUCCESS SNACKBAR
                      CustomSnackBar.show(
                        context,
                        message: state is ReviewSubmitted
                            ? state.message
                            : (state as ReviewUpdated).message,
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
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.fromLTRB(
                        ClientTheme.gutter,
                        20,
                        ClientTheme.gutter,
                        24 + MediaQuery.paddingOf(context).bottom,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSalonInfoCard(context),
                            const SizedBox(height: 16),
                            _buildRatingCard(context),
                            const SizedBox(height: 16),
                            _buildCommentField(context),
                            const SizedBox(height: 26),
                            ClientPrimaryButton(
                              text: isEditMode
                                  ? 'client.salon_details.update_review'.tr()
                                  : 'client.salon_details.submit_review'.tr(),
                              icon: CupertinoIcons.paperplane_fill,
                              isLoading: _isSubmitting,
                              onPressed: _rating > 0
                                  ? () => _handleSubmit(context)
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed:
                                  _isSubmitting ? null : () => context.pop(),
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 48),
                                foregroundColor:
                                    ClientTheme.textSecondary(context),
                                textStyle: const TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text('common.cancel'.tr()),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //============================================================================
  // SALON INFO CARD
  //============================================================================

  Widget _buildSalonInfoCard(BuildContext context) {
    return ClientCard(
      radius: 22,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const ClientIconTile(
            icon: CupertinoIcons.scissors,
            color: AppColors.primary,
            size: 46,
            solid: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.salon.salonName,
                  style: ClientTheme.body(context).copyWith(
                    fontWeight: FontWeight.w700,
                    color: ClientTheme.textPrimary(context),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.salon.address,
                  style: ClientTheme.caption(context),
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
  // RATING CARD
  //============================================================================

  String _ratingLabel(double rating) {
    if (rating == 0) return 'client.salon_details.rating_tap'.tr();
    final step = rating.ceil().clamp(1, 5);
    return 'client.salon_details.rating_$step'.tr();
  }

  Widget _buildRatingCard(BuildContext context) {
    final accent = ClientTheme.isDark(context)
        ? Theme.of(context).colorScheme.primary
        : AppColors.primaryDark;

    return ClientCard(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Column(
        children: [
          Text(
            'client.salon_details.rate_prompt'.tr(),
            textAlign: TextAlign.center,
            style: ClientTheme.title(context),
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RatingStars.input(
              initialRating: _rating,
              size: 44,
              onRatingChanged: (rating) {
                setState(() {
                  _rating = rating;
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _ratingLabel(_rating),
              key: ValueKey(_rating),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _rating == 0
                    ? ClientTheme.textSecondary(context)
                    : accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  //============================================================================
  // COMMENT FIELD
  //============================================================================

  Widget _buildCommentField(BuildContext context) {
    return ClientCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'client.salon_details.comment_title'.tr(),
            style: ClientTheme.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: ClientTheme.textPrimary(context),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            maxLines: 5,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'client.salon_details.comment_hint'.tr(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
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
        message: 'client.salon_details.select_rating'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;

    if (authState is! Authenticated) {
      // ERROR SNACKBAR
      CustomSnackBar.show(
        context,
        message: 'client.salon_details.sign_in_required'.tr(),
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
