import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/cupertino.dart';

import '../app/config/app_router.dart';
import '../app/widgets/adaptive/adaptive_bottom_nav.dart';
import '../app/widgets/main_back_scope.dart';
import '../app/utils/navigation_guard.dart';

// Import the Appointments Bloc
import '../features/2_client_appointments/presentation/bloc/appointments_bloc.dart';
// Note: Using the exact file name provided in your project
import '../features/2_client_appointments/presentation/bloc/appoitments_state.dart';

// Import tab screens for PageView
import '../features/2_client_dashboard/presentation/screens/client_dashboard_screen.dart';
import '../features/2_client_discovery/presentation/screens/discovery_screen.dart';
import '../features/2_client_appointments/presentation/screens/appointments_screen.dart';
import '../features/2_client_profile/presentation/screens/profile_screen.dart';
import '../features/3_owner_management/dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../features/3_owner_management/calendar/presentation/screens/calendar_screen.dart';
import '../features/3_owner_management/services/presentation/screens/service_list_screen.dart';
import '../features/3_owner_management/clients/presentation/screens/client_management_screen.dart';
import '../features/3_owner_profile_screen/owner_profile_screen.dart';
import '../features/3_owner_management/services/presentation/bloc/services_bloc.dart';
import '../app/services/service_locator.dart';

// --- Main tab routes for matching ---
const _clientTabRoutes = [
  AppRoutes.clientHome,
  AppRoutes.clientDiscover,
  AppRoutes.clientBookings,
  AppRoutes.clientProfile,
];

const _ownerTabRoutes = [
  AppRoutes.ownerHome,
  AppRoutes.ownerSchedule,
  AppRoutes.ownerServices,
  AppRoutes.ownerClients,
  AppRoutes.ownerProfile,
];

// --- OWNER NAV ITEMS ---
// NOTE: Inspiration tab temporarily removed - will return in future months
final ownerNavItems = [
  const AdaptiveNavItem(
    icon: CupertinoIcons.chart_bar,
    activeIcon: CupertinoIcons.chart_bar_fill,
    label: 'Home',
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
  late PageController _pageController;
  bool _isSwiping = false;
  bool _isSyncing = false;
  bool _wasOnMainTab = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Check if the current route is a main tab route (swipeable).
  bool _isMainTabRoute(String location) {
    final tabRoutes = widget.userRole == 'client'
        ? _clientTabRoutes
        : _ownerTabRoutes;
    return tabRoutes.any((route) => location == route || location == '$route/');
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

  void _goToRoute(int index) {
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
  }

  void _onItemTapped(int index, BuildContext context) {
    guardedNavigate(() {
      // Animate the PageView then update the route
      if (_pageController.hasClients) {
        _isSwiping = true;
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        ).then((_) {
          _isSwiping = false;
        });
      }
      _goToRoute(index);
    });
  }

  void _onPageChanged(int index) {
    if (_isSwiping || _isSyncing) return; // Skip during tab tap or sync
    guardedNavigate(() {
      _goToRoute(index);
    });
  }

  List<Widget> _buildClientPages() {
    return const [
      ClientDashboardScreen(),
      DiscoveryScreen(),
      AppointmentsScreen(),
      ClientProfileScreen(),
    ];
  }

  List<Widget> _buildOwnerPages() {
    return [
      const OwnerDashboardScreen(),
      const CalendarScreen(),
      BlocProvider(
        create: (context) => sl<ServicesBloc>(),
        child: const ServiceListScreen(),
      ),
      const ClientManagementScreen(),
      const OwnerProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _calculateSelectedIndex(context);
    final String location = GoRouterState.of(context).uri.path;
    final isOnMainTab = _isMainTabRoute(location);

    // Sync PageController with current tab when navigating via route
    if (isOnMainTab && !_wasOnMainTab) {
      // Transitioning from non-tab route (e.g. /client/categories) to a tab route.
      // Recreate the controller at the correct page to avoid showing the wrong tab.
      _isSyncing = true;
      _pageController.dispose();
      _pageController = PageController(initialPage: currentIndex);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _isSyncing = false;
      });
    } else if (isOnMainTab &&
        _pageController.hasClients &&
        _pageController.page?.round() != currentIndex) {
      // Already on tabs but route changed (e.g. programmatic navigation).
      _isSyncing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients && mounted) {
          _pageController.jumpToPage(currentIndex);
        }
        _isSyncing = false;
      });
    }
    _wasOnMainTab = isOnMainTab;

    final homeRoute = widget.userRole == 'client'
        ? AppRoutes.clientHome
        : AppRoutes.ownerHome;
    final canPopSecondary = !isOnMainTab && context.canPop();

    return MainBackScope(
      isOnMainTab: isOnMainTab,
      currentIndex: currentIndex,
      canPopSecondary: canPopSecondary,
      onLeaveSecondary: () => context.go(homeRoute),
      onGoHome: () => _goToRoute(0),
      child: Scaffold(
        body: isOnMainTab
            ? PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: widget.userRole == 'client'
                    ? _buildClientPages()
                    : _buildOwnerPages(),
              )
            : widget.child,
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
                    currentIndex: currentIndex,
                    onTap: (index) => _onItemTapped(index, context),
                  );
                },
              )
            : AdaptiveBottomNavBar(
                items: ownerNavItems,
                currentIndex: currentIndex,
                onTap: (index) => _onItemTapped(index, context),
                height: 60,
                labelSize: 10,
                iconSize: 22,
              ),
      ),
    );
  }
}