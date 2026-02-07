import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/app/services/service_locator.dart';

import '../../../3_reviews/data/repositories/reviews_repository_impl.dart';

class SalonBookingBottomBar extends StatefulWidget {
  final SalonModel salon;

  const SalonBookingBottomBar({super.key, required this.salon});

  @override
  State<SalonBookingBottomBar> createState() => _SalonBookingBottomBarState();
}

class _SalonBookingBottomBarState extends State<SalonBookingBottomBar> {
  double _averageRating = 0.0;
  int _totalReviews = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRatings();
  }

  Future<void> _fetchRatings() async {
    try {
      final reviewsRepo = sl<ReviewsRepository>();
      final avg = await reviewsRepo.getAverageRating(salonId: widget.salon.id);
      final count = await reviewsRepo.getReviewCount(salonId: widget.salon.id);
      if (mounted) {
        setState(() {
          _averageRating = avg;
          _totalReviews = count;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startBooking(BuildContext context) {
    context.read<BookingBloc>().add(StartBooking(widget.salon));
    context.push(
      AppRoutes.serviceSelection.replaceFirst(':salonId', widget.salon.id),
      extra: {'salonName': widget.salon.salonName},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Rating Display
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                  // Simple text shimmer or loader could go here, but keeping it minimal
                    const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Row(
                      children: [
                        const Icon(CupertinoIcons.star_fill, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          ' ($_totalReviews)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppConstants.padM),

            // Book Now Button
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: () => _startBooking(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppConstants.radiusL,
                  ),
                  elevation: 4,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
                child: const Text(
                  'Book Now',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}