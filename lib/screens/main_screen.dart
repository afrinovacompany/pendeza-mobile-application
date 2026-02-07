import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';

import '../app/config/app_router.dart';
import '../app/widgets/adaptive/adaptive_bottom_nav.dart';
import '../app/widgets/adaptive/adaptive_dialog.dart';
import '../app/utils/navigation_guard.dart';

// Import the Appointments Bloc
import '../features/2_client_appointments/presentation/bloc/appointments_bloc.dart';
// Note: Using the exact file name provided in your project
import '../features/2_client_appointments/presentation/bloc/appoitments_state.dart';

// --- OWNER NAV ITEMS ---
// NOTE: Inspiration tab temporarily removed - will return in future months
final ownerNavItems = [
  const AdaptiveNavItem(
    icon: CupertinoIcons.chart_bar,
    activeIcon: CupertinoIcons.chart_bar_fill,
    label: 'Dashboard',
  ),
  const AdaptiveNavItem(
    icon: CupertinoIcons.calendar,
    activeIcon: CupertinoIcons.calendar_circle_fill,
    label: 'Schedule',
  ),
  const AdaptiveNavItem(
    icon: CupertinoIcons.scissors,
    activeIcon: CupertinoIcons.scissors,
    label: 'Services',
  ),
  const AdaptiveNavItem(
    icon: CupertinoIcons.group,
    activeIcon: CupertinoIcons.group_solid,
    label: 'Clients',
  ),
  const AdaptiveNavItem(
    icon: CupertinoIcons.person,
    activeIcon: CupertinoIcons.person_solid,
    label: 'Profile',
  ),
];

class MainScreen extends StatefulWidget {
  final Widget child;
  final String userRole;

  const MainScreen({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with NavigationGuard {
  Future<void> _showExitConfirmation() async {
    final shouldExit = await showAdaptiveConfirmDialog(
      context: context,
      title: 'Exit Pendeza?',
      content: 'Are you sure you want to leave the app?',
      confirmText: 'Exit',
      cancelText: 'Stay',
      isDestructive: true,
    );
    if (shouldExit && mounted) {
      SystemNavigator.pop();
    }
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    if (widget.userRole == 'client') {
      if (location.startsWith(AppRoutes.clientHome)) return 0;
      if (location.startsWith(AppRoutes.clientDiscover)) return 1;
      if (location.startsWith(AppRoutes.clientBookings)) return 2;
      if (location.startsWith(AppRoutes.clientProfile)) return 3;
    } else {
      if (location.startsWith(AppRoutes.ownerHome)) return 0;
      if (location.startsWith(AppRoutes.ownerSchedule)) return 1;
      if (location.startsWith(AppRoutes.ownerServices)) return 2;
      if (location.startsWith(AppRoutes.ownerClients)) return 3;
      if (location.startsWith(AppRoutes.ownerProfile)) return 4;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    // Prevent double navigation on rapid tab switching
    guardedNavigate(() {
      if (widget.userRole == 'client') {
        switch (index) {
          case 0: context.go(AppRoutes.clientHome); break;
          case 1: context.go(AppRoutes.clientDiscover); break;
          case 2: context.go(AppRoutes.clientBookings); break;
          case 3: context.go(AppRoutes.clientProfile); break;
        }
      } else {
        switch (index) {
          case 0: context.go(AppRoutes.ownerHome); break;
          case 1: context.go(AppRoutes.ownerSchedule); break;
          case 2: context.go(AppRoutes.ownerServices); break;
          case 3: context.go(AppRoutes.ownerClients); break;
          case 4: context.go(AppRoutes.ownerProfile); break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmation();
      },
      child: Scaffold(
      body: widget.child,
      bottomNavigationBar: widget.userRole == 'client'
          ? BlocBuilder<AppointmentsBloc, AppointmentsState>(
        builder: (context, state) {
          int? badgeCount;
          if (state is AppointmentsLoaded) {
            final count = state.activeAppointmentsCount;
            if (count > 0) badgeCount = count;
          }

          final clientNavItems = [
            const AdaptiveNavItem(
              icon: CupertinoIcons.home,
              activeIcon: CupertinoIcons.house_fill,
              label: 'Home',
            ),
            const AdaptiveNavItem(
              icon: CupertinoIcons.compass,
              activeIcon: CupertinoIcons.compass_fill,
              label: 'Discover',
            ),
            AdaptiveNavItem(
              icon: CupertinoIcons.calendar,
              activeIcon: CupertinoIcons.calendar_today,
              label: 'Bookings',
              badge: badgeCount,
            ),
            const AdaptiveNavItem(
              icon: CupertinoIcons.person,
              activeIcon: CupertinoIcons.person_fill,
              label: 'Profile',
            ),
          ];

          return AdaptiveBottomNav(
            items: clientNavItems,
            currentIndex: _calculateSelectedIndex(context),
            onTap: (index) => _onItemTapped(index, context),
          );
        },
      )
          : AdaptiveBottomNav(
        items: ownerNavItems,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    ),
    );
  }
}