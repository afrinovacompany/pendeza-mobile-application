import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import '../../domain/models/client_stats.dart';

class ClientAppointmentHistory extends StatelessWidget {
  final List<AppointmentModel> appointments;
  final ClientStats clientStats;

  const ClientAppointmentHistory({
    super.key,
    required this.appointments,
    required this.clientStats,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced section header with gradient accent
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appointment History',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 3,
                    width: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.padS,
                  vertical: AppConstants.padXXS,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                ),
                child: Text(
                  '${appointments.length} total',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.padL),

        // Appointments list with enhanced UI
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          child: appointments.isEmpty
              ? _buildEmptyState(context, theme, isDarkMode)
              : Column(
            children: appointments.asMap().entries.map(
                  (entry) {
                final index = entry.key;
                final appointment = entry.value;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == appointments.length - 1
                        ? 0
                        : AppConstants.padM,
                  ),
                  child: _AppointmentHistoryItem(
                    appointment: appointment,
                    index: index,
                  ),
                );
              },
            ).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padXL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.95),
          ]
              : [
            theme.colorScheme.surface,
            theme.colorScheme.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusValL),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.padM),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_rounded,
              size: 48,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.padM),
          Text(
            'No appointments yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.padXXS),
          Text(
            'Client\'s booking history will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AppointmentHistoryItem extends StatelessWidget {
  final AppointmentModel appointment;
  final int index;

  const _AppointmentHistoryItem({
    required this.appointment,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final statusColor = _getStatusColor(appointment.status);
    final isPast = appointment.startTime.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [
            AppColors.darkSurface,
            AppColors.darkSurfaceVariant,
          ]
              : [
            theme.colorScheme.surface,
            theme.colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusValL),
        border: Border.all(
          color: isDarkMode
              ? AppColors.darkBorder
              : theme.dividerColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: isDarkMode
            ? AppColors.darkShadowSm
            : AppColors.lightShadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusValL),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppConstants.radiusValL),
          onTap: () {
            log.d('Tapped appointment: ${appointment.id}');
            // TODO: Navigate to appointment details
          },
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.padM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Enhanced header with date and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppConstants.radiusValS),
                            ),
                            child: Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: AppConstants.padS),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat.yMMMd().format(appointment.startTime),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  DateFormat.jm().format(appointment.startTime),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge with enhanced styling
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.padS,
                        vertical: AppConstants.padXXS,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppConstants.radiusValS),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            appointment.status.toUpperCase(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.padM),

                // Services list with enhanced design
                _ServicesList(serviceIds: appointment.serviceIds),
                const SizedBox(height: AppConstants.padM),

                // Duration and price row with better visual hierarchy
                Container(
                  padding: const EdgeInsets.all(AppConstants.padS),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppConstants.radiusValS),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${appointment.durationMinutes} min',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.padS,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(AppConstants.radiusValXS),
                            ),
                            child: Text(
                              AppFormatters.formatCurrency(appointment.totalPrice),
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons for future appointments
                if (!isPast && appointment.status.toLowerCase() != 'cancelled')
                  Padding(
                    padding: const EdgeInsets.only(top: AppConstants.padS),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            log.i('Edit appointment: ${appointment.id}');
                            // TODO: Navigate to appointment edit
                          },
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('Reschedule'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return AppColors.success;
      case 'confirmed':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      case 'noshow':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

/// Widget to display list of services with real names
class _ServicesList extends StatelessWidget {
  final List<String> serviceIds;

  const _ServicesList({required this.serviceIds});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firestoreService = sl<FirestoreService>();

    return FutureBuilder<List<ServiceModel>>(
      future: _fetchServices(firestoreService, serviceIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState(theme);
        }

        if (snapshot.hasError) {
          log.e('Error loading services: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildFallbackState(theme);
        }

        final services = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: services.map((service) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      service.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(service.price),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Row(
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading services...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackState(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.content_cut_rounded,
          size: 16,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 4),
        Text(
          '${serviceIds.length} service(s)',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Future<List<ServiceModel>> _fetchServices(
      FirestoreService firestoreService,
      List<String> serviceIds,
      ) async {
    final services = <ServiceModel>[];
    for (final serviceId in serviceIds) {
      try {
        final service = await firestoreService.getServiceDetails(serviceId);
        services.add(service);
      } catch (e) {
        log.w('Could not fetch service $serviceId: $e');
        // Skip services that can't be loaded
        continue;
      }
    }
    return services;
  }
}