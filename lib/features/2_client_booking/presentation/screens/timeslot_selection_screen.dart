
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import 'package:pendeza/shared/models/staff_model.dart';
import '../../../../app/config/app_router.dart';
import '../../../../app/config/theme/app_colors.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/utils/formatters.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../widgets/calendar_view.dart';
import 'booking_confirmation_screen.dart';

class TimeslotSelectionScreen extends StatefulWidget {
  const TimeslotSelectionScreen({super.key});

  @override
  State<TimeslotSelectionScreen> createState() =>
      _TimeslotSelectionScreenState();
}

class _TimeslotSelectionScreenState extends State<TimeslotSelectionScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;

  void _selectDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _selectedTimeSlot = null; // Clear time slot when date changes
    });
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      _selectedTimeSlot = timeSlot;
    });
  }

  void _proceedToConfirmation(BookingInProgress state) {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a time slot to continue.')),
      );
      return;
    }

    final timeParts = DateFormat.jm().parse(_selectedTimeSlot!);
    final appointmentDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      timeParts.hour,
      timeParts.minute,
    );

    context.read<BookingBloc>().add(SelectDateTime(appointmentDateTime));

    final bookingDetails = BookingDetailsArguments(
      salonName: state.salon.salonName,
      services: state.selectedServices,
      // --- CHANGE IS HERE: Use a placeholder for "Any Staff" ---
      staff: const StaffModel(
        id: 'any_available',
        salonId: '',
        name: 'Any Available Staff',
        role: 'Best available',
        serviceIds: [],
      ),
      appointmentDateTime: appointmentDateTime,
    );

    context.push(
      AppRoutes.bookingConfirmation,
      extra: bookingDetails,
    );
  }

  List<String> _getAvailableTimeSlots(DateTime date) {
    final slots = <String>[];
    for (int hour = 9; hour < 17; hour++) {
      slots.add(DateFormat.jm().format(DateTime(date.year, date.month, date.day, hour, 0)));
      slots.add(DateFormat.jm().format(DateTime(date.year, date.month, date.day, hour, 30)));
    }

    if (date.day == DateTime.now().day && date.month == DateTime.now().month) {
      final now = DateTime.now();
      return slots.where((slot) {
        final slotTime = DateFormat.jm().parse(slot);
        final fullSlotDateTime = DateTime(now.year, now.month, now.day, slotTime.hour, slotTime.minute);
        return fullSlotDateTime.isAfter(now);
      }).toList();
    }

    return slots;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Date & Time'),
      ),
      body: BlocBuilder<BookingBloc, BookingState>(
        builder: (context, state) {
          if (state is BookingInProgress) {
            final availableTimeSlots = _getAvailableTimeSlots(_selectedDate);
            final totalDurationMinutes = state.selectedServices
                .fold(0, (sum, service) => sum + service.durationMinutes);

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 120),
                    children: [
                      const SizedBox(height: AppConstants.padL),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                        child: Text(
                          'Choose Date',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: AppConstants.padS),
                      HorizontalDayPicker(
                        selectedDate: _selectedDate,
                        onDateSelected: _selectDate,
                      ),
                      const SizedBox(height: AppConstants.padXL),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Available Time Slots',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Duration: $totalDurationMinutes min',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppConstants.padM),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                        child: Text(
                          "Note: Availability will be confirmed by the salon after booking.",
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      ),
                      const SizedBox(height: AppConstants.padM),
                      availableTimeSlots.isEmpty
                          ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                        child: Text(
                          'No slots available for this day.',
                          style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      )
                          : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                        child: Wrap(
                          spacing: AppConstants.padS,
                          runSpacing: AppConstants.padS,
                          children: availableTimeSlots.map((slot) {
                            final isSelected = slot == _selectedTimeSlot;
                            return _TimeSlotChip(
                              slot: slot,
                              isSelected: isSelected,
                              onTap: () => _selectTimeSlot(slot),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildFloatingFooter(theme, state),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildFloatingFooter(ThemeData theme, BookingInProgress state) {
    final totalPrice = state.selectedServices.fold(0.0, (sum, service) => sum + service.price);

    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: theme.brightness == Brightness.light ? AppColors.lightShadowMd : AppColors.darkShadowMd,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.padL),
          topRight: Radius.circular(AppConstants.padL),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total Payable:',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              Text(
                AppFormatters.formatCurrency(totalPrice),
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: PrimaryGradientButton(
              text: 'REVIEW BOOKING',
              onPressed: _selectedTimeSlot == null ? null : () => _proceedToConfirmation(state),
              iconData: CupertinoIcons.arrow_right,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSlotChip extends StatelessWidget {
  final String slot;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeSlotChip({
    required this.slot,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final containerColor = isSelected ? colorScheme.primary : theme.cardColor;
    final textColor = isSelected ? Colors.white : colorScheme.onSurface;
    final borderColor = isSelected ? colorScheme.primary : theme.dividerColor;

    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.radiusM,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padM, vertical: AppConstants.padS),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: AppConstants.radiusM,
          border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.0),
        ),
        child: Text(
          slot,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
