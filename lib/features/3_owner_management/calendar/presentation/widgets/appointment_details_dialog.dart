import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/widgets/profile_avatar.dart'; // Import ProfileAvatar

import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/services/service_locator.dart';

import '../../../../0_auth/data/models/user_model.dart';

/// A dialog to show detailed information about an appointment with real data.
class AppointmentDetailsDialog extends StatefulWidget {
  final AppointmentModel appointment;

  const AppointmentDetailsDialog({super.key, required this.appointment});

  @override
  State<AppointmentDetailsDialog> createState() =>
      _AppointmentDetailsDialogState();
}

class _AppointmentDetailsDialogState extends State<AppointmentDetailsDialog> {
  final FirestoreService _firestoreService = sl<FirestoreService>();

  UserModel? _client;
  List<ServiceModel> _services = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAppointmentDetails();
  }

  Future<void> _loadAppointmentDetails() async {
    try {
      // Fetch client details
      final clientFuture = _firestoreService.getUserDetails(widget.appointment.clientId);

      // Fetch all service details
      final serviceFutures = widget.appointment.serviceIds
          .map((id) => _firestoreService.getServiceDetails(id))
          .toList();

      // Wait for all data
      final results = await Future.wait([
        clientFuture,
        ...serviceFutures,
      ]);

      if (mounted) {
        setState(() {
          _client = results[0] as UserModel;
          _services = results.sublist(1).cast<ServiceModel>();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppConstants.radiusL),
      titlePadding: const EdgeInsets.only(
        top: AppConstants.padL,
        left: AppConstants.padL,
        right: AppConstants.padL,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppConstants.padL,
        vertical: AppConstants.padM,
      ),
      actionsPadding: const EdgeInsets.only(
        right: AppConstants.padM,
        bottom: AppConstants.padM,
      ),
      title: Row(
        children: [
          const Icon(Icons.event_note_rounded),
          const SizedBox(width: AppConstants.padS),
          const Text('Appointment Details'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          )
        ],
      ),
      content: _isLoading
          ? const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      )
          : _errorMessage != null
          ? SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: theme.colorScheme.error),
              const SizedBox(height: AppConstants.padM),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      )
          : SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Info
            _buildSectionTitle(theme, 'Client'),
            ListTile(
              leading: ProfileAvatar(
                fullName: _client?.fullName ?? 'Unknown',
                imageUrl: _client?.profilePictureUrl,
                radius: 20,
              ),
              title: Text(
                _client?.fullName ?? 'Unknown Client',
                style: theme.textTheme.titleMedium,
              ),
              // --- THIS IS THE FIX ---
              // We already check if phoneNumber is not null,
              // so we can use the `!` (bang operator) to tell Dart
              // that we are sure it's not null inside the Text widget.
              subtitle: _client?.phoneNumber != null
                  ? Text(_client!.phoneNumber!) // Added `!` here
                  : null,
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            const Divider(height: AppConstants.padM),

            // Date & Time Info
            _buildSectionTitle(theme, 'Date & Time'),
            _buildDetailRow(
              theme,
              Icons.calendar_today_outlined,
              DateFormat.yMMMMEEEEd().format(widget.appointment.startTime),
            ),
            const SizedBox(height: AppConstants.padS),
            _buildDetailRow(
              theme,
              Icons.access_time_rounded,
              DateFormat.jm().format(widget.appointment.startTime),
            ),
            const SizedBox(height: AppConstants.padS),
            _buildDetailRow(
              theme,
              Icons.hourglass_bottom_rounded,
              '${widget.appointment.durationMinutes} minutes',
            ),
            const Divider(height: AppConstants.padM),

            // Services Info
            _buildSectionTitle(theme, 'Services Booked'),
            if (_services.isEmpty)
              Text(
                'No services found',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            else
              ..._services.map((service) => Padding(
                padding: const EdgeInsets.only(top: AppConstants.padXS),
                child: Row(
                  children: [
                    // FIXED: Proper bullet character
                    Text('• ', style: theme.textTheme.bodyLarge),
                    Expanded(
                      child: Text(
                        service.name,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(service.price),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
            const SizedBox(height: AppConstants.padS),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Total: ${AppFormatters.formatCurrency(widget.appointment.totalPrice)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const Divider(height: AppConstants.padM),

            // Status Info
            _buildSectionTitle(theme, 'Status'),
            _buildStatusChip(theme, widget.appointment.status),
          ],
        ),
      ),
      actions: _isLoading || _errorMessage != null
          ? [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ]
          : [
        // Action buttons for appointment management
        if (widget.appointment.status.toLowerCase() != 'completed' &&
            widget.appointment.status.toLowerCase() != 'cancelled')
          TextButton(
            onPressed: () => _handleMarkComplete(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Mark Complete'),
          ),
        if (widget.appointment.status.toLowerCase() != 'cancelled')
          TextButton(
            onPressed: () => _handleCancel(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padS),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: AppConstants.padM),
        Expanded(
          child: Text(text, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme, String status) {
    Color statusColor;
    Color backgroundColor;

    switch (status.toLowerCase()) {
      case 'confirmed':
        statusColor = Colors.blue;
        backgroundColor = Colors.blue.withOpacity(0.1);
        break;
      case 'completed':
        statusColor = Colors.green;
        backgroundColor = Colors.green.withOpacity(0.1);
        break;
      case 'cancelled':
        statusColor = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.1);
        break;
      case 'noshow':
        statusColor = Colors.orange;
        backgroundColor = Colors.orange.withOpacity(0.1);
        break;
      default:
        statusColor = theme.colorScheme.primary;
        backgroundColor = theme.colorScheme.primary.withOpacity(0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.padM,
        vertical: AppConstants.padS,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppConstants.radiusS,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: statusColor),
          const SizedBox(width: AppConstants.padS),
          Text(
            status.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ADDED: Handle marking appointment as complete
  Future<void> _handleMarkComplete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Mark as Complete'),
        content: const Text(
          'Are you sure you want to mark this appointment as completed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Mark Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _firestoreService.updateAppointmentStatus(
          widget.appointment.id,
          'Completed',
        );
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment marked as completed'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // ADDED: Handle cancelling appointment
  Future<void> _handleCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: const Text(
          'Are you sure you want to cancel this appointment? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No, Keep It'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await _firestoreService.updateAppointmentStatus(
          widget.appointment.id,
          'Cancelled',
        );
        if (mounted) {
          Navigator.of(context).pop(); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Appointment cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}