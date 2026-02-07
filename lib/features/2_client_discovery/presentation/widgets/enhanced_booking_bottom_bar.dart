import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/utils/business_hours_utils.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/app/utils/navigation_guard.dart';
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_state.dart';
import 'package:pendeza/shared/models/salon_model.dart';

/// Enhanced booking bottom bar with rating, status indicator, and starting price.
///
/// Features:
/// - Rating display (star + value + count)
/// - Open/Closed status indicator (colored dot)
/// - Starting price: "From TZS X"
/// - Gradient "Book Now" button with calendar icon
/// - Disabled state when closed (grey gradient)
class EnhancedBookingBottomBar extends StatefulWidget {
  final SalonModel salon;

  const EnhancedBookingBottomBar({
    super.key,
    required this.salon,
  });

  @override
  State<EnhancedBookingBottomBar> createState() =>
      _EnhancedBookingBottomBarState();
}

class _EnhancedBookingBottomBarState extends State<EnhancedBookingBottomBar> {
  double? _startingPrice;
  bool _loadingPrice = true;

  @override
  void initState() {
    super.initState();
    _loadStartingPrice();
  }

  Future<void> _loadStartingPrice() async {
    try {
      final services =
          await sl<BookingRepository>().getServicesForSalon(widget.salon.id);
      final activeServices = services.where((s) => s.isActive).toList();

      if (activeServices.isNotEmpty && mounted) {
        final minPrice = activeServices
            .map((s) => s.effectivePrice)
            .reduce((a, b) => a < b ? a : b);
        setState(() {
          _startingPrice = minPrice;
          _loadingPrice = false;
        });
      } else if (mounted) {
        setState(() => _loadingPrice = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingPrice = false);
    }
  }

  void _startBooking(BuildContext context) {
    if (!NavigationDebouncer.shouldNavigate('book_now_${widget.salon.id}')) {
      return;
    }

    context.read<BookingBloc>().add(StartBooking(widget.salon));
    context.push(
      AppRoutes.serviceSelection.replaceFirst(':salonId', widget.salon.id),
      extra: {'salonName': widget.salon.salonName},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHours = widget.salon.hasBusinessHours;
    final status = BusinessHoursUtils.getStatus(
      openingTime: widget.salon.openingTime,
      closingTime: widget.salon.closingTime,
    );
    final isOpen = status == SalonStatus.open || status == SalonStatus.closing;
    final statusColor = BusinessHoursUtils.getStatusColor(status);
    final isBookable = widget.salon.isBookable;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.padL,
            vertical: AppConstants.padM,
          ),
          child: Row(
            children: [
              // Left Side: Info Column
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rating & Status Row
                    Row(
                      children: [
                        // Rating
                        BlocBuilder<ReviewsBloc, ReviewsState>(
                          builder: (context, state) {
                            double rating = 0;
                            int count = 0;

                            if (state is ReviewsLoaded) {
                              rating = state.averageRating;
                              count = state.reviews.length;
                            }

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  CupertinoIcons.star_fill,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rating > 0 ? rating.toStringAsFixed(1) : '-',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (count > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '($count)',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),

                        // Status Indicator (only show when hours are set)
                        if (hasHours) ...[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 1,
                            height: 14,
                            color: theme.colorScheme.outline.withValues(alpha: 0.3),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isOpen ? 'Open' : 'Closed',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Starting Price
                    if (_loadingPrice)
                      SizedBox(
                        height: 16,
                        width: 80,
                        child: Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      )
                    else if (_startingPrice != null)
                      Text(
                        'From ${AppFormatters.formatCurrency(_startingPrice)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: AppConstants.padM),

              // Book Now Button (disabled only for pending approval salons)
              _buildBookButton(context, isBookable),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookButton(BuildContext context, bool isBookable) {
    final theme = Theme.of(context);

    final gradient = isBookable
        ? LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          )
        : LinearGradient(
            colors: [
              Colors.grey.shade400,
              Colors.grey.shade500,
            ],
          );

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: AppConstants.radiusM,
        boxShadow: isBookable
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppConstants.radiusM,
        child: InkWell(
          onTap: isBookable ? () => _startBooking(context) : null,
          borderRadius: AppConstants.radiusM,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.padL,
              vertical: AppConstants.padS,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isBookable
                      ? CupertinoIcons.calendar_badge_plus
                      : CupertinoIcons.clock,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isBookable
                      ? 'client.appointments.book_now'.tr()
                      : 'Pending Approval',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
