import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendeza/features/5_admin_panel/presentation/screens/admin_manage_notification_screen.dart';

/// Regression tests for "notification history never shows, only loads".
///
/// The inbox used to be one Firestore `snapshots()` stream (a broadcast stream,
/// which does not replay past events) shared by two StreamBuilders. The
/// Compose tab's stat tiles consumed the initial snapshot; the History tab
/// subscribed later and waited forever.
void main() {
  late StreamController<List<Map<String, dynamic>>> inbox;

  setUp(() => inbox = StreamController<List<Map<String, dynamic>>>.broadcast());
  tearDown(() => inbox.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AdminManageNotificationsScreen(debugInboxStream: inbox.stream),
      ),
    );
    await tester.pump();
  }

  Future<void> openHistory(WidgetTester tester) async {
    await tester.tap(find.text('History'));
    // Not pumpAndSettle: the loading skeleton animates forever.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('shows history that arrived before the tab was opened',
      (tester) async {
    await pumpScreen(tester);

    // Data is delivered while the user is still on the Compose tab.
    inbox.add([
      {
        'title': 'Summer promo',
        'body': '20% off all facials',
        'targetAudience': 'all',
        'analytics': {'sent': 12, 'failed': 1},
      },
    ]);
    await tester.pump();

    await openHistory(tester);

    expect(find.text('Summer promo'), findsOneWidget);
    expect(find.text('Sent to 12'), findsOneWidget);
    expect(find.text('1 failed'), findsOneWidget);
  });

  testWidgets('reads the CTA label from customData', (tester) async {
    await pumpScreen(tester);
    inbox.add([
      {
        'title': 'Book now',
        'body': 'Slots are filling up',
        'targetAudience': 'clients',
        'customData': {'actionLabel': 'View offers'},
      },
    ]);
    await tester.pump();
    await openHistory(tester);

    expect(find.text('CTA: View offers'), findsOneWidget);
  });

  testWidgets('shows an empty state when nothing has been sent',
      (tester) async {
    await pumpScreen(tester);
    inbox.add(const []);
    await tester.pump();
    await openHistory(tester);

    expect(find.text('No notifications sent yet'), findsOneWidget);
  });

  testWidgets('surfaces errors instead of loading forever', (tester) async {
    await pumpScreen(tester);
    inbox.addError(StateError('boom'));
    await tester.pump();
    await openHistory(tester);

    expect(find.text('Couldn’t load history'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('stat tiles total the devices reached', (tester) async {
    await pumpScreen(tester);
    inbox.add([
      {'title': 'A', 'analytics': {'sent': 10}},
      {'title': 'B', 'analytics': {'sent': 5}},
    ]);
    await tester.pump(); // deliver the stream event
    await tester.pump(); // rebuild with it

    expect(find.text('15'), findsOneWidget); // devices reached
    expect(find.text('2'), findsOneWidget); // broadcasts
  });

  testWidgets('gives up waiting after a while and offers a retry',
      (tester) async {
    await pumpScreen(tester);
    await openHistory(tester);
    expect(find.text('Couldn’t load history'), findsNothing);

    // Nothing ever arrives.
    await tester.pump(const Duration(seconds: 16));
    await tester.pump();

    expect(find.text('Couldn’t load history'), findsOneWidget);
  });
}
