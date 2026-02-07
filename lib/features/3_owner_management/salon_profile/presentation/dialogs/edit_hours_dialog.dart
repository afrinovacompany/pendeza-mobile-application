import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import '../bloc/salon_profile_bloc.dart';
import '../bloc/salon_profile_event.dart';

class EditHoursDialog extends StatefulWidget {
  final SalonModel salon;

  const EditHoursDialog({
    super.key,
    required this.salon,
  });

  @override
  State<EditHoursDialog> createState() => _EditHoursDialogState();
}

class _EditHoursDialogState extends State<EditHoursDialog> {
  late TimeOfDay _openingTime;
  late TimeOfDay _closingTime;

  @override
  void initState() {
    super.initState();
    _openingTime = _parseTime(widget.salon.openingTime);
    _closingTime = _parseTime(widget.salon.closingTime);
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectTime(BuildContext context, bool isOpening) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? _openingTime : _closingTime,
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Business Hours',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.padL),

              // Opening Time
              Text(
                'Opening Time',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppConstants.padXS),
              InkWell(
                onTap: () => _selectTime(context, true),
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.padM),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    // FIX: Use radiusValM (double) instead of radiusM (BorderRadius)
                    borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppConstants.padM),
                          Text(
                            _openingTime.format(context),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.padL),

              // Closing Time
              Text(
                'Closing Time',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppConstants.padXS),
              InkWell(
                onTap: () => _selectTime(context, false),
                child: Container(
                  padding: const EdgeInsets.all(AppConstants.padM),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    // FIX: Use radiusValM (double) instead of radiusM (BorderRadius)
                    borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: AppConstants.padM),
                          Text(
                            _closingTime.format(context),
                            style: theme.textTheme.titleMedium,
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.padXL),

              // Info
              Container(
                padding: const EdgeInsets.all(AppConstants.padM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                  // FIX: Use radiusValM (double) instead of radiusM (BorderRadius)
                  borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.padS),
                    Expanded(
                      child: Text(
                        'These hours will be visible to all clients',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.padL),

              // Save Button
              PrimaryGradientButton(
                onPressed: _handleSave,
                text: 'Save Hours',
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSave() {
    context.read<SalonProfileBloc>().add(
      UpdateBusinessHours(
        openingTime: _formatTime(_openingTime),
        closingTime: _formatTime(_closingTime),
      ),
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Business hours updated!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}