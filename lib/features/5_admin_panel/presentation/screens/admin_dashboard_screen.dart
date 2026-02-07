import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
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
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor:
        isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
        elevation: 1,
      ),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : theme.scaffoldBackgroundColor.withAlpha(245),
      body: BlocBuilder<AdminBloc, AdminState>(
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
                  Text(state.message),
                  const SizedBox(height: AppConstants.padM),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<AdminBloc>().add(LoadAdminData()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (state is AdminLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.padL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overview',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.padM),

                  // Stats Grid - FIXED: Proper responsive grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculate appropriate crossAxisCount based on width
                      int crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;

                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: AppConstants.padM,
                        mainAxisSpacing: AppConstants.padM,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        // FIXED: Increased ratio to prevent overflow
                        childAspectRatio: 1.5, // Was 1.4, now 1.5 for more height
                        children: [
                          _StatCard(
                            theme: theme,
                            title: 'Total Users',
                            value: state.users.length.toString(),
                            icon: CupertinoIcons.person_2_fill,
                            color: AppColors.primary,
                          ),
                          _StatCard(
                            theme: theme,
                            title: 'Total Salons',
                            value: state.salons.length.toString(),
                            icon: CupertinoIcons.building_2_fill,
                            color: AppColors.accent,
                          ),
                          _StatCard(
                            theme: theme,
                            title: 'Articles',
                            value: state.articles.length.toString(),
                            icon: CupertinoIcons.doc_text_fill,
                            color: AppColors.accent2,
                          ),
                          _StatCard(
                            theme: theme,
                            title: 'Lookbook',
                            value: state.lookbook.length.toString(),
                            icon: CupertinoIcons.photo_fill,
                            color: AppColors.success,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: AppConstants.padXL),

                  // Recent Activity
                  Text(
                    'Quick Stats',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppConstants.padM),

                  _buildQuickStat(
                    context,
                    'Admin Users',
                    state.users.where((u) => u.role == 'admin').length.toString(),
                    CupertinoIcons.shield_lefthalf_fill,
                    AppColors.error,
                  ),
                  _buildQuickStat(
                    context,
                    'Salon Owners',
                    state.users.where((u) => u.role == 'owner').length.toString(),
                    CupertinoIcons.briefcase_fill,
                    AppColors.accent2,
                  ),
                  _buildQuickStat(
                    context,
                    'Clients',
                    state.users.where((u) => u.role == 'client').length.toString(),
                    CupertinoIcons.person_fill,
                    AppColors.success,
                  ),
                ],
              ),
            );
          }
          return const Center(child: Text('Unknown state.'));
        },
      ),
    );
  }

  Widget _buildQuickStat(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padM),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(AppConstants.padS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppConstants.radiusS,
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          value,
          style: AppTextStyles.headline3.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
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
  final String? trend;
  final bool trendUp;

  const _StatCard({
    required this.theme,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.trendUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppConstants.durationMedium,
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: AppConstants.radiusL,
        boxShadow: AppColors.lightShadowSm,
        border: Border.all(
            color: Colors.grey.withAlpha((0.2 * 255).round())),
      ),
      // FIXED: Proper Column structure to prevent overflow
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top row (icon + trend) - FIXED: Constrained row
              SizedBox(
                height: 32, // Fixed height for icon row
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppConstants.padS),
                      decoration: BoxDecoration(
                        color: color.withAlpha((0.12 * 255).round()),
                        borderRadius: AppConstants.radiusS,
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const Spacer(),
                    if (trend != null)
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              trendUp
                                  ? CupertinoIcons.arrow_up
                                  : CupertinoIcons.arrow_down,
                              size: 12,
                              color: trendUp ? AppColors.success : AppColors.error,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                trend!,
                                style: AppTextStyles.caption.copyWith(
                                  color: trendUp ? AppColors.success : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              // Value - FIXED: Constrained text
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: AppTextStyles.headline3.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              // Title - FIXED: Flexible text with proper constraints
              Flexible(
                child: Text(
                  title,
                  style: AppTextStyles.caption.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha((0.6 * 255).round()),
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}