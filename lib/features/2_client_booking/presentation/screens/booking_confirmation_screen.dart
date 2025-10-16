import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/models/staff_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart';


class BookingDetailsArguments {
  final String salonName;
  final List<ServiceModel> services;
  final StaffModel staff;
  final DateTime appointmentDateTime;

  const BookingDetailsArguments({
    required this.salonName,
    required this.services,
    required this.staff,
    required this.appointmentDateTime,
  });

  double get totalPrice =>
      services.fold(0.0, (sum, service) => sum + service.price);
  int get totalDuration =>
      services.fold(0, (sum, service) => sum + service.durationMinutes);
}

class BookingConfirmationScreen extends StatelessWidget {
  final BookingDetailsArguments bookingDetails;

  const BookingConfirmationScreen({
    super.key,
    required this.bookingDetails,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Your Booking'),
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          if (state is BookingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Booking Confirmed Successfully!')));
            context.pop();
          }
          if (state is BookingFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Error: ${state.error}'),
                backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          final isLoading =
              state is BookingInProgress && state.status == BookingStatus.loading;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppConstants.padL),
                  children: [
                    _buildAppointmentSummaryCard(context),
                    const SizedBox(height: AppConstants.padXL),
                    _buildSectionTitle(context, 'Booking Summary'),
                    const SizedBox(height: AppConstants.padS),
                    ...bookingDetails.services
                        .map((service) => _buildServiceTile(context, service)),
                    const Divider(height: AppConstants.padL),
                    _buildTotalRow(context, 'Total Duration',
                        '${bookingDetails.totalDuration} min'),
                    const SizedBox(height: AppConstants.padXL),
                    _buildSectionTitle(context, 'Your Stylist'),
                    const SizedBox(height: AppConstants.padS),
                    _buildStaffTile(context),
                  ],
                ),
              ),
              _buildFloatingFooter(
                  context, theme, bookingDetails.totalPrice, isLoading),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildAppointmentSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    return CustomCard(
      padding: const EdgeInsets.all(AppConstants.padL),
      color: theme.colorScheme.primary.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            bookingDetails.salonName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: AppConstants.padM),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.calendar_today,
            value: DateFormat.yMMMMEEEEd()
                .format(bookingDetails.appointmentDateTime),
          ),
          const SizedBox(height: AppConstants.padS),
          _buildDetailRow(
            context,
            icon: CupertinoIcons.time,
            value: DateFormat.jm().format(bookingDetails.appointmentDateTime),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context,
      {required IconData icon, required String value}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppConstants.padM),
        Text(value,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildServiceTile(BuildContext context, ServiceModel service) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.padXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(service.name, style: theme.textTheme.bodyLarge)),
          const SizedBox(width: AppConstants.padS),
          Text(
            AppFormatters.formatCurrency(service.price),
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(BuildContext context, String title, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.padXS),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.bodyLarge),
          Text(value,
              style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStaffTile(BuildContext context) {
    final theme = Theme.of(context);
    final staff = bookingDetails.staff;
    return CustomCard(
      child: Row(
        children: [
          // --- CHANGE IS HERE: Conditionally show icon or avatar ---
          if (staff.id == 'any_available')
            Icon(Icons.person_search_rounded,
                color: theme.colorScheme.primary, size: 40)
          else
            ProfileAvatar(fullName: staff.name, radius: 24),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text(staff.role,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingFooter(
      BuildContext context, ThemeData theme, double totalPrice, bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: theme.brightness == Brightness.light
            ? AppColors.lightShadowMd
            : AppColors.darkShadowMd,
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
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.7)),
              ),
              Text(
                AppFormatters.formatCurrency(totalPrice),
                style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary),
              ),
            ],
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: PrimaryGradientButton(
              text: 'CONFIRM & PAY',
              isLoading: isLoading,
              onPressed: isLoading
                  ? null
                  : () {
                context.read<BookingBloc>().add(ConfirmBooking());
              },
              iconData: CupertinoIcons.check_mark_circled_solid,
            ),
          ),
        ],
      ),
    );
  }
}
