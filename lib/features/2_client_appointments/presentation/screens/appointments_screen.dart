import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_config.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_appointments/domain/models/appointment_with_details.dart';
import 'package:pendeza/features/2_client_appointments/presentation/bloc/appointments_bloc.dart';
import 'package:pendeza/features/2_client_appointments/presentation/widgets/appointment_card.dart';
import 'package:pendeza/features/2_client_appointments/presentation/widgets/appointment_details_sheet.dart';
import 'package:pendeza/features/4_payments/presentation/screens/payment_screen.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';

import '../bloc/appoitment_events.dart';
import '../bloc/appoitments_state.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<AppointmentsBloc>()..add(FetchAppointmentsRequested()),
      // TEMPORARILY DISABLED - Payments turned off for App Store submission
      child: DefaultTabController(
        length: AppConfig.paymentsEnabled ? 3 : 2,
        child: Scaffold(
          backgroundColor: ClientTheme.background(context),
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                const _Header(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(
                    ClientTheme.gutter,
                    4,
                    ClientTheme.gutter,
                    12,
                  ),
                  child: _Tabs(),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      if (AppConfig.paymentsEnabled)
                        const _AppointmentsList(bucket: _Bucket.pending),
                      const _AppointmentsList(bucket: _Bucket.upcoming),
                      const _AppointmentsList(bucket: _Bucket.past),
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
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER + TABS
// ═════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ClientTheme.gutter,
        18,
        ClientTheme.gutter,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'client.appointments.title'.tr(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ClientTheme.display(context),
            ),
          ),
          BlocBuilder<AppointmentsBloc, AppointmentsState>(
            builder: (context, state) {
              if (state is! AppointmentsLoaded) return const SizedBox.shrink();
              final active = (AppConfig.paymentsEnabled
                      ? state.pendingPaymentAppointments.length
                      : 0) +
                  state.upcomingAppointments.length;
              if (active == 0) return const SizedBox.shrink();
              return TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                tween: Tween(begin: 0.0, end: 1.0),
                curve: Curves.easeOutBack,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                        spreadRadius: -3,
                      ),
                    ],
                  ),
                  child: Text(
                    'client.appointments.active_count'.tr(args: ['$active']),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        var pendingLabel = 'client.appointments.tab_pending'.tr();
        if (AppConfig.paymentsEnabled &&
            state is AppointmentsLoaded &&
            state.pendingPaymentAppointments.isNotEmpty) {
          pendingLabel += ' (${state.pendingPaymentAppointments.length})';
        }
        return ClientSegmentedTabs(
          labels: [
            // TEMPORARILY DISABLED - Payments turned off for App Store submission
            if (AppConfig.paymentsEnabled) pendingLabel,
            'client.appointments.tab_upcoming'.tr(),
            'client.appointments.tab_past'.tr(),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LISTS
// ═════════════════════════════════════════════════════════════════════════════

enum _Bucket { pending, upcoming, past }

class _AppointmentsList extends StatelessWidget {
  final _Bucket bucket;

  const _AppointmentsList({required this.bucket});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppointmentsBloc, AppointmentsState>(
      builder: (context, state) {
        if (state is AppointmentsLoading || state is AppointmentsInitial) {
          return _buildLoading();
        }

        if (state is AppointmentsError) {
          return ClientEmptyState(
            icon: CupertinoIcons.exclamationmark_shield_fill,
            color: Theme.of(context).colorScheme.error,
            title: 'common.oops'.tr(),
            message: state.message,
            actionLabel: 'common.retry'.tr(),
            onAction: () =>
                context.read<AppointmentsBloc>().add(FetchAppointmentsRequested()),
          );
        }

        if (state is AppointmentsLoaded) {
          final items = switch (bucket) {
            _Bucket.pending => state.pendingPaymentAppointments,
            _Bucket.upcoming => state.upcomingAppointments,
            _Bucket.past => state.pastAppointments,
          };
          if (items.isEmpty) return _buildEmpty(context);
          return _buildList(context, items);
        }

        return ClientEmptyState(
          icon: CupertinoIcons.question_circle,
          title: 'common.oops'.tr(),
          message: 'common.error_generic'.tr(),
        );
      },
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        ClientTheme.gutter,
        4,
        ClientTheme.gutter,
        0,
      ),
      itemCount: 3,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: ShimmerPlaceholder(
          width: double.infinity,
          height: 172,
          borderRadius: BorderRadius.circular(26),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    switch (bucket) {
      case _Bucket.pending:
        return ClientEmptyState(
          icon: CupertinoIcons.checkmark_seal_fill,
          color: const Color(0xFF00B894),
          title: 'client.appointments.empty_pending_title'.tr(),
          message: 'client.appointments.empty_pending_msg'.tr(),
        );
      case _Bucket.upcoming:
        return ClientEmptyState(
          icon: CupertinoIcons.calendar_badge_plus,
          title: 'client.appointments.empty_upcoming_title'.tr(),
          message: 'client.appointments.empty_upcoming_msg'.tr(),
          actionLabel: 'client.appointments.book_now'.tr(),
          onAction: () => context.go(AppRoutes.clientDiscover),
        );
      case _Bucket.past:
        return ClientEmptyState(
          icon: CupertinoIcons.clock,
          color: const Color(0xFF8A8FA0),
          title: 'client.appointments.empty_past_title'.tr(),
          message: 'client.appointments.empty_past_msg'.tr(),
        );
    }
  }

  Widget _buildList(BuildContext context, List<AppointmentWithDetails> items) {
    return RefreshIndicator(
      onRefresh: () async {
        final bloc = context.read<AppointmentsBloc>();
        bloc.add(FetchAppointmentsRequested());
        await bloc.stream.firstWhere((state) => state is! AppointmentsLoading);
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          ClientTheme.gutter,
          4,
          ClientTheme.gutter,
          110,
        ),
        // Pending tab leads with the "complete your payment" notice.
        itemCount: items.length + (bucket == _Bucket.pending ? 1 : 0),
        itemBuilder: (context, index) {
          if (bucket == _Bucket.pending) {
            if (index == 0) return const _PaymentNotice();
            index -= 1;
          }
          final details = items[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: Duration(milliseconds: 300 + (index * 80)),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 24 * (1 - value)),
                child: child,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppointmentCard(
                details: details,
                onTap: () => showAppointmentDetailsSheet(
                  context,
                  details,
                  onCompletePayment: bucket == _Bucket.pending
                      ? () => _navigateToPayment(context, details)
                      : null,
                ),
                onCompletePayment: bucket == _Bucket.pending
                    ? () => _navigateToPayment(context, details)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToPayment(BuildContext context, AppointmentWithDetails details) {
    // TEMPORARILY DISABLED - Payments turned off for App Store submission
    if (!AppConfig.paymentsEnabled) return;

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
}

class _PaymentNotice extends StatelessWidget {
  const _PaymentNotice();

  @override
  Widget build(BuildContext context) {
    const amber = Color(0xFFF5A623);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: amber.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const ClientIconTile(
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              color: amber,
              size: 40,
              solid: true,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'client.appointments.payment_warning'.tr(),
                style: ClientTheme.caption(context).copyWith(
                  fontSize: 12.5,
                  color: ClientTheme.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
