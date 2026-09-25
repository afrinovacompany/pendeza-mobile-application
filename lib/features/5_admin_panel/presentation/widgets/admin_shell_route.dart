import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/app/widgets/main_back_scope.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/widgets/admin_ui.dart';
import 'package:pendeza/shared/widgets/theme_mode_button.dart';
import 'package:pendeza/app/bloc/theme_cubit.dart';

class _NavDestination {
  final String route;
  final String label;
  final String shortLabel;
  final IconData icon;
  final IconData selectedIcon;

  const _NavDestination({
    required this.route,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.selectedIcon,
  });
}

// NOTE: Inspiration tab temporarily removed - will return in future months
const List<_NavDestination> _destinations = [
  _NavDestination(
    route: AppRoutes.adminHome,
    label: 'Dashboard',
    shortLabel: 'Home',
    icon: CupertinoIcons.chart_bar,
    selectedIcon: CupertinoIcons.chart_bar_fill,
  ),
  _NavDestination(
    route: AppRoutes.adminManageUsers,
    label: 'Users',
    shortLabel: 'Users',
    icon: CupertinoIcons.group,
    selectedIcon: CupertinoIcons.group_solid,
  ),
  _NavDestination(
    route: AppRoutes.adminManageSalons,
    label: 'Salons',
    shortLabel: 'Salons',
    icon: CupertinoIcons.building_2_fill,
    selectedIcon: CupertinoIcons.building_2_fill,
  ),
  _NavDestination(
    route: AppRoutes.adminManagePromotions,
    label: 'Promotions',
    shortLabel: 'Promos',
    icon: CupertinoIcons.tag,
    selectedIcon: CupertinoIcons.tag_fill,
  ),
  _NavDestination(
    route: AppRoutes.adminManageNotifications,
    label: 'Notifications',
    shortLabel: 'Alerts',
    icon: CupertinoIcons.bell,
    selectedIcon: CupertinoIcons.bell_fill,
  ),
  _NavDestination(
    route: AppRoutes.adminManageTransactions,
    label: 'Bookings',
    shortLabel: 'Bookings',
    icon: CupertinoIcons.calendar,
    selectedIcon: CupertinoIcons.calendar_today,
  ),
];

class AdminShellRoute extends StatefulWidget {
  final Widget child;
  const AdminShellRoute({super.key, required this.child});

  @override
  State<AdminShellRoute> createState() => _AdminShellRouteState();
}

class _AdminShellRouteState extends State<AdminShellRoute> {
  /// null = follow the viewport (open on large screens, icons-only otherwise).
  bool? _sidebarExtended;

  int _calculateCurrentIndex(String location) {
    final index =
        _destinations.indexWhere((d) => location.startsWith(d.route));
    return index < 0 ? 0 : index;
  }

  void _onDestinationSelected(int index) {
    context.go(_destinations[index].route);
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showAdminConfirmDialog(
      context,
      title: 'Sign out?',
      message: 'You will need to sign in again to manage Pendeza.',
      confirmLabel: 'Sign out',
      tone: AdminTone.danger,
      icon: CupertinoIcons.square_arrow_right,
    );
    if (confirmed && context.mounted) {
      context.read<AuthBloc>().add(SignOutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final currentIndex = _calculateCurrentIndex(currentRoute);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (currentRoute != AppRoutes.adminHome) {
          context.go(AppRoutes.adminHome);
        } else {
          confirmAndExitApp(context);
        }
      },
      child: BlocProvider(
        create: (context) => sl<AdminBloc>()..add(LoadAdminData()),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useSidebar =
                constraints.maxWidth >= AdminTheme.wideBreakpoint;
            final extended =
                _sidebarExtended ?? constraints.maxWidth >= 1150;

            return AdminShellScope(
              compact: !useSidebar,
              onLogout: () => _confirmLogout(context),
              child: Scaffold(
                backgroundColor: AdminTheme.background(context),
                body: Row(
                  children: [
                    if (useSidebar)
                      _AdminSidebar(
                        currentIndex: currentIndex,
                        extended: extended,
                        onSelected: _onDestinationSelected,
                        onToggle: () =>
                            setState(() => _sidebarExtended = !extended),
                        onLogout: () => _confirmLogout(context),
                      ),
                    Expanded(child: widget.child),
                  ],
                ),
                bottomNavigationBar: useSidebar
                    ? null
                    : _AdminBottomBar(
                        currentIndex: currentIndex,
                        onSelected: _onDestinationSelected,
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SIDEBAR (tablet / desktop)
// ═════════════════════════════════════════════════════════════════════════════

class _AdminSidebar extends StatelessWidget {
  final int currentIndex;
  final bool extended;
  final ValueChanged<int> onSelected;
  final VoidCallback onToggle;
  final VoidCallback onLogout;

  const _AdminSidebar({
    required this.currentIndex,
    required this.extended,
    required this.onSelected,
    required this.onToggle,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: extended ? 252 : 84,
      decoration: BoxDecoration(
        color: AdminTheme.card(context),
        border: Border(
          right: BorderSide(color: AdminTheme.border(context)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SidebarBrand(extended: extended),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < _destinations.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _SidebarItem(
                          destination: _destinations[i],
                          selected: i == currentIndex,
                          extended: extended,
                          onTap: () => onSelected(i),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(height: 24, color: AdminTheme.border(context)),
              _SidebarAction(
                icon: extended
                    ? CupertinoIcons.sidebar_left
                    : CupertinoIcons.sidebar_right,
                label: extended ? 'Collapse' : 'Expand',
                extended: extended,
                onTap: onToggle,
              ),
              const SizedBox(height: 4),
              BlocBuilder<ThemeCubit, ThemeMode>(
                builder: (context, mode) => _SidebarAction(
                  icon: themeModeIcon(mode),
                  label: 'appearance.title'.tr(),
                  extended: extended,
                  onTap: () => showThemeModeSheet(context),
                ),
              ),
              const SizedBox(height: 4),
              _SidebarAction(
                icon: CupertinoIcons.square_arrow_right,
                label: 'Sign out',
                extended: extended,
                tone: AdminTone.danger,
                onTap: onLogout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarBrand extends StatelessWidget {
  final bool extended;
  const _SidebarBrand({required this.extended});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment:
          extended ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        const AdminIconTile(
          icon: CupertinoIcons.shield_lefthalf_fill,
          gradient: true,
          size: 44,
        ),
        if (extended) ...[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pendeza',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.heading(context).copyWith(fontSize: 18),
                ),
                Text(
                  'Admin console',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AdminTheme.caption(context),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final _NavDestination destination;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.destination,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AdminTheme.toneInk(context, AdminTone.primary)
        : AdminTheme.textSecondary(context);

    final content = Row(
      mainAxisAlignment:
          extended ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        Icon(
          selected ? destination.selectedIcon : destination.icon,
          size: 22,
          color: color,
        ),
        if (extended) ...[
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              destination.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ),
          if (selected)
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ],
    );

    return Tooltip(
      message: extended ? '' : destination.label,
      child: Material(
        color: selected
            ? AdminTheme.toneTint(context, AdminTone.primary, alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(height: 48, child: content),
          ),
        ),
      ),
    );
  }
}

class _SidebarAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool extended;
  final AdminTone tone;
  final VoidCallback onTap;

  const _SidebarAction({
    required this.icon,
    required this.label,
    required this.extended,
    required this.onTap,
    this.tone = AdminTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final color = AdminTheme.toneInk(context, tone);
    return Tooltip(
      message: extended ? '' : label,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: extended
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: color),
                if (extended) ...[
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BOTTOM BAR (phones)
// ═════════════════════════════════════════════════════════════════════════════

class _AdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const _AdminBottomBar({
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AdminTheme.card(context),
        border: Border(top: BorderSide(color: AdminTheme.border(context))),
      ),
      child: SafeArea(
        top: false,
        child: MediaQuery.withClampedTextScaling(
          // Six labels share the width; keep them on one line.
          maxScaleFactor: 1.15,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
            child: Row(
              children: [
                for (var i = 0; i < _destinations.length; i++)
                  Expanded(
                    child: _BottomItem(
                      destination: _destinations[i],
                      selected: i == currentIndex,
                      onTap: () => onSelected(i),
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

class _BottomItem extends StatelessWidget {
  final _NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _BottomItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AdminTheme.toneInk(context, AdminTone.primary)
        : AdminTheme.textSecondary(context);

    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: selected
                    ? AdminTheme.toneTint(context, AdminTone.primary,
                        alpha: 0.16)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                selected ? destination.selectedIcon : destination.icon,
                size: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              destination.shortLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
