import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../../app/config/theme/app_constants.dart';
import '../../../../../shared/widgets/profile_avatar.dart';
import '../../../../../shared/widgets/loading_indicator.dart';
import '../../../../../shared/widgets/empty_state_widget.dart';
import '../../../../../app/services/service_locator.dart';
import '../../../../../shared/models/appointment_model.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import '../../../../0_auth/data/models/user_model.dart';
import '../bloc/owner_calender_bloc.dart';
import '../bloc/owner_calender_event.dart';
import '../bloc/owner_calender_state.dart';
import '../widgets/appointment_details_dialog.dart';
import 'package:pendeza/app/services/firestore_service.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OwnerCalendarBloc(authBloc: sl<AuthBloc>())
        ..add(LoadAppointmentsForDate(DateTime.now())),
      child: const _CalendarView(),
    );
  }
}

class _CalendarView extends StatefulWidget {
  const _CalendarView();

  @override
  State<_CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<_CalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final FirestoreService _firestoreService = sl<FirestoreService>();
  final Map<String, UserModel> _clientCache = {};

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      context.read<OwnerCalendarBloc>().add(LoadAppointmentsForDate(selectedDay));
    }
  }

  void _goToToday() {
    final now = DateTime.now();
    if (!isSameDay(_selectedDay, now)) {
      setState(() {
        _selectedDay = now;
        _focusedDay = now;
      });
      context.read<OwnerCalendarBloc>().add(LoadAppointmentsForDate(now));
    } else {
      setState(() {
        _focusedDay = now;
      });
    }
  }

  void _showAppointmentDetails(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AppointmentDetailsDialog(appointment: appointment);
      },
    ).then((_) {
      context.read<OwnerCalendarBloc>().add(LoadAppointmentsForDate(_selectedDay));
    });
  }

  Future<UserModel?> _getClientDetails(String clientId) async {
    if (_clientCache.containsKey(clientId)) {
      return _clientCache[clientId];
    }

    try {
      final client = await _firestoreService.getUserDetails(clientId);
      _clientCache[clientId] = client;
      return client;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('owner.calendar.title'.tr()),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.15),
                  theme.colorScheme.secondary.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              icon: Icon(
                CupertinoIcons.today,
                color: theme.colorScheme.primary,
              ),
              tooltip: 'common.date_today'.tr(),
              onPressed: _goToToday,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Calendar Widget
          Container(
            margin: const EdgeInsets.all(AppConstants.padM),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.surface,
                  theme.colorScheme.surface,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(AppConstants.padM),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarFormat: CalendarFormat.week,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(
                  CupertinoIcons.chevron_left,
                  color: theme.colorScheme.primary,
                ),
                rightChevronIcon: Icon(
                  CupertinoIcons.chevron_right,
                  color: theme.colorScheme.primary,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                      theme.colorScheme.secondary.withValues(alpha: 0.3),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                todayTextStyle: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                selectedDecoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                selectedTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Title for appointment list
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.15),
                        theme.colorScheme.secondary.withValues(alpha: 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    CupertinoIcons.calendar_today,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'owner.calendar.list_header'.tr(args: [DateFormat.yMMMd().format(_selectedDay)]),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.padM),

          // Appointment List
          Expanded(
            child: BlocBuilder<OwnerCalendarBloc, OwnerCalendarState>(
              builder: (context, state) {
                if (state is OwnerCalendarLoading && isSameDay(state.loadingDate, _selectedDay)) {
                  return _buildLoadingList();
                }
                if (state is OwnerCalendarError && isSameDay(state.errorDate, _selectedDay)) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                    child: EmptyStateWidget.error(
                      message: state.message,
                      onActionPressed: () => context
                          .read<OwnerCalendarBloc>()
                          .add(LoadAppointmentsForDate(_selectedDay)),
                    ),
                  );
                }
                if (state is OwnerCalendarLoaded && isSameDay(state.selectedDate, _selectedDay)) {
                  if (state.appointments.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                      child: EmptyStateWidget(
                        iconData: CupertinoIcons.calendar_badge_minus,
                        title: 'owner.calendar.no_appointments'.tr(),
                        message: 'owner.calendar.no_appointments_msg'.tr(),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                    itemCount: state.appointments.length,
                    itemBuilder: (context, index) {
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (index * 80)),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 20 * (1 - value)),
                              child: child,
                            ),
                          );
                        },
                        child: _buildAppointmentItem(context, state.appointments[index]),
                      );
                    },
                  );
                }

                return _buildLoadingList();
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      itemCount: 3,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: AppConstants.padM),
        child: ShimmerPlaceholder(height: 80, width: double.infinity),
      ),
    );
  }

  Widget _buildAppointmentItem(BuildContext context, AppointmentModel appointment) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padM),
      child: FutureBuilder<UserModel?>(
        future: _getClientDetails(appointment.clientId),
        builder: (context, snapshot) {
          final String displayName = snapshot.hasData && snapshot.data != null
              ? snapshot.data!.fullName
              : 'common.loading_details'.tr();

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.05),
                  theme.colorScheme.secondary.withValues(alpha: 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.15),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: () => _showAppointmentDetails(appointment),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.padM),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withValues(alpha: 0.3),
                              theme.colorScheme.secondary.withValues(alpha: 0.3),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ProfileAvatar(
                          fullName: displayName,
                          imageUrl: snapshot.hasData ? snapshot.data?.profilePictureUrl : null,
                          radius: 26,
                        ),
                      ),
                      const SizedBox(width: AppConstants.padM),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  CupertinoIcons.scissors,
                                  size: 14,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${appointment.serviceIds.length} ${'owner.calendar.services_count'.tr()}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          DateFormat.jm().format(appointment.startTime),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}