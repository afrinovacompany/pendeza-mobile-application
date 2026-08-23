import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_state.dart';

import '../bloc/admin_event.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : theme.scaffoldBackgroundColor,
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
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
                    'Loading dashboard...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            );
          }
          if (state is AdminError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: AppConstants.padL),
                  Text(
                    'Something went wrong',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.padS),
                  Text(
                    state.message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: AppConstants.padL),
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<AdminBloc>().add(LoadAdminData()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is AdminLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<AdminBloc>().add(LoadAdminData());
                await Future.delayed(const Duration(seconds: 1));
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header with Gradient
                    _buildWelcomeHeader(context, theme, state),

                    Padding(
                      padding: const EdgeInsets.all(AppConstants.padL),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quick Actions
                          _buildSectionTitle(theme, 'Quick Actions'),
                          const SizedBox(height: AppConstants.padM),
                          _buildQuickActions(context, theme),

                          const SizedBox(height: AppConstants.padXL),

                          // Platform Stats
                          _buildSectionTitle(theme, 'Platform Overview'),
                          const SizedBox(height: AppConstants.padM),
                          _buildStatsGrid(context, theme, state),

                          const SizedBox(height: AppConstants.padXL),

                          // User Breakdown
                          _buildSectionTitle(theme, 'User Breakdown'),
                          const SizedBox(height: AppConstants.padM),
                          _buildUserBreakdown(context, theme, state),

                          const SizedBox(height: AppConstants.padXL),

                          // Recent Activity / Quick Links
                          _buildSectionTitle(theme, 'Management'),
                          const SizedBox(height: AppConstants.padM),
                          _buildManagementCards(context, theme),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Center(child: Text('Unknown state.'));
        },
      ),
    );
  }

  Widget _buildWelcomeHeader(
      BuildContext context, ThemeData theme, AdminLoaded state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppConstants.padL,
        left: AppConstants.padL,
        right: AppConstants.padL,
        bottom: AppConstants.padXL,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  CupertinoIcons.shield_lefthalf_fill,
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
                      'Admin Dashboard',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome back! Here\'s your overview.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padL),
          // Summary Row
          Row(
            children: [
              _buildHeaderStat(
                '${state.users.length}',
                'Users',
                CupertinoIcons.person_2_fill,
              ),
              const SizedBox(width: AppConstants.padL),
              _buildHeaderStat(
                '${state.salons.length}',
                'Salons',
                CupertinoIcons.building_2_fill,
              ),
              const SizedBox(width: AppConstants.padL),
              _buildHeaderStat(
                '${state.promotions.length}',
                'Promos',
                CupertinoIcons.tag_fill,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.padM,
          vertical: AppConstants.padS,
        ),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Row(
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
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _QuickActionCard(
            icon: CupertinoIcons.person_add_solid,
            label: 'Users',
            color: AppColors.primary,
            onTap: () => context.go(AppRoutes.adminManageUsers),
          ),
        ),
        const SizedBox(width: AppConstants.padM),
        Expanded(
          child: _QuickActionCard(
            icon: CupertinoIcons.building_2_fill,
            label: 'Salons',
            color: AppColors.accent,
            onTap: () => context.go(AppRoutes.adminManageSalons),
          ),
        ),
        const SizedBox(width: AppConstants.padM),
        Expanded(
          child: _QuickActionCard(
            icon: CupertinoIcons.bell_fill,
            label: 'Notify',
            color: AppColors.accent2,
            onTap: () => context.go(AppRoutes.adminManageNotifications),
          ),
        ),
        const SizedBox(width: AppConstants.padM),
        Expanded(
          child: _QuickActionCard(
            icon: CupertinoIcons.tag_fill,
            label: 'Promos',
            color: AppColors.success,
            onTap: () => context.go(AppRoutes.adminManagePromotions),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, ThemeData theme, AdminLoaded state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppConstants.padM,
          mainAxisSpacing: AppConstants.padM,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              theme: theme,
              title: 'Total Users',
              value: state.users.length.toString(),
              icon: CupertinoIcons.person_2_fill,
              color: AppColors.primary,
              onTap: () => context.go(AppRoutes.adminManageUsers),
            ),
            _StatCard(
              theme: theme,
              title: 'Total Salons',
              value: state.salons.length.toString(),
              icon: CupertinoIcons.building_2_fill,
              color: AppColors.accent,
              onTap: () => context.go(AppRoutes.adminManageSalons),
            ),
            _StatCard(
              theme: theme,
              title: 'Promotions',
              value: state.promotions.length.toString(),
              icon: CupertinoIcons.tag_fill,
              color: AppColors.success,
              onTap: () => context.go(AppRoutes.adminManagePromotions),
            ),
            _StatCard(
              theme: theme,
              title: 'Bookings',
              value: state.appointments.length.toString(),
              icon: CupertinoIcons.calendar,
              color: AppColors.accent2,
              onTap: () => context.go(AppRoutes.adminManageTransactions),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserBreakdown(
      BuildContext context, ThemeData theme, AdminLoaded state) {
    final adminCount = state.users.where((u) => u.role == 'admin').length;
    final ownerCount = state.users.where((u) => u.role == 'owner').length;
    final clientCount = state.users.where((u) => u.role == 'client').length;
    final total = state.users.length;

    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppConstants.radiusL,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _UserBreakdownRow(
            label: 'Admins',
            count: adminCount,
            total: total,
            color: AppColors.error,
            icon: CupertinoIcons.shield_lefthalf_fill,
          ),
          const Divider(height: 24),
          _UserBreakdownRow(
            label: 'Salon Owners',
            count: ownerCount,
            total: total,
            color: AppColors.accent2,
            icon: CupertinoIcons.briefcase_fill,
          ),
          const Divider(height: 24),
          _UserBreakdownRow(
            label: 'Clients',
            count: clientCount,
            total: total,
            color: AppColors.success,
            icon: CupertinoIcons.person_fill,
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCards(BuildContext context, ThemeData theme) {
    return Column(
      children: [
        _ManagementCard(
          icon: CupertinoIcons.calendar,
          title: 'View All Bookings',
          subtitle: 'Appointments across every salon',
          color: AppColors.primary,
          onTap: () => context.go(AppRoutes.adminManageTransactions),
        ),
        const SizedBox(height: AppConstants.padM),
        _ManagementCard(
          icon: CupertinoIcons.bell_fill,
          title: 'Send Notification',
          subtitle: 'Push notifications to users',
          color: AppColors.accent2,
          onTap: () => context.go(AppRoutes.adminManageNotifications),
        ),
        const SizedBox(height: AppConstants.padM),
        _ManagementCard(
          icon: CupertinoIcons.tag_fill,
          title: 'Manage Promotions',
          subtitle: 'Platform promotions & offers',
          color: AppColors.success,
          onTap: () => context.go(AppRoutes.adminManagePromotions),
        ),
      ],
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.padM),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppConstants.radiusL,
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.theme,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.padM),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppConstants.radiusL,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (onTap != null)
                  Icon(
                    CupertinoIcons.chevron_forward,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserBreakdownRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;
  final IconData icon;

  const _UserBreakdownRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: AppConstants.padM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: total > 0 ? count / total : 0,
                  backgroundColor: color.withValues(alpha: 0.1),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppConstants.padM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              count.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              '$percentage%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ManagementCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ManagementCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.padM),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppConstants.radiusL,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppConstants.padM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
