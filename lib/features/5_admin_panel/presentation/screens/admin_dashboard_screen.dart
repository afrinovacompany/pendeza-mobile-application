import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_state.dart';
import 'package:pendeza/features/5_admin_panel/presentation/widgets/admin_ui.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Dashboard',
      subtitle: DateFormat('EEEE, d MMMM').format(DateTime.now()),
      icon: CupertinoIcons.shield_lefthalf_fill,
      child: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          if (state is AdminLoading || state is AdminInitial) {
            return const AdminLoadingState(count: 5, itemHeight: 110);
          }
          if (state is AdminError) {
            return AdminErrorState(
              message: state.message,
              onRetry: () => context.read<AdminBloc>().add(LoadAdminData()),
            );
          }
          if (state is AdminLoaded) {
            return RefreshIndicator(
              color: Theme.of(context).colorScheme.primary,
              onRefresh: () async {
                final bloc = context.read<AdminBloc>();
                bloc.add(LoadAdminData());
                await bloc.stream.firstWhere(
                  (s) => s is AdminLoaded || s is AdminError,
                );
              },
              child: _DashboardBody(state: state),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final AdminLoaded state;
  const _DashboardBody({required this.state});

  @override
  Widget build(BuildContext context) {
    final gutter = AdminTheme.gutter(MediaQuery.sizeOf(context).width);
    final pending = state.salons.where((s) => s.isPending).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 32),
      children: [
        _HeroCard(state: state),
        if (pending > 0) ...[
          const SizedBox(height: 16),
          _AttentionCard(pending: pending),
        ],
        const SizedBox(height: 28),
        const AdminSectionHeader(title: 'Platform overview'),
        const SizedBox(height: 12),
        _ResponsiveGrid(
          minTileWidth: 168,
          maxColumns: 4,
          children: [
            AdminStatTile(
              icon: CupertinoIcons.person_2_fill,
              label: 'Total users',
              value: '${state.users.length}',
              tone: AdminTone.primary,
              onTap: () => context.go(AppRoutes.adminManageUsers),
            ),
            AdminStatTile(
              icon: CupertinoIcons.building_2_fill,
              label: 'Salons',
              value: '${state.salons.length}',
              tone: AdminTone.accent,
              onTap: () => context.go(AppRoutes.adminManageSalons),
            ),
            AdminStatTile(
              icon: CupertinoIcons.tag_fill,
              label: 'Promotions',
              value: '${state.promotions.length}',
              tone: AdminTone.success,
              onTap: () => context.go(AppRoutes.adminManagePromotions),
            ),
            AdminStatTile(
              icon: CupertinoIcons.calendar,
              label: 'Bookings',
              value: '${state.appointments.length}',
              tone: AdminTone.info,
              onTap: () => context.go(AppRoutes.adminManageTransactions),
            ),
          ],
        ),
        const SizedBox(height: 28),
        _ResponsiveGrid(
          minTileWidth: 340,
          maxColumns: 2,
          children: [
            _BreakdownCard(
              title: 'People',
              subtitle: 'Accounts by role',
              segments: [
                _Segment(
                  'Clients',
                  state.users.where((u) => u.role == 'client').length,
                  AdminTone.success,
                ),
                _Segment(
                  'Salon owners',
                  state.users.where((u) => u.role == 'owner').length,
                  AdminTone.info,
                ),
                _Segment(
                  'Admins',
                  state.users.where((u) => u.role == 'admin').length,
                  AdminTone.danger,
                ),
              ],
            ),
            _BreakdownCard(
              title: 'Salon approvals',
              subtitle: 'Verification status',
              segments: [
                _Segment(
                  'Approved',
                  state.salons.where((s) => s.isApproved).length,
                  AdminTone.success,
                ),
                _Segment(
                  'Pending',
                  state.salons.where((s) => s.isPending).length,
                  AdminTone.warning,
                ),
                _Segment(
                  'Rejected',
                  state.salons.where((s) => s.isRejected).length,
                  AdminTone.danger,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        const AdminSectionHeader(title: 'Shortcuts'),
        const SizedBox(height: 12),
        _ResponsiveGrid(
          minTileWidth: 320,
          maxColumns: 2,
          children: [
            _ShortcutTile(
              icon: CupertinoIcons.bell_fill,
              title: 'Send notification',
              subtitle: 'Push a message to users',
              tone: AdminTone.info,
              onTap: () => context.go(AppRoutes.adminManageNotifications),
            ),
            _ShortcutTile(
              icon: CupertinoIcons.tag_fill,
              title: 'Manage promotions',
              subtitle: 'Platform offers & banners',
              tone: AdminTone.success,
              onTap: () => context.go(AppRoutes.adminManagePromotions),
            ),
            _ShortcutTile(
              icon: CupertinoIcons.checkmark_seal_fill,
              title: 'Review salons',
              subtitle: 'Approve or reject applications',
              tone: AdminTone.accent,
              onTap: () => context.go(AppRoutes.adminManageSalons),
            ),
            _ShortcutTile(
              icon: CupertinoIcons.calendar_today,
              title: 'All bookings',
              subtitle: 'Appointments across every salon',
              tone: AdminTone.primary,
              onTap: () => context.go(AppRoutes.adminManageTransactions),
            ),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HERO
// ═════════════════════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  final AdminLoaded state;
  const _HeroCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -6,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: _Bubble(size: 170, alpha: 0.10),
            ),
            Positioned(
              right: 50,
              bottom: -70,
              child: _Bubble(size: 130, alpha: 0.07),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'WELCOME BACK',
                    style: _heroText(11, FontWeight.w700, 0.7)
                        .copyWith(letterSpacing: 1.2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Here’s how Pendeza is doing',
                    style: _heroText(20, FontWeight.w700, 1),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _HeroStat(
                        value: '${state.users.length}',
                        label: 'Users',
                        icon: CupertinoIcons.person_2_fill,
                      ),
                      const _HeroDivider(),
                      _HeroStat(
                        value: '${state.salons.length}',
                        label: 'Salons',
                        icon: CupertinoIcons.building_2_fill,
                      ),
                      const _HeroDivider(),
                      _HeroStat(
                        value: '${state.appointments.length}',
                        label: 'Bookings',
                        icon: CupertinoIcons.calendar,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static TextStyle _heroText(double size, FontWeight weight, double alpha) =>
      TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: size,
        fontWeight: weight,
        height: 1.25,
        color: Colors.white.withValues(alpha: alpha),
      );
}

class _Bubble extends StatelessWidget {
  final double size;
  final double alpha;
  const _Bubble({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

class _HeroStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _HeroStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _HeroCard._heroText(12, FontWeight.w500, 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: _HeroCard._heroText(26, FontWeight.w700, 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  const _HeroDivider();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 14),
        color: Colors.white.withValues(alpha: 0.22),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// ATTENTION
// ═════════════════════════════════════════════════════════════════════════════

class _AttentionCard extends StatelessWidget {
  final int pending;
  const _AttentionCard({required this.pending});

  @override
  Widget build(BuildContext context) {
    final ink = AdminTheme.toneInk(context, AdminTone.warning);
    return AdminCard(
      color: AdminTheme.toneSurface(context, AdminTone.warning),
      borderColor:
          AdminTheme.toneBase(context, AdminTone.warning).withValues(alpha: 0.45),
      onTap: () => context.go(AppRoutes.adminManageSalons, extra: 'pending'),
      child: Row(
        children: [
          const AdminIconTile(
            icon: CupertinoIcons.hourglass,
            tone: AdminTone.warning,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending == 1
                      ? '1 salon is waiting for approval'
                      : '$pending salons are waiting for approval',
                  style: AdminTheme.body(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review them so they become visible to clients.',
                  style: AdminTheme.caption(context),
                ),
              ],
            ),
          ),
          Icon(CupertinoIcons.chevron_forward, size: 18, color: ink),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BREAKDOWN
// ═════════════════════════════════════════════════════════════════════════════

class _Segment {
  final String label;
  final int count;
  final AdminTone tone;
  const _Segment(this.label, this.count, this.tone);
}

class _BreakdownCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_Segment> segments;

  const _BreakdownCard({
    required this.title,
    required this.subtitle,
    required this.segments,
  });

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (sum, s) => sum + s.count);

    return AdminCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(
            title: title,
            subtitle: subtitle,
            trailing: Text(
              '$total',
              style: AdminTheme.title(context).copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: SizedBox(
              height: 10,
              child: total == 0
                  ? ColoredBox(color: AdminTheme.inset(context))
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final s in segments)
                          if (s.count > 0)
                            Expanded(
                              flex: s.count,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: ColoredBox(
                                  color: AdminTheme.toneBase(context, s.tone),
                                ),
                              ),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < segments.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _LegendRow(segment: segments[i], total: total),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final _Segment segment;
  final int total;
  const _LegendRow({required this.segment, required this.total});

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : (segment.count / total * 100).round();
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: AdminTheme.toneBase(context, segment.tone),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(segment.label, style: AdminTheme.body(context))),
        Text(
          '${segment.count}',
          style: AdminTheme.body(context).copyWith(fontWeight: FontWeight.w700),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$percent%',
            textAlign: TextAlign.right,
            style: AdminTheme.caption(context),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SHORTCUTS + LAYOUT
// ═════════════════════════════════════════════════════════════════════════════

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final AdminTone tone;
  final VoidCallback onTap;

  const _ShortcutTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      child: Row(
        children: [
          AdminIconTile(icon: icon, tone: tone),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.body(context)
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.caption(context),
                ),
              ],
            ),
          ),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: AdminTheme.textSecondary(context),
          ),
        ],
      ),
    );
  }
}

/// Lays children out in equal-width columns that adapt to the available
/// width (no fixed aspect ratios, so tiles never overflow with large text).
class _ResponsiveGrid extends StatelessWidget {
  final double minTileWidth;
  final int maxColumns;
  final List<Widget> children;

  const _ResponsiveGrid({
    required this.minTileWidth,
    required this.maxColumns,
    required this.children,
  });

  static const double spacing = 12;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        var columns = ((available + spacing) / (minTileWidth + spacing))
            .floor()
            .clamp(1, maxColumns);
        if (columns > children.length) columns = children.length;
        final tileWidth = (available - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final child in children)
              SizedBox(width: tileWidth, child: child),
          ],
        );
      },
    );
  }
}
