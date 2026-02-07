import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_event.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_bloc.dart';
import 'package:pendeza/features/5_admin_panel/presentation/bloc/admin_event.dart';

class AdminShellRoute extends StatefulWidget {
  final Widget child;
  const AdminShellRoute({super.key, required this.child});

  @override
  State<AdminShellRoute> createState() => _AdminShellRouteState();
}

class _AdminShellRouteState extends State<AdminShellRoute> {
  bool _isRailExtended = false;

  // NOTE: Inspiration tab temporarily removed - will return in future months
  int _calculateCurrentIndex(String location) {
    if (location.startsWith(AppRoutes.adminHome)) return 0;
    if (location.startsWith(AppRoutes.adminManageUsers)) return 1;
    if (location.startsWith(AppRoutes.adminManageSalons)) return 2;
    if (location.startsWith(AppRoutes.adminManagePromotions)) return 3;
    if (location.startsWith(AppRoutes.adminManageNotifications)) return 4;
    if (location.startsWith(AppRoutes.adminManageTransactions)) return 5;
    return 0;
  }

  void _onDestinationSelected(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.adminHome);
        break;
      case 1:
        context.go(AppRoutes.adminManageUsers);
        break;
      case 2:
        context.go(AppRoutes.adminManageSalons);
        break;
      case 3:
        context.go(AppRoutes.adminManagePromotions);
        break;
      case 4:
        context.go(AppRoutes.adminManageNotifications);
        break;
      case 5:
        context.go(AppRoutes.adminManageTransactions);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 12),
            Text('Logout'),
          ],
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(SignOutRequested());
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final currentIndex = _calculateCurrentIndex(currentRoute);

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (currentRoute != AppRoutes.adminHome) {
          context.go(AppRoutes.adminHome);
        } else {
          SystemNavigator.pop();
        }
      },
      child: BlocProvider(
        create: (context) => sl<AdminBloc>()..add(LoadAdminData()),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool useRail = constraints.maxWidth >= 850;
            return Scaffold(
              appBar: useRail
                  ? null
                  : AppBar(
                title: const Text('Admin Panel'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    onPressed: () => _showLogoutDialog(context),
                    tooltip: 'Logout',
                  ),
                ],
              ),
              body: Row(
                children: [
                  if (useRail)
                    _buildNavigationRail(
                      context,
                      currentIndex,
                    ),
                  Expanded(child: widget.child),
                ],
              ),
              bottomNavigationBar: useRail
                  ? null
                  : _buildBottomNav(
                context,
                currentIndex,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context, int currentIndex) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) => _onDestinationSelected(index, context),
      extended: _isRailExtended,
      minWidth: 80,
      backgroundColor:
      isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
      elevation: 2,
      leading: Column(
        children: [
          const SizedBox(height: AppConstants.padL),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.shield_lefthalf_fill,
                color: theme.colorScheme.primary,
                size: 32,
              ),
              if (_isRailExtended) ...[
                const SizedBox(width: AppConstants.padS),
                Text(
                  'Pendeza',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: AppConstants.padM),
              ]
            ],
          ),
          const SizedBox(height: AppConstants.padS),
          IconButton(
            icon: Icon(
              _isRailExtended
                  ? CupertinoIcons.chevron_back
                  : CupertinoIcons.chevron_forward,
            ),
            onPressed: () {
              setState(() {
                _isRailExtended = !_isRailExtended;
              });
            },
          ),
          const SizedBox(height: AppConstants.padS),
          const Divider(height: 1),
        ],
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.padM),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: _isRailExtended ? const Text('Logout') : null,
              onTap: () => _showLogoutDialog(context),
            ),
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(CupertinoIcons.chart_bar),
          selectedIcon: Icon(CupertinoIcons.chart_bar_fill),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(CupertinoIcons.group),
          selectedIcon: Icon(CupertinoIcons.group_solid),
          label: Text('Users'),
        ),
        NavigationRailDestination(
          icon: Icon(CupertinoIcons.building_2_fill),
          selectedIcon: Icon(CupertinoIcons.building_2_fill),
          label: Text('Salons'),
        ),
        NavigationRailDestination(
          icon: Icon(CupertinoIcons.tag),
          selectedIcon: Icon(CupertinoIcons.tag_fill),
          label: Text('Promotions'),
        ),
        NavigationRailDestination(
          icon: Icon(CupertinoIcons.bell),
          selectedIcon: Icon(CupertinoIcons.bell_fill),
          label: Text('Notifications'),
        ),
        NavigationRailDestination(
          icon: Icon(CupertinoIcons.creditcard),
          selectedIcon: Icon(CupertinoIcons.creditcard_fill),
          label: Text('Transactions'),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context, int currentIndex) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) => _onDestinationSelected(index, context),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 10,
      unselectedFontSize: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.chart_bar),
          activeIcon: Icon(CupertinoIcons.chart_bar_fill),
          label: 'Dash',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.group),
          activeIcon: Icon(CupertinoIcons.group_solid),
          label: 'Users',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.building_2_fill),
          activeIcon: Icon(CupertinoIcons.building_2_fill),
          label: 'Salons',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.tag),
          activeIcon: Icon(CupertinoIcons.tag_fill),
          label: 'Promos',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.bell),
          activeIcon: Icon(CupertinoIcons.bell_fill),
          label: 'Notifs',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.creditcard),
          activeIcon: Icon(CupertinoIcons.creditcard_fill),
          label: 'Trans',
        ),
      ],
    );
  }
}