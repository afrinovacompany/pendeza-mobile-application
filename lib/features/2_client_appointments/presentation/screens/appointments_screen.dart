import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/widgets/adaptive/adaptive_button.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/features/2_client_appointments/presentation/bloc/appointments_bloc.dart';
import 'package:pendeza/features/2_client_appointments/presentation/widgets/appointment_card.dart';
import 'package:pendeza/features/4_payments/presentation/screens/payment_screen.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import '../bloc/appoitment_events.dart';
import '../bloc/appoitments_state.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (context) => sl<AppointmentsBloc>()..add(FetchAppointmentsRequested()),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                // Header matching Discovery screen style
                _buildHeader(context, theme),
                // Enhanced Tab Bar
                _buildTabBar(context, theme),
                // Tab content
                const Expanded(
                  child: TabBarView(
                    children: [
                      _PendingPaymentListView(),
                      _AppointmentsListView(listType: _ListType.upcoming),
                      _AppointmentsListView(listType: _ListType.past),
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

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.padL,
        AppConstants.padL,
        AppConstants.padL,
        AppConstants.padS,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'client.appointments.title'.tr(),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          // Appointment count badge
          BlocBuilder<AppointmentsBloc, AppointmentsState>(
            builder: (context, state) {
              if (state is AppointmentsLoaded) {
                final totalActive = state.pendingPaymentAppointments.length +
                    state.upcomingAppointments.length;
                if (totalActive > 0) {
                  return TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'client.appointments.active_count'.tr(args: ['$totalActive']),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.padL,
        vertical: AppConstants.padS,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        labelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        splashBorderRadius: BorderRadius.circular(10),
        labelPadding: EdgeInsets.zero,
        tabs: [
          BlocBuilder<AppointmentsBloc, AppointmentsState>(
            builder: (context, state) {
              final pendingCount = state is AppointmentsLoaded
                  ? state.pendingPaymentAppointments.length
                  : 0;
              return Tab(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('client.appointments.tab_pending'.tr()),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade600,
                                    Colors.orange.shade500,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pendingCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Tab(
            height: 40,
            child: Text('client.appointments.tab_upcoming'.tr()),
          ),
          Tab(
            height: 40,
            child: Text('client.appointments.tab_past'.tr()),
          ),
        ],
      ),
    );
  }
}

enum _ListType { upcoming, past }

class _PendingPaymentListView extends StatelessWidget {
  const _PendingPaymentListView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        if (state is AppointmentsLoading || state is AppointmentsInitial) {
          return _buildLoadingState();
        }

        if (state is AppointmentsError) {
          return EmptyStateWidget.error(
            iconData: CupertinoIcons.exclamationmark_shield_fill,
            message: state.message,
            onActionPressed: () {
              context.read<AppointmentsBloc>().add(FetchAppointmentsRequested());
            },
          );
        }

        if (state is AppointmentsLoaded) {
          final appointments = state.pendingPaymentAppointments;

          if (appointments.isEmpty) {
            return EmptyStateWidget(
              iconData: CupertinoIcons.checkmark_circle,
              title: 'client.appointments.empty_pending_title'.tr(),
              message: 'client.appointments.empty_pending_msg'.tr(),
            );
          }

          return _buildPendingList(context, appointments);
        }

        return EmptyStateWidget(
          iconData: CupertinoIcons.question_circle,
          title: 'common.oops'.tr(),
          message: 'common.error_generic'.tr(),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.padM),
          child: ShimmerPlaceholder(
            width: double.infinity,
            height: 180,
            borderRadius: AppConstants.radiusL,
          ),
        );
      },
    );
  }

  Widget _buildPendingList(BuildContext context, List<AppointmentWithDetails> appointments) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AppointmentsBloc>().add(FetchAppointmentsRequested());
        await context
            .read<AppointmentsBloc>()
            .stream
            .firstWhere((state) => state is! AppointmentsLoading);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppConstants.padL),
        children: [
          // Enhanced warning banner
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
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
            child: Container(
              margin: const EdgeInsets.only(bottom: AppConstants.padM),
              padding: const EdgeInsets.all(AppConstants.padM),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade50,
                    Colors.orange.shade100.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.orange.shade300,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      CupertinoIcons.exclamationmark_triangle_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppConstants.padM),
                  Expanded(
                    child: Text(
                      'client.appointments.payment_warning'.tr(),
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Appointment cards with staggered animation
          ...appointments.asMap().entries.map((entry) {
            final index = entry.key;
            final appointmentDetails = entry.value;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 100)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppConstants.padM),
                child: AppointmentCard(
                  details: appointmentDetails,
                  onTap: () => _showAppointmentDetailsBottomSheet(context, appointmentDetails),
                  onCompletePayment: () => _navigateToPayment(context, appointmentDetails),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _navigateToPayment(BuildContext context, AppointmentWithDetails details) {
    final authState = context.read<AuthBloc>().state;

    String name = "Client";
    String email = "client@example.com";

    if (authState is Authenticated) {
      name = authState.user.fullName;
      email = authState.user.email;
    }

    context.push(
      AppRoutes.paymentSelection,
      extra: PaymentArguments(
        appointmentId: details.appointment.id,
        amount: details.appointment.totalPrice,
        customerName: name,
        customerEmail: email,
      ),
    );
  }

  void _showAppointmentDetailsBottomSheet(BuildContext context, AppointmentWithDetails details) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppConstants.padL),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.padL),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.shade100,
                          Colors.orange.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.creditcard_fill,
                      color: Colors.orange.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'client.appointments.details_title'.tr(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.padL),
              _buildDetailRow(context,
                  icon: CupertinoIcons.building_2_fill,
                  label: 'common.salon'.tr(),
                  value: details.salon.salonName),
              _buildDetailRow(context,
                  icon: CupertinoIcons.scissors,
                  label: 'common.services'.tr(),
                  value: details.serviceNames),
              _buildDetailRow(context,
                  icon: CupertinoIcons.calendar,
                  label: 'common.date'.tr(),
                  value: AppFormatters.monthDay.format(details.appointment.startTime)),
              _buildDetailRow(context,
                  icon: CupertinoIcons.time,
                  label: 'common.time'.tr(),
                  value: AppFormatters.formatTime(details.appointment.startTime)),
              _buildDetailRow(context,
                  icon: CupertinoIcons.money_dollar_circle,
                  label: 'common.total'.tr(),
                  value: AppFormatters.formatCurrency(details.appointment.totalPrice)),
              const SizedBox(height: AppConstants.padXL),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.orange.shade500],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToPayment(context, details);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.creditcard, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            'client.booking.complete_payment_btn'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.padS),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('common.close'.tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
      }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsListView extends StatelessWidget {
  final _ListType listType;

  const _AppointmentsListView({required this.listType});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        if (state is AppointmentsLoading || state is AppointmentsInitial) {
          return _buildLoadingState();
        }

        if (state is AppointmentsError) {
          return EmptyStateWidget.error(
            iconData: CupertinoIcons.exclamationmark_shield_fill,
            message: state.message,
            onActionPressed: () {
              context.read<AppointmentsBloc>().add(FetchAppointmentsRequested());
            },
          );
        }

        if (state is AppointmentsLoaded) {
          final appointments = listType == _ListType.upcoming
              ? state.upcomingAppointments
              : state.pastAppointments;

          if (appointments.isEmpty) {
            return EmptyStateWidget.notFound(
              iconData: listType == _ListType.upcoming
                  ? CupertinoIcons.calendar_badge_plus
                  : CupertinoIcons.calendar_badge_minus,
              message: listType == _ListType.upcoming
                  ? 'client.appointments.empty_upcoming_msg'.tr()
                  : 'client.appointments.empty_past_msg'.tr(),
              actionText: listType == _ListType.upcoming
                  ? 'client.appointments.book_now'.tr()
                  : null,
              onActionPressed: listType == _ListType.upcoming
                  ? () => context.go(AppRoutes.clientDiscover)
                  : null,
            );
          }

          return _buildLoadedList(context, appointments);
        }

        return EmptyStateWidget(
          iconData: CupertinoIcons.question_circle,
          title: 'common.oops'.tr(),
          message: 'common.error_generic'.tr(),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.padM),
          child: ShimmerPlaceholder(
            width: double.infinity,
            height: 140,
            borderRadius: AppConstants.radiusL,
          ),
        );
      },
    );
  }

  Widget _buildLoadedList(BuildContext context, List<AppointmentWithDetails> appointments) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AppointmentsBloc>().add(FetchAppointmentsRequested());
        await context
            .read<AppointmentsBloc>()
            .stream
            .firstWhere((state) => state is! AppointmentsLoading);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.padL),
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointmentDetails = appointments[index];
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
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppConstants.padM),
              child: AppointmentCard(
                details: appointmentDetails,
                onTap: () => _showAppointmentDetailsBottomSheet(context, appointmentDetails),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAppointmentDetailsBottomSheet(BuildContext context, AppointmentWithDetails details) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppConstants.padL),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppConstants.padL),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                          theme.colorScheme.secondary.withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      CupertinoIcons.calendar_badge_plus,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'client.appointments.appointment_details'.tr(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.padL),
              _buildDetailRow(context,
                  icon: CupertinoIcons.building_2_fill,
                  label: 'common.salon'.tr(),
                  value: details.salon.salonName),
              _buildDetailRow(context,
                  icon: CupertinoIcons.scissors,
                  label: 'common.services'.tr(),
                  value: details.serviceNames),
              _buildDetailRow(context,
                  icon: CupertinoIcons.calendar,
                  label: 'common.date'.tr(),
                  value: AppFormatters.monthDay.format(details.appointment.startTime)),
              _buildDetailRow(context,
                  icon: CupertinoIcons.time,
                  label: 'common.time'.tr(),
                  value: AppFormatters.formatTime(details.appointment.startTime)),
              _buildDetailRow(context,
                  icon: CupertinoIcons.hourglass,
                  label: 'common.duration'.tr(),
                  value: 'client.booking.approx_duration'.tr(args: ['${details.appointment.durationMinutes}'])),
              _buildDetailRow(context,
                  icon: CupertinoIcons.money_dollar_circle,
                  label: 'common.total_price'.tr(),
                  value: AppFormatters.formatCurrency(details.appointment.totalPrice)),
              _buildDetailRow(context,
                  icon: CupertinoIcons.checkmark_shield_fill,
                  label: 'common.status'.tr(),
                  value: details.appointment.status),
              const SizedBox(height: AppConstants.padXL),
              AdaptiveButton(
                onPressed: () => Navigator.pop(context),
                isExpanded: true,
                child: Text('common.close'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
      }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.padM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}