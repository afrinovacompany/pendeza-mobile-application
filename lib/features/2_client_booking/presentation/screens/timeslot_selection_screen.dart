import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/utils/navigation_guard.dart';
import '../../../../shared/widgets/client_ui.dart';
import '../../../../shared/widgets/custom_snackbar.dart';
import '../widgets/booking_step_header.dart';
import '../widgets/booking_summary_footer.dart';
import '../widgets/calendar_view.dart';
import '../widgets/time_slot_chip.dart';

class TimeslotSelectionScreen extends StatefulWidget {
  const TimeslotSelectionScreen({super.key});

  @override
  State<TimeslotSelectionScreen> createState() =>
      _TimeslotSelectionScreenState();
}

class _TimeslotSelectionScreenState extends State<TimeslotSelectionScreen>
    with NavigationGuard {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;

  // Keeps the day strip (and its scroll position) alive while the screen swaps
  // between the loading and loaded layouts.
  final GlobalKey _dayPickerKey = GlobalKey();

  @override
  void initState() {
    super.initState();

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
    return Scaffold(
      backgroundColor: ClientTheme.background(context),
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<BookingBloc, BookingState>(
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
            final salonName =
                state is BookingInProgress ? state.salon.salonName : '';

            return Column(
              children: [
                BookingStepHeader(
                  step: 2,
                  title: 'client.booking.select_time_title'.tr(),
                  subtitle: salonName,
                ),
                Expanded(child: _buildBody(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookingState state) {
    if (state is BookingFailure) {
      return ClientEmptyState(
        icon: CupertinoIcons.exclamationmark_circle,
        title: 'common.oops'.tr(),
        message: state.error,
        color: const Color(0xFFEF4444),
      );
    }

    if (state is BookingInProgress &&
        state.status == BookingStatus.selectingServices) {
      return _buildLoadingStateWithCalendar(context);
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
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(top: 18, bottom: 24),
              children: [
                _buildDateSection(context),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ClientTheme.gutter,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'client.booking.available_slots'.tr(),
                        style: ClientTheme.title(context),
                      ),
                      if (totalDurationMinutes > 0) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.time,
                              size: 13,
                              color: ClientTheme.textSecondary(context),
                            ),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'client.booking.est_duration'
                                    .tr(args: ['$totalDurationMinutes']),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: ClientTheme.caption(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (availableTimeSlots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClientEmptyState(
                      icon: CupertinoIcons.calendar_badge_minus,
                      title: 'client.booking.no_slots'.tr(),
                      message: 'client.booking.no_slots_hint'.tr(),
                      color: const Color(0xFFF5A623),
                    ),
                  )
                else
                  _SlotGroups(
                    slots: availableTimeSlots,
                    selected: _selectedTimeSlot,
                    onSelected: _onTimeSlotSelectedInUI,
                  ),
              ],
            ),
          ),
          _buildFooter(state),
        ],
      );
    }
    return _buildLoadingStateWithCalendar(context);
  }

  Widget _buildDateSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 2,
            children: [
              Text(
                'client.booking.choose_date'.tr(),
                style: ClientTheme.title(context),
              ),
              Text(
                DateFormat.yMMMM().format(_selectedDate),
                style: ClientTheme.caption(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        HorizontalDayPicker(
          key: _dayPickerKey,
          selectedDate: _selectedDate,
          onDateSelected: _onDateSelectedInUI,
        ),
      ],
    );
  }

  Widget _buildLoadingStateWithCalendar(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 18),
          child: _buildDateSection(context),
        ),
        const Expanded(
          child: Center(child: CircularProgressIndicator()),
        ),
        _buildFooter(null),
      ],
    );
  }

  Widget _buildFooter(BookingInProgress? state) {
    final slot = _selectedTimeSlot;
    final canContinue = state != null && slot != null;

    return BookingSummaryFooter(
      totalPrice: state?.totalPrice ?? 0.0,
      totalDurationMinutes: 0,
      label: 'client.booking.total_payable'.tr(),
      caption: slot != null
          ? '${DateFormat('EEE, MMM d').format(_selectedDate)} • $slot'
          : 'client.booking.pick_time_hint'.tr(),
      buttonText: 'client.booking.review_btn'.tr(),
      buttonIcon: CupertinoIcons.arrow_right,
      onButtonPressed: canContinue ? () => _proceedToConfirmation(state) : null,
    );
  }
}

/// Time slots grouped into Morning / Afternoon / Evening. Falls back to one
/// flat list when a slot is not "HH:mm".
class _SlotGroups extends StatelessWidget {
  final List<String> slots;
  final String? selected;
  final ValueChanged<String> onSelected;

  const _SlotGroups({
    required this.slots,
    required this.selected,
    required this.onSelected,
  });

  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final groups = _group(slots);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth - ClientTheme.gutter * 2;
        final columns = available >= 260 ? 3 : 2;
        final chipWidth = (available - _gap * (columns - 1)) / columns;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final group in groups) ...[
                if (group.label != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          group.icon,
                          size: 16,
                          color: ClientTheme.textSecondary(context),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          group.label!.toUpperCase(),
                          style: ClientTheme.label(context),
                        ),
                      ],
                    ),
                  ),
                Wrap(
                  spacing: _gap,
                  runSpacing: _gap,
                  children: [
                    for (final slot in group.slots)
                      SizedBox(
                        width: chipWidth,
                        child: TimeSlotChip(
                          slot: slot,
                          isSelected: slot == selected,
                          onTap: () => onSelected(slot),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
              ],
            ],
          ),
        );
      },
    );
  }

  List<_SlotGroup> _group(List<String> slots) {
    final hours = <int>[];
    for (final slot in slots) {
      final hour = int.tryParse(slot.split(':').first.trim());
      if (hour == null || !slot.contains(':')) {
        return [_SlotGroup(null, null, slots)];
      }
      hours.add(hour);
    }

    final morning = <String>[];
    final afternoon = <String>[];
    final evening = <String>[];
    for (var i = 0; i < slots.length; i++) {
      final hour = hours[i];
      if (hour < 12) {
        morning.add(slots[i]);
      } else if (hour < 17) {
        afternoon.add(slots[i]);
      } else {
        evening.add(slots[i]);
      }
    }

    return [
      if (morning.isNotEmpty)
        _SlotGroup(
          'client.booking.morning'.tr(),
          CupertinoIcons.sunrise_fill,
          morning,
        ),
      if (afternoon.isNotEmpty)
        _SlotGroup(
          'client.booking.afternoon'.tr(),
          CupertinoIcons.sun_max_fill,
          afternoon,
        ),
      if (evening.isNotEmpty)
        _SlotGroup(
          'client.booking.evening'.tr(),
          CupertinoIcons.sunset_fill,
          evening,
        ),
    ];
  }
}

class _SlotGroup {
  final String? label;
  final IconData? icon;
  final List<String> slots;

  const _SlotGroup(this.label, this.icon, this.slots);
}
