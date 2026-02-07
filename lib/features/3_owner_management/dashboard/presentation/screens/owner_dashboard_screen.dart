import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/formatters.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/3_owner_management/promotions/presentation/screens/owner_promotions_list_screen.dart';
import '../bloc/owner_dashboard_bloc.dart';
import '../bloc/owner_dashboard_event.dart';
import '../bloc/owner_dashboard_state.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/kpi_card.dart';
import '../widgets/upcoming_appointments_list.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<OwnerDashboardBloc>()..add(const LoadDashboardData()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<OwnerDashboardBloc, OwnerDashboardState>(
          builder: (context, state) {
            if (state is OwnerDashboardLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'owner.dashboard.loading'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (state is OwnerDashboardError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'owner.dashboard.error_title'.tr(),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context.read<OwnerDashboardBloc>().add(const LoadDashboardData());
                      },
                      child: Text('common.retry'.tr()),
                    ),
                  ],
                ),
              );
            }

            if (state is OwnerDashboardLoaded) {
              final stats = state.stats;

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<OwnerDashboardBloc>().add(const LoadDashboardData());
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.padL),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enhanced Header
                      DashboardHeader(
                        salonName: state.salonName,
                      ),
                      const SizedBox(height: AppConstants.padL),

                      // Quick Action: Manage Salon Profile
                      _buildManageSalonCard(context, theme),
                      const SizedBox(height: AppConstants.padXL),

                      // Section label for stats
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  theme.colorScheme.primary,
                                  theme.colorScheme.secondary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'owner.dashboard.todays_overview'.tr(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.padM),

                      // Stats Grid with staggered animation
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppConstants.padM,
                        mainAxisSpacing: AppConstants.padM,
                        childAspectRatio: 1.3,
                        children: [
                          _buildAnimatedKpi(
                            context,
                            index: 0,
                            child: KpiCard(
                              title: 'owner.dashboard.revenue'.tr(),
                              value: AppFormatters.formatCurrency(stats.todayRevenue),
                              icon: Icons.trending_up_rounded,
                              color: Colors.green,
                              onTap: () {},
                            ),
                          ),
                          _buildAnimatedKpi(
                            context,
                            index: 1,
                            child: KpiCard(
                              title: 'owner.dashboard.appointments'.tr(),
                              value: 'owner.dashboard.appointments_today'
                                  .tr(args: ['${stats.todayAppointmentsCount}']),
                              icon: Icons.calendar_today_rounded,
                              color: Colors.blue,
                              onTap: () {},
                            ),
                          ),
                          _buildAnimatedKpi(
                            context,
                            index: 2,
                            child: KpiCard(
                              title: 'owner.dashboard.new_clients'.tr(),
                              value: 'owner.dashboard.clients_week'
                                  .tr(args: ['${stats.newClientsThisWeek}']),
                              icon: Icons.person_add_alt_1_rounded,
                              color: Colors.orange,
                              onTap: () {},
                            ),
                          ),
                          _buildAnimatedKpi(
                            context,
                            index: 3,
                            child: KpiCard(
                              title: 'owner.dashboard.promotions'.tr(),
                              value: 'owner.dashboard.promotions_desc'.tr(),
                              icon: Icons.local_offer_rounded,
                              color: Colors.purple,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const OwnerPromotionsListScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppConstants.padXXL),

                      // Upcoming appointments (next 7 days)
                      UpcomingAppointmentsList(
                        appointments: stats.upcomingAll.isNotEmpty
                            ? stats.upcomingAll
                            : stats.upcomingToday,
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildAnimatedKpi(
      BuildContext context, {
        required int index,
        required Widget child,
      }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index * 100)),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildManageSalonCard(BuildContext context, ThemeData theme) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.ownerSalonProfile),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppConstants.padL),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: AppConstants.radiusL,
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.store_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppConstants.padM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'owner.dashboard.manage_salon'.tr(),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'owner.dashboard.manage_salon_desc'.tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
