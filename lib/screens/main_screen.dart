import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/config/app_router.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

/// This widget is the "shell" for the main application screens.
/// It contains the BottomNavigationBar and the logic to navigate
/// between the main sections of the app.
class MainScreen extends StatelessWidget {
  /// The child widget (the current screen) to display above the navigation bar.
  final Widget child;

  /// The role of the current user, used to display the correct navigation bar.
  final String userRole;

  const MainScreen({
    super.key,
    required this.child,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    // The BlocListener has been removed. The GoRouter's redirect logic now
    // handles navigating to the login screen when the user is unauthenticated.
    return Scaffold(
      body: child, // The active screen is displayed here
      bottomNavigationBar: CustomBottomNavBar(
        // Show the correct nav items based on the user's role
        items: userRole == 'client' ? clientNavItems : ownerNavItems,
        currentIndex: _calculateCurrentIndex(context),
        onTap: (index) => _onItemTapped(index, context),
      ),
    );
  }

  /// Calculates the current index of the navigation bar based on the current route.
  /// The userRole is now implicitly handled by which routes are available.
  int _calculateCurrentIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;

    if (userRole == 'client') {
      if (location.startsWith(AppRoutes.clientHome)) return 0;
      if (location.startsWith(AppRoutes.clientDiscover)) return 1;
      if (location.startsWith(AppRoutes.clientBookings)) return 2;
      if (location.startsWith(AppRoutes.clientProfile)) return 3;
    } else { // Assumes 'owner'
      if (location.startsWith(AppRoutes.ownerHome)) return 0;
      if (location.startsWith(AppRoutes.ownerSchedule)) return 1;
      if (location.startsWith(AppRoutes.ownerServices)) return 2;
      if (location.startsWith(AppRoutes.ownerStaff)) return 3;
      if (location.startsWith(AppRoutes.ownerClients)) return 4;
    }

    return 0; // Default index
  }

  /// Navigates to the corresponding route when a navigation bar item is tapped.
  void _onItemTapped(int index, BuildContext context) {
    if (userRole == 'client') {
      switch (index) {
        case 0:
          context.go(AppRoutes.clientHome);
          break;
        case 1:
          context.go(AppRoutes.clientDiscover);
          break;
        case 2:
          context.go(AppRoutes.clientBookings);
          break;
        case 3:
          context.go(AppRoutes.clientProfile);
          break;
      }
    } else { // Assumes 'owner'
      switch (index) {
        case 0:
          context.go(AppRoutes.ownerHome);
          break;
        case 1:
          context.go(AppRoutes.ownerSchedule);
          break;
        case 2:
          context.go(AppRoutes.ownerServices);
          break;
        case 3:
          context.go(AppRoutes.ownerStaff);
          break;
        case 4:
          context.go(AppRoutes.ownerClients);
          break;
      }
    }
  }
}
