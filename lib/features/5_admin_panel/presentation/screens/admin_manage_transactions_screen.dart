import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/5_admin_panel/presentation/widgets/admin_ui.dart';
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
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    context.read<AdminBloc>().add(const LoadAllAppointments());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final loaded = state is AdminLoaded ? state : null;

        return AdminPage(
          title: 'Bookings',
          subtitle: loaded == null
              ? null
              : '${loaded.appointments.length} appointments',
          icon: CupertinoIcons.calendar,
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadBookings,
              icon: const Icon(CupertinoIcons.refresh, size: 20),
              style: IconButton.styleFrom(
                backgroundColor: AdminTheme.card(context),
                foregroundColor: AdminTheme.textSecondary(context),
                side: BorderSide(color: AdminTheme.border(context)),
              ),
            ),
          ],
          toolbar: loaded == null
              ? null
              : AdminSearchField(
                  hint: 'Search client, salon or service',
                  onChanged: (v) => setState(() => _query = v),
                ),
          filters: loaded == null ? null : _buildFilters(loaded),
          child: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildFilters(AdminLoaded state) {
    // Only offer statuses that actually occur in the data.
    final counts = <String, int>{};
    for (final a in state.appointments) {
      counts[a.status] = (counts[a.status] ?? 0) + 1;
    }
    final statuses = AppointmentStatus.all
        .where((s) => (counts[s] ?? 0) > 0 || s == _selectedStatus)
        .toList();

    return AdminFilterBar(
      chips: [
        AdminFilterChip(
          label: 'All',
          count: state.appointments.length,
          selected: _selectedStatus == null,
          onTap: () => setState(() => _selectedStatus = null),
        ),
        for (final status in statuses)
          AdminFilterChip(
            label: _statusLabel(status),
            count: counts[status] ?? 0,
            tone: _statusTone(status),
            selected: _selectedStatus == status,
            onTap: () => setState(() => _selectedStatus = status),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, AdminState state) {
    if (state is AdminLoading || state is AdminInitial) {
      return const AdminLoadingState(itemHeight: 104);
    }
    if (state is AdminError) {
      return AdminErrorState(message: state.message, onRetry: _loadBookings);
    }
    if (state is! AdminLoaded) return const SizedBox.shrink();

    final filtered = _filterAppointments(state);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AdminTheme.gutter(width);
    final columns = width >= AdminTheme.wideBreakpoint ? 2 : 1;
    final rowCount = (filtered.length / columns).ceil();

    if (filtered.isEmpty) {
      return Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 0),
            child: _buildSummary(state.appointments),
          ),
          Expanded(child: _buildEmptyState()),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
      // The summary is the first row so it scrolls with the list.
      itemCount: rowCount + 1,
      itemBuilder: (context, row) {
        if (row == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSummary(state.appointments),
          );
        }

        final children = <Widget>[];
        for (var c = 0; c < columns; c++) {
          final index = (row - 1) * columns + c;
          if (c > 0) children.add(const SizedBox(width: 12));
          children.add(
            Expanded(
              child: index < filtered.length
                  ? _buildBookingCard(context, filtered[index], state)
                  : const SizedBox.shrink(),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummary(List<AppointmentModel> appointments) {
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

    final upcoming = appointments
        .where((a) =>
            a.startTime.isAfter(now) &&
            a.status == AppointmentStatus.confirmed)
        .length;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Today',
            value: '$todayCount',
            icon: CupertinoIcons.today,
            tone: AdminTone.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            label: 'This week',
            value: '$weekCount',
            icon: CupertinoIcons.calendar,
            tone: AdminTone.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            label: 'Upcoming',
            value: '$upcoming',
            icon: CupertinoIcons.time,
            tone: AdminTone.success,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final hasFilters = _query.isNotEmpty || _selectedStatus != null;
    return AdminEmptyState(
      icon: CupertinoIcons.calendar,
      title: hasFilters ? 'No bookings match your filters' : 'No bookings yet',
      message: hasFilters
          ? 'Try a different status or search term.'
          : 'Appointments across all salons will appear here.',
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    AppointmentModel appointment,
    AdminLoaded state,
  ) {
    final clientName = _clientName(appointment, state.users);
    final salonName = _salonName(appointment, state.salons);
    final services = _serviceNames(appointment, state.serviceNames);
    final timeLabel = DateFormat('h:mm a').format(appointment.startTime);

    return AdminCard(
      onTap: () => _showBookingDetails(
        appointment,
        clientName,
        salonName,
        services,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DateBadge(date: appointment.startTime),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.body(context)
                      .copyWith(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  salonName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.body(context).copyWith(
                    fontSize: 13,
                    color: AdminTheme.textSecondary(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  services,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.caption(context),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 13,
                      color: AdminTheme.textSecondary(context),
                    ),
                    const SizedBox(width: 4),
                    Text(timeLabel, style: AdminTheme.caption(context)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AdminPill(
                label: _statusLabel(appointment.status),
                tone: _statusTone(appointment.status),
              ),
              const SizedBox(height: 10),
              Text(
                AppFormatters.formatCurrency(appointment.totalPrice),
                style: AdminTheme.body(context)
                    .copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  AdminTone _statusTone(String status) {
    switch (status) {
      case AppointmentStatus.confirmed:
        return AdminTone.success;
      case AppointmentStatus.completed:
        return AdminTone.primary;
      case AppointmentStatus.cancelled:
        return AdminTone.neutral;
      case AppointmentStatus.pendingPayment:
        return AdminTone.warning;
      case AppointmentStatus.noShow:
      case AppointmentStatus.paymentFailed:
        return AdminTone.danger;
      default:
        return AdminTone.info;
    }
  }

  /// "no_show" / "pendingPayment" → "No show" / "Pending payment".
  String _statusLabel(String status) {
    final spaced = status
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'(?<=[a-z])(?=[A-Z])'),
          (_) => ' ',
        )
        .toLowerCase()
        .trim();
    if (spaced.isEmpty) return status;
    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  List<AppointmentModel> _filterAppointments(AdminLoaded state) {
    final searchTerm = _query.trim().toLowerCase();
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

    showAdminSheet<void>(
      context,
      builder: (sheetContext) {
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            4,
            24,
            24 + MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      clientName,
                      style: AdminTheme.title(sheetContext)
                          .copyWith(fontSize: 20),
                    ),
                  ),
                  AdminPill(
                    label: _statusLabel(appointment.status),
                    tone: _statusTone(appointment.status),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AdminInfoRow(
                icon: CupertinoIcons.building_2_fill,
                label: 'Salon',
                value: salonName,
              ),
              AdminInfoRow(
                icon: CupertinoIcons.scissors,
                label: 'Service',
                value: services,
              ),
              AdminInfoRow(
                icon: CupertinoIcons.calendar,
                label: 'Date',
                value: dateLabel,
              ),
              AdminInfoRow(
                icon: CupertinoIcons.clock,
                label: 'Time',
                value: timeLabel,
              ),
              AdminInfoRow(
                icon: CupertinoIcons.hourglass,
                label: 'Duration',
                value: '${appointment.durationMinutes} min',
              ),
              AdminInfoRow(
                icon: CupertinoIcons.money_dollar_circle,
                label: 'Total',
                value: AppFormatters.formatCurrency(appointment.totalPrice),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact KPI used in the summary row.
class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AdminTone tone;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminIconTile(icon: icon, tone: tone, size: 32),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AdminTheme.title(context).copyWith(fontSize: 24),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AdminTheme.caption(context),
          ),
        ],
      ),
    );
  }
}

/// Calendar-style day tile ("SEP / 20").
class _DateBadge extends StatelessWidget {
  final DateTime date;
  const _DateBadge({required this.date});

  @override
  Widget build(BuildContext context) {
    final ink = AdminTheme.toneInk(context, AdminTone.primary);
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AdminTheme.toneTint(context, AdminTone.primary),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('MMM').format(date).toUpperCase(),
            style: AdminTheme.label(context).copyWith(color: ink),
          ),
          const SizedBox(height: 2),
          Text(
            '${date.day}',
            style: AdminTheme.title(context).copyWith(fontSize: 22, color: ink),
          ),
          Text(
            DateFormat('EEE').format(date),
            style: AdminTheme.caption(context).copyWith(
              fontSize: 11,
              color: ink.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
