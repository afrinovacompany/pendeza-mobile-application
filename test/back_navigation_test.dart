import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/widgets/main_back_scope.dart';

/// System Back on the main tabs: Profile (or any other tab) -> Home, and Home
/// asks before closing the app. These run the real go_router back handling
/// (`handlePopRoute` is what Android's Back button/gesture ends up calling).

const _tabs = [
  '/client/home',
  '/client/discover',
  '/client/bookings',
  '/client/profile',
];

/// Same shape as the app's MainScreen: a shell page whose [MainBackScope]
/// decides what Back does.
class _Shell extends StatelessWidget {
  final Widget child;
  final void Function() onExit;

  const _Shell({required this.child, required this.onExit});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isOnMainTab = _tabs.contains(location);

    return MainBackScope(
      isOnMainTab: isOnMainTab,
      currentIndex: isOnMainTab ? _tabs.indexOf(location) : 0,
      canPopSecondary: !isOnMainTab && context.canPop(),
      onLeaveSecondary: () => context.go('/client/home'),
      onGoHome: () => context.go('/client/home'),
      onExit: (_) async => onExit(),
      child: Scaffold(body: child),
    );
  }
}

/// Runs [body] as if on [platform]; the override must be cleared before the
/// test ends, so it can't live in a tearDown.
Future<void> onPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

void main() {
  late List<String> exitRequests;
  late GoRouter router;

  String location() => router.routerDelegate.currentConfiguration.uri.path;

  Future<void> pumpApp(WidgetTester tester, {String start = '/client/home'}) {
    exitRequests = [];
    router = GoRouter(
      initialLocation: start,
      routes: [
        ShellRoute(
          pageBuilder:
              (context, state, child) => MaterialPage(
                child: _Shell(
                  onExit: () => exitRequests.add('exit'),
                  child: child,
                ),
              ),
          routes: [
            for (final path in [..._tabs, '/client/categories'])
              GoRoute(path: path, builder: (_, _) => Center(child: Text(path))),
          ],
        ),
      ],
    );
    return tester.pumpWidget(MaterialApp.router(routerConfig: router));
  }

  Future<void> back(WidgetTester tester) async {
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  group('Back on the main tabs', () {
    testWidgets('Profile goes to Home instead of closing the app', (
      tester,
    ) async {
      await pumpApp(tester, start: '/client/profile');
      expect(location(), '/client/profile');

      await back(tester);

      expect(location(), '/client/home');
      expect(
        exitRequests,
        isEmpty,
        reason: 'must not ask to exit from Profile',
      );
    });

    testWidgets('every other tab also goes to Home first', (tester) async {
      for (final tab in ['/client/discover', '/client/bookings']) {
        await pumpApp(tester, start: tab);
        await back(tester);
        expect(location(), '/client/home', reason: 'from $tab');
        expect(exitRequests, isEmpty);
      }
    });

    testWidgets('Home asks whether to close instead of closing straight away', (
      tester,
    ) async {
      await pumpApp(tester);

      await back(tester);

      expect(exitRequests, hasLength(1));
      expect(location(), '/client/home', reason: 'stays put behind the prompt');
    });

    testWidgets('Profile -> Home -> prompt on two Back presses', (
      tester,
    ) async {
      await pumpApp(tester, start: '/client/profile');

      await back(tester);
      expect(location(), '/client/home');
      expect(exitRequests, isEmpty);

      await back(tester);
      expect(exitRequests, hasLength(1));
    });

    testWidgets('a screen opened on top of a tab just goes back to it', (
      tester,
    ) async {
      await pumpApp(tester, start: '/client/profile');
      unawaited(router.push('/client/categories'));
      await tester.pumpAndSettle();
      expect(find.text('/client/categories'), findsOneWidget);

      await back(tester);

      expect(find.text('/client/categories'), findsNothing);
      expect(
        find.text('/client/profile'),
        findsOneWidget,
        reason: 'back to the tab it was opened from, not Home',
      );
      expect(exitRequests, isEmpty);
    });

    testWidgets('a screen with nothing to go back to lands on Home', (
      tester,
    ) async {
      await pumpApp(tester, start: '/client/categories');

      await back(tester);

      expect(location(), '/client/home');
      expect(exitRequests, isEmpty);
    });
  });

  group('confirmAndExitApp', () {
    late int systemPops;

    setUp(() {
      systemPops = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'SystemNavigator.pop') systemPops++;
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    Future<void> pumpTrigger(WidgetTester tester) => tester.pumpWidget(
      PlatformProvider(
        builder:
            (context) => MaterialApp(
              home: Builder(
                builder:
                    (context) => Scaffold(
                      body: Center(
                        child: TextButton(
                          onPressed: () => confirmAndExitApp(context),
                          child: const Text('back'),
                        ),
                      ),
                    ),
              ),
            ),
      ),
    );

    testWidgets('Android: No keeps the app open', (tester) async {
      await onPlatform(TargetPlatform.android, () async {
        await pumpTrigger(tester);

        await tester.tap(find.text('back'));
        await tester.pumpAndSettle();
        expect(find.text('common.exit_title'), findsOneWidget);
        expect(find.text('common.exit_message'), findsOneWidget);

        await tester.tap(find.text('common.no'));
        await tester.pumpAndSettle();

        expect(find.text('common.exit_title'), findsNothing);
        expect(systemPops, 0);
      });
    });

    testWidgets('Android: Yes closes the app', (tester) async {
      await onPlatform(TargetPlatform.android, () async {
        await pumpTrigger(tester);

        await tester.tap(find.text('back'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('common.yes'));
        await tester.pumpAndSettle();

        expect(systemPops, 1);
      });
    });

    testWidgets('iOS: no prompt, the app never tries to quit', (tester) async {
      await onPlatform(TargetPlatform.iOS, () async {
        await pumpTrigger(tester);

        await tester.tap(find.text('back'));
        await tester.pumpAndSettle();

        expect(find.text('common.exit_title'), findsNothing);
        expect(systemPops, 0);
      });
    });
  });
}
