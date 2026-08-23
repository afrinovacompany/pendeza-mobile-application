import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/utils/formatters.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../widgets/calendar_view.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../../../../app/utils/navigation_guard.dart';

class TimeslotSelectionScreen extends StatefulWidget {
  const TimeslotSelectionScreen({super.key});

  @override
  State<TimeslotSelectionScreen> createState() =>
      _TimeslotSelectionScreenState();
}

class _TimeslotSelectionScreenState extends State<TimeslotSelectionScreen>
    with SingleTickerProviderStateMixin, NavigationGuard {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    final currentState = context.read<BookingBloc>().state;
    if (currentState is BookingInProgress) {
      _selectedDate = currentState.selectedDate ?? DateTime.now();
      _selectedTimeSlot = currentState.selectedTimeSlot;

      if (currentState.selectedDate != null &&
          currentState.status != BookingStatus.selectingTime &&
          currentState.status != BookingStatus.reviewing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<BookingBloc>().add(FetchTimeSlots());
        });
      } else if (currentState.selectedDate == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<BookingBloc>().add(DateSelected(_selectedDate));
        });
      }
    } else {
      _selectedDate = DateTime.now();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<BookingBloc>().add(DateSelected(_selectedDate));
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onDateSelectedInUI(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _selectedTimeSlot = null;
    });
    context.read<BookingBloc>().add(DateSelected(newDate));
  }

  void _onTimeSlotSelectedInUI(String timeSlot) {
    setState(() {
      _selectedTimeSlot = timeSlot;
    });
    context.read<BookingBloc>().add(TimeSlotSelected(timeSlot));
  }

  void _proceedToConfirmation(BookingInProgress state) {
    if (_selectedTimeSlot == null) {
      CustomSnackBar.show(
        context,
        message: 'client.booking.error_no_time'.tr(),
        type: SnackBarType.warning,
      );
      return;
    }

    // Prevent double navigation on rapid button taps
    guardedNavigate(() {
      // Navigate without extra — confirmation screen reads from BLoC state
      context.push(
        AppRoutes.bookingConfirmation.replaceFirst(':salonId', state.salon.id),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('client.booking.select_time_title'.tr()),
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingInProgress &&
              state.status == BookingStatus.failure &&
              state.errorMessage != null) {
            CustomSnackBar.show(
              context,
              message: 'Error: ${state.errorMessage}',
              type: SnackBarType.error,
            );
          }
        },
        builder: (context, state) {
          if (state is BookingFailure) {
            return EmptyStateWidget.error(message: state.error);
          }

          if (state is BookingInProgress &&
              state.status == BookingStatus.selectingServices) {
            return _buildLoadingStateWithCalendar(context, _selectedDate);
          }

          if (state is BookingInProgress &&
              (state.status == BookingStatus.selectingTime ||
                  state.status == BookingStatus.reviewing)) {
            final availableTimeSlots = state.availableTimeSlots;
            final totalDurationMinutes = state.totalDurationMinutes;

            _selectedDate = state.selectedDate ?? _selectedDate;
            _selectedTimeSlot = state.selectedTimeSlot ?? _selectedTimeSlot;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 140),
                    children: [
                      const SizedBox(height: AppConstants.padL),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.padL),
                        child: Text(
                          'client.booking.choose_date'.tr(),
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.padM),
                      HorizontalDayPicker(
                        selectedDate: _selectedDate,
                        onDateSelected: _onDateSelectedInUI,
                      ),
                      const SizedBox(height: AppConstants.padXL),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.padL),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'client.booking.available_slots'.tr(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (totalDurationMinutes > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.padM,
                                  vertical: AppConstants.padXS,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.time,
                                      size: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'client.booking.est_duration'
                                          .tr(args: ['$totalDurationMinutes']),
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.padM),
                      availableTimeSlots.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.padL,
                            vertical: AppConstants.padXL),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.calendar_badge_minus,
                                size: 48,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: AppConstants.padM),
                              Text(
                                'client.booking.no_slots'.tr(),
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                          : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.padL),
                        child: Wrap(
                          spacing: AppConstants.padS,
                          runSpacing: AppConstants.padS,
                          children: availableTimeSlots.map((slot) {
                            final isSelected = slot == _selectedTimeSlot;
                            return _EnhancedTimeSlotChip(
                              slot: slot,
                              isSelected: isSelected,
                              onTap: () => _onTimeSlotSelectedInUI(slot),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildEnhancedFooter(theme, state),
              ],
            );
          }
          return _buildLoadingStateWithCalendar(context, _selectedDate);
        },
      ),
    );
  }

  Widget _buildLoadingStateWithCalendar(
      BuildContext context, DateTime currentDate) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const SizedBox(height: AppConstants.padL),
        Padding(
          padding:
          const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          child: Text(
            'client.booking.choose_date'.tr(),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: AppConstants.padS),
        HorizontalDayPicker(
          selectedDate: currentDate,
          onDateSelected: _onDateSelectedInUI,
        ),
        const SizedBox(height: AppConstants.padXL),
        const Expanded(
          child: Center(child: CircularProgressIndicator()),
        ),
        _buildEnhancedFooter(theme, null, isDisabled: true),
      ],
    );
  }

  Widget _buildEnhancedFooter(ThemeData theme, BookingInProgress? state,
      {bool isDisabled = false}) {
    final totalPrice = state?.totalPrice ?? 0.0;
    final isTimeSlotSelected = _selectedTimeSlot != null;

    return AnimatedContainer(
      duration: AppConstants.durationMedium,
      margin: isTimeSlotSelected && !isDisabled
          ? const EdgeInsets.all(AppConstants.padL)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: theme.brightness == Brightness.light
            ? AppColors.lightShadowLg
            : AppColors.darkShadowLg,
        borderRadius: isTimeSlotSelected && !isDisabled
            ? BorderRadius.circular(AppConstants.radiusValL)
            : const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusValL),
          topRight: Radius.circular(AppConstants.radiusValL),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'client.booking.total_payable'.tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppFormatters.formatCurrency(totalPrice),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.padM),
              Expanded(
                flex: 3,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isTimeSlotSelected && !isDisabled
                          ? 1.0 + (_pulseController.value * 0.02)
                          : 1.0,
                      child: child,
                    );
                  },
                  child: PrimaryGradientButton(
                    text: 'client.booking.review_btn'.tr(),
                    onPressed: isDisabled || !isTimeSlotSelected || state == null
                        ? null
                        : () => _proceedToConfirmation(state),
                    iconData: CupertinoIcons.arrow_right,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EnhancedTimeSlotChip extends StatefulWidget {
  final String slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnhancedTimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_EnhancedTimeSlotChip> createState() => _EnhancedTimeSlotChipState();
}

class _EnhancedTimeSlotChipState extends State<_EnhancedTimeSlotChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppConstants.durationFast,
      value: widget.isSelected ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(_EnhancedTimeSlotChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _scaleController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_scaleController.value * 0.03),
          child: child,
        );
      },
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: AppConstants.radiusM,
        child: AnimatedContainer(
          duration: AppConstants.durationFast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.padL,
            vertical: AppConstants.padM,
          ),
          decoration: BoxDecoration(
            color: widget.isSelected ? colorScheme.primary : theme.cardColor,
            borderRadius: AppConstants.radiusM,
            border: Border.all(
              color: widget.isSelected
                  ? colorScheme.primary
                  : theme.dividerColor.withValues(alpha: 0.3),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : [],
          ),
          child: Text(
            widget.slot,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: widget.isSelected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface,
              fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}