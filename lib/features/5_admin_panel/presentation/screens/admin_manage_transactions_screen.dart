import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';

import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminManageTransactionsScreen extends StatefulWidget {
  const AdminManageTransactionsScreen({super.key});

  @override
  State<AdminManageTransactionsScreen> createState() =>
      _AdminManageTransactionsScreenState();
}

class _AdminManageTransactionsScreenState
    extends State<AdminManageTransactionsScreen> {
  String? _selectedStatus;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    context.read<AdminBloc>().add(const LoadAllAppointments());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
        backgroundColor:
            isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.refresh),
            onPressed: _loadBookings,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : theme.scaffoldBackgroundColor.withAlpha(245),
      body: Column(
        children: [
          _buildFiltersSection(theme),
          Expanded(
            child: BlocBuilder<AdminBloc, AdminState>(
              builder: (context, state) {
                if (state is AdminLoading || state is AdminInitial) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: AppColors.error),
                        const SizedBox(height: AppConstants.padM),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(state.message, textAlign: TextAlign.center),
                        ),
                        const SizedBox(height: AppConstants.padM),
                        ElevatedButton(
                          onPressed: _loadBookings,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is AdminLoaded) {
                  final filtered = _filterAppointments(state);
                  return _buildLoadedBody(filtered, theme, state);
                }

                return const Center(child: Text('Unknown state'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search client, salon, or service...',
              prefixIcon: const Icon(CupertinoIcons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppConstants.padM,
                vertical: AppConstants.padS,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppConstants.padM),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterDropdown(
                  label: 'Status',
                  value: _selectedStatus,
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All statuses')),
                    ...AppointmentStatus.all.map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                  },
                ),
                if (_selectedStatus != null) ...[
                  const SizedBox(width: AppConstants.padM),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _selectedStatus = null);
                    },
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String?>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: value,
          items: items,
          onChanged: onChanged,
          hint: Text(label),
        ),
      ),
    );
  }

  Widget _buildLoadedBody(
    List<AppointmentModel> filtered,
    ThemeData theme,
    AdminLoaded state,
  ) {
    return Column(
      children: [
        _buildSummary(state.appointments, theme),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(theme)
              : ListView.separated(
                  padding: const EdgeInsets.all(AppConstants.padM),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppConstants.padS),
                  itemBuilder: (context, index) {
                    final appointment = filtered[index];
                    return _buildBookingCard(appointment, theme, state);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSummary(List<AppointmentModel> appointments, ThemeData theme) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfWeek =
        startOfToday.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));

    final todayCount = appointments.where((a) {
      return !a.startTime.isBefore(startOfToday) &&
          a.startTime.isBefore(startOfToday.add(const Duration(days: 1)));
    }).length;

    final weekCount = appointments.where((a) {
      return !a.startTime.isBefore(startOfWeek) &&
          a.startTime.isBefore(endOfWeek);
    }).length;

    final confirmed = appointments
        .where((a) => a.status == AppointmentStatus.confirmed)
        .length;
    final completed = appointments
        .where((a) => a.status == AppointmentStatus.completed)
        .length;
    final cancelled = appointments
        .where((a) => a.status == AppointmentStatus.cancelled)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.padM,
        AppConstants.padM,
        AppConstants.padM,
        0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Today',
                  value: '$todayCount',
                  icon: CupertinoIcons.today,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppConstants.padS),
              Expanded(
                child: _SummaryCard(
                  label: 'This week',
                  value: '$weekCount',
                  icon: CupertinoIcons.calendar,
                  color: AppColors.accent2,
                ),
              ),
              const SizedBox(width: AppConstants.padS),
              Expanded(
                child: _SummaryCard(
                  label: 'Loaded',
                  value: '${appointments.length}',
                  icon: CupertinoIcons.collections,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padS),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(label: 'Confirmed', count: confirmed),
                _StatusChip(label: 'Completed', count: completed),
                _StatusChip(label: 'Cancelled', count: cancelled),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final hasFilters =
        _searchController.text.isNotEmpty || _selectedStatus != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.calendar,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: AppConstants.padM),
          Text(
            hasFilters ? 'No bookings match your filters' : 'No bookings yet',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: AppConstants.padS),
          Text(
            hasFilters
                ? 'Try a different status or search term'
                : 'Appointments across all salons will appear here',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(
    AppointmentModel appointment,
    ThemeData theme,
    AdminLoaded state,
  ) {
    final clientName = _clientName(appointment, state.users);
    final salonName = _salonName(appointment, state.salons);
    final services = _serviceNames(appointment, state.serviceNames);
    final dateLabel =
        DateFormat('EEE d MMM').format(appointment.startTime);
    final timeLabel = DateFormat('h:mm a').format(appointment.startTime);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBookingDetails(
          appointment,
          clientName,
          salonName,
          services,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      clientName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusBadge(appointment.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                salonName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                services,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '$dateLabel · $timeLabel',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    AppFormatters.formatCurrency(appointment.totalPrice),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AppColors.success;
      case AppointmentStatus.completed:
        return AppColors.primary;
      case AppointmentStatus.cancelled:
        return Colors.grey;
      case AppointmentStatus.pendingPayment:
        return Colors.orange;
      case AppointmentStatus.noShow:
      case AppointmentStatus.paymentFailed:
        return AppColors.error;
      default:
        return AppColors.accent2;
    }
  }

  List<AppointmentModel> _filterAppointments(AdminLoaded state) {
    final searchTerm = _searchController.text.trim().toLowerCase();
    return state.appointments.where((appointment) {
      if (_selectedStatus != null && appointment.status != _selectedStatus) {
        return false;
      }
      if (searchTerm.isEmpty) return true;
      final client = _clientName(appointment, state.users).toLowerCase();
      final salon = _salonName(appointment, state.salons).toLowerCase();
      final services =
          _serviceNames(appointment, state.serviceNames).toLowerCase();
      return client.contains(searchTerm) ||
          salon.contains(searchTerm) ||
          services.contains(searchTerm) ||
          appointment.status.toLowerCase().contains(searchTerm);
    }).toList();
  }

  String _clientName(AppointmentModel appointment, List<UserModel> users) {
    if (appointment.isWalkIn) {
      final walkIn = appointment.walkInName?.trim();
      if (walkIn != null && walkIn.isNotEmpty) return '$walkIn (walk-in)';
      return 'Walk-in';
    }
    final user = users.where((u) => u.uid == appointment.clientId).firstOrNull;
    if (user != null && user.fullName.trim().isNotEmpty) {
      return user.fullName;
    }
    return 'Unknown client';
  }

  String _salonName(AppointmentModel appointment, List<SalonModel> salons) {
    final salon =
        salons.where((s) => s.id == appointment.salonId).firstOrNull;
    return salon?.salonName ?? 'Unknown salon';
  }

  String _serviceNames(
    AppointmentModel appointment,
    Map<String, String> names,
  ) {
    if (appointment.serviceIds.isEmpty) return 'No services';
    final resolved = appointment.serviceIds
        .map((id) => names[id])
        .whereType<String>()
        .toList();
    if (resolved.isEmpty) {
      final count = appointment.serviceIds.length;
      return count == 1 ? '1 service' : '$count services';
    }
    return resolved.join(', ');
  }

  void _showBookingDetails(
    AppointmentModel appointment,
    String clientName,
    String salonName,
    String services,
  ) {
    final dateLabel =
        DateFormat('EEEE d MMM y').format(appointment.startTime);
    final timeLabel = DateFormat('h:mm a').format(appointment.startTime);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      clientName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildStatusBadge(appointment.status),
                ],
              ),
              const SizedBox(height: 16),
              _detailRow('Salon', salonName),
              _detailRow('Service', services),
              _detailRow('Date', dateLabel),
              _detailRow('Time', timeLabel),
              _detailRow('Duration', '${appointment.durationMinutes} min'),
              _detailRow(
                'Total',
                AppFormatters.formatCurrency(appointment.totalPrice),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final int count;

  const _StatusChip({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Chip(
      visualDensity: VisualDensity.compact,
      label: Text('$label $count'),
      padding: EdgeInsets.zero,
    );
  }
}
