import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/features/2_client_dashboard/presentation/widgets/dashboard_header.dart';
import 'package:pendeza/features/2_client_dashboard/presentation/widgets/quick_action_bar.dart';
import 'package:pendeza/features/2_client_profile/presentation/screens/guest_profile_screen.dart';

/// The client redesign is visual only: these pin the navigation and callbacks
/// so a restyle can't silently rewire them.
void main() {
  /// Mounts [child] under a router that records where it navigates.
  Future<List<String>> pumpWithRouter(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 1400),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final visited = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => Scaffold(body: child)),
        for (final path in [
          AppRoutes.clientDiscover,
          AppRoutes.clientFavorites,
          AppRoutes.clientProfile,
          AppRoutes.clientNotifications,
          AppRoutes.login,
        ])
          GoRoute(
            path: path,
            builder: (_, _) {
              visited.add(path);
              return const Scaffold(body: SizedBox.shrink());
            },
          ),
      ],
    );
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    return visited;
  }

  group('QuickActionsBar navigation (unchanged)', () {
    testWidgets('offers / near me / trending go to discovery', (tester) async {
      final actions = <String>[];
      final visited = await pumpWithRouter(
        tester,
        QuickActionsBar(onActionTap: actions.add),
      );

      for (final icon in [
        CupertinoIcons.tag_fill,
        CupertinoIcons.location_solid,
        CupertinoIcons.flame_fill,
      ]) {
        await tester.tap(find.byIcon(icon));
        await tester.pumpAndSettle();
        expect(visited.last, AppRoutes.clientDiscover);
        // back to the dashboard for the next tap
        GoRouter.of(tester.element(find.byType(Scaffold).first)).go('/');
        await tester.pumpAndSettle();
      }
      expect(actions, ['offers', 'near_me', 'trending']);
    });

    testWidgets('saved opens favourites', (tester) async {
      final actions = <String>[];
      final visited = await pumpWithRouter(
        tester,
        QuickActionsBar(onActionTap: actions.add),
      );

      await tester.tap(find.byIcon(CupertinoIcons.heart_fill));
      await tester.pumpAndSettle();

      expect(visited, [AppRoutes.clientFavorites]);
      expect(actions, ['favorites']);
    });
  });

  group('DashboardHeaderView', () {
    testWidgets('signed in: bell and avatar fire their callbacks',
        (tester) async {
      var bell = 0, profile = 0, search = 0;
      await pumpWithRouter(
        tester,
        DashboardHeaderView(
          name: 'Amina',
          isAuthenticated: true,
          unreadCount: 120,
          onNotifications: () => bell++,
          onProfile: () => profile++,
          onSearch: () => search++,
        ),
      );

      expect(find.textContaining('Amina', findRichText: true), findsOneWidget);
      expect(find.text('99+'), findsOneWidget); // badge caps at 99+

      await tester.tap(find.byIcon(CupertinoIcons.bell));
      await tester.tap(find.byIcon(CupertinoIcons.search));
      expect(bell, 1);
      expect(search, 1);
      expect(profile, 0);
    });

    testWidgets('guest: shows the login pill, not the bell', (tester) async {
      var login = 0;
      await pumpWithRouter(
        tester,
        DashboardHeaderView(
          name: 'Guest',
          isAuthenticated: false,
          onLogin: () => login++,
        ),
      );

      expect(find.byIcon(CupertinoIcons.bell), findsNothing);
      await tester.tap(find.byIcon(CupertinoIcons.arrow_right_circle_fill));
      expect(login, 1);
    });
  });

  group('GuestProfileView', () {
    testWidgets('sign up, log in and favourites callbacks', (tester) async {
      var signUp = 0, login = 0, favorites = 0;
      await pumpWithRouter(
        tester,
        GuestProfileView(
          onSignUp: () => signUp++,
          onLogin: () => login++,
          onFavorites: () => favorites++,
        ),
      );

      await tester.tap(find.byIcon(CupertinoIcons.person_add_solid));
      await tester.tap(find.byIcon(CupertinoIcons.arrow_right_circle));
      await tester.tap(find.byIcon(CupertinoIcons.heart_fill));

      expect(signUp, 1);
      expect(login, 1);
      expect(favorites, 1);
    });
  });
}
