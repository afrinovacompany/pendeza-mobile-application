import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/app/utils/business_hours_utils.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/app/utils/navigation_guard.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_bloc.dart';
import 'package:pendeza/features/3_reviews/presentation/bloc/reviews_state.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

/// Bottom bar of the salon details screen: rating, open/closed status,
/// starting price and the gradient "Book now" button.
class EnhancedBookingBottomBar extends StatefulWidget {
  final SalonModel salon;
  final List<ServiceModel>? services;
  final bool servicesLoading;

  const EnhancedBookingBottomBar({
    super.key,
    required this.salon,
    this.services,
    this.servicesLoading = false,
  });

  @override
  State<EnhancedBookingBottomBar> createState() =>
      _EnhancedBookingBottomBarState();
}

class _EnhancedBookingBottomBarState extends State<EnhancedBookingBottomBar> {
  double? get _startingPrice {
    final services = widget.services;
    if (services == null || services.isEmpty) return null;
    return services
        .map((s) => s.effectivePrice)
        .reduce((a, b) => a < b ? a : b);
  }

  bool get _loadingPrice => widget.servicesLoading;

  bool get _hasNoServices =>
      !widget.servicesLoading && (widget.services?.isEmpty ?? true);

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
    final cs = Theme.of(context).colorScheme;
    final isDark = ClientTheme.isDark(context);
    final hasHours = widget.salon.hasBusinessHours;
    final status = BusinessHoursUtils.getStatus(
      openingTime: widget.salon.openingTime,
      closingTime: widget.salon.closingTime,
    );
    final isOpen = status == SalonStatus.open || status == SalonStatus.closing;
    final statusColor = BusinessHoursUtils.getStatusColor(status);
    final canBook = widget.salon.isBookable && !_hasNoServices;

    return Container(
      decoration: BoxDecoration(
        color: ClientTheme.card(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: ClientTheme.border(context))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.15,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            _buildRating(context),
                            if (hasHours) ...[
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                width: 1,
                                height: 14,
                                color: ClientTheme.border(context),
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
                                isOpen
                                    ? 'client.salon_details.open'.tr()
                                    : 'client.salon_details.closed'.tr(),
                                style: ClientTheme.caption(context).copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_loadingPrice)
                        Container(
                          height: 16,
                          width: 90,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                      else if (_startingPrice != null)
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '${'client.salon_details.from'.tr()} ',
                                style: ClientTheme.caption(context),
                              ),
                              TextSpan(
                                text: AppFormatters.formatCurrency(
                                  _startingPrice,
                                ),
                                style: TextStyle(
                                  fontFamily: AppTextStyles.fontFamily,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color:
                                      isDark
                                          ? cs.primary
                                          : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else if (_hasNoServices)
                        Text(
                          'client.salon_details.no_services_yet'.tr(),
                          style: ClientTheme.caption(context),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                _buildBookButton(context, canBook),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRating(BuildContext context) {
    return BlocBuilder<ReviewsBloc, ReviewsState>(
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
              color: Color(0xFFF5A623),
            ),
            const SizedBox(width: 4),
            Text(
              rating > 0 ? rating.toStringAsFixed(1) : '-',
              style: ClientTheme.body(
                context,
              ).copyWith(fontWeight: FontWeight.w700),
            ),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Text('($count)', style: ClientTheme.caption(context)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBookButton(BuildContext context, bool enabled) {
    final cs = Theme.of(context).colorScheme;
    final muted = ClientTheme.textSecondary(context);
    final label =
        !widget.salon.isBookable
            ? 'client.salon_details.pending_approval'.tr()
            : _hasNoServices
            ? 'client.salon_details.unavailable'.tr()
            : 'client.appointments.book_now'.tr();

    return Container(
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.primaryGradient : null,
        color: enabled ? null : cs.onSurface.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        boxShadow:
            enabled
                ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ]
                : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? () => _startBooking(context) : null,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  enabled
                      ? CupertinoIcons.calendar_badge_plus
                      : CupertinoIcons.clock,
                  color: enabled ? Colors.white : muted,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: enabled ? Colors.white : muted,
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
