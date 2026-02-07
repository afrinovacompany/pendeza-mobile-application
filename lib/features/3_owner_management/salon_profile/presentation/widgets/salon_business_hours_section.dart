import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import '../bloc/salon_profile_bloc.dart';
import '../dialogs/edit_hours_dialog.dart';

class SalonBusinessHoursSection extends StatelessWidget {
  final SalonModel salon;

  const SalonBusinessHoursSection({
    super.key,
    required this.salon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Business Hours',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showEditDialog(context),
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: AppConstants.padM),
        CustomCard(
          child: Column(
            children: [
              _buildDayRow(
                context,
                day: 'Monday - Friday',
                time: salon.hasBusinessHours
                    ? '${salon.openingTime} - ${salon.closingTime}'
                    : 'Not set',
                isClosed: !salon.hasBusinessHours,
              ),
              const Divider(height: AppConstants.padL),
              _buildDayRow(
                context,
                day: 'Saturday',
                time: salon.hasBusinessHours
                    ? '${salon.openingTime} - ${salon.closingTime}'
                    : 'Not set',
                isClosed: !salon.hasBusinessHours,
              ),
              const Divider(height: AppConstants.padL),
              _buildDayRow(
                context,
                day: 'Sunday',
                time: 'Closed',
                isClosed: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(
      BuildContext context, {
        required String day,
        required String time,
        bool isClosed = false,
      }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          day,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          time,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isClosed
                ? theme.colorScheme.error
                : theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SalonProfileBloc>(),
        child: EditHoursDialog(salon: salon),
      ),
    );
  }
}