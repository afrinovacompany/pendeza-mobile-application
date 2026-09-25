import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_notifications/domain/repositories/notification_repository.dart';
import 'package:pendeza/features/2_client_notifications/presentation/bloc/notification_bloc.dart';
import 'package:pendeza/features/2_client_notifications/presentation/bloc/notification_event.dart';
import 'package:pendeza/features/2_client_notifications/presentation/bloc/notification_state.dart';
import 'package:pendeza/features/2_client_notifications/presentation/screens/notifications_screen.dart';
import 'package:pendeza/shared/models/notification_model.dart';

/// Deleting a notification is undoable: it leaves the list at once, but is only
/// deleted from the server once the undo window has passed.

class _FakeAuthBloc extends Fake implements AuthBloc {
  final _state = Authenticated(UserModel(
    uid: 'u1',
    email: 'a@b.co',
    fullName: 'Amina',
    role: 'client',
    fcmTokens: const [],
    createdAt: DateTime(2025),
  ));

  @override
  AuthState get state => _state;
  @override
  Stream<AuthState> get stream => const Stream.empty();
}

class _FakeRepo extends Fake implements NotificationRepository {
  _FakeRepo(this.items);

  final List<NotificationModel> items;
  final stream = StreamController<List<NotificationModel>>.broadcast();
  final deleted = <String>[];
  bool failDelete = false;

  @override
  Future<List<NotificationModel>> getNotifications(
    String userId, {
    String? userRole,
  }) async =>
      List.of(items);

  @override
  Future<int> getUnreadCount(String userId, {String? userRole}) async =>
      items.where((n) => !n.isRead).length;

  @override
  Stream<List<NotificationModel>> streamNotifications(String userId) =>
      stream.stream;

  @override
  Stream<int> streamUnreadCount(String userId) => const Stream.empty();

  @override
  Future<void> deleteNotification(String notificationId) async {
    if (failDelete) throw Exception('offline');
    deleted.add(notificationId);
  }
}

NotificationModel _n(
  String id,
  int minutesAgo, {
  bool read = false,
  bool broadcast = false,
}) =>
    NotificationModel(
      id: id,
      userId: 'u1',
      title: 'Title $id',
      body: 'Body $id',
      type: NotificationType.general,
      createdAt: DateTime(2026, 1, 1, 12).subtract(Duration(minutes: minutesAgo)),
      isRead: read,
      isBroadcast: broadcast,
    );

void main() {
  const window = Duration(milliseconds: 60);
  final pastWindow = window * 3;

  late _FakeRepo repo;
  late NotificationBloc bloc;

  Future<void> start(List<NotificationModel> items) async {
    repo = _FakeRepo(items);
    bloc = NotificationBloc(
      repository: repo,
      authBloc: _FakeAuthBloc(),
      undoWindow: window,
    );
    // Wait for the initial load.
    await bloc.stream.firstWhere((s) => s is NotificationLoaded);
  }

  tearDown(() async {
    if (!bloc.isClosed) await bloc.close();
    unawaited(repo.stream.close());
  });

  NotificationLoaded loaded() => bloc.state as NotificationLoaded;
  List<String> ids() => loaded().notifications.map((n) => n.id).toList();

  test('delete hides the notification at once and deletes it after the window',
      () async {
    await start([_n('a', 1), _n('b', 2, read: true)]);

    bloc.add(const DeleteNotification('a'));
    await Future<void>.delayed(Duration.zero);

    expect(ids(), ['b']);
    expect(loaded().unreadCount, 0);
    expect(repo.deleted, isEmpty, reason: 'still undoable');

    await Future<void>.delayed(pastWindow);
    expect(repo.deleted, ['a']);
    expect(ids(), ['b']);
  });

  test('undo brings it back in place and it is never deleted', () async {
    await start([_n('a', 1), _n('b', 2), _n('c', 3, read: true)]);

    bloc.add(const DeleteNotification('b'));
    await Future<void>.delayed(Duration.zero);
    expect(ids(), ['a', 'c']);
    expect(loaded().unreadCount, 1);

    bloc.add(const UndoDeleteNotification('b'));
    await Future<void>.delayed(Duration.zero);

    expect(ids(), ['a', 'b', 'c']);
    expect(loaded().unreadCount, 2);

    await Future<void>.delayed(pastWindow);
    expect(repo.deleted, isEmpty);
    expect(ids(), ['a', 'b', 'c']);
  });

  test('undo after the window has closed does nothing', () async {
    await start([_n('a', 1), _n('b', 2)]);

    bloc.add(const DeleteNotification('a'));
    await Future<void>.delayed(pastWindow);
    bloc.add(const UndoDeleteNotification('a'));
    await Future<void>.delayed(Duration.zero);

    expect(repo.deleted, ['a']);
    expect(ids(), ['b']);
  });

  test('a live update during the window does not bring it back', () async {
    final a = _n('a', 1);
    final b = _n('b', 2);
    await start([a, b]);

    bloc.add(const DeleteNotification('a'));
    await Future<void>.delayed(Duration.zero);

    // Firestore still has it, so the stream still reports it.
    repo.stream.add([a, b]);
    await Future<void>.delayed(Duration.zero);

    expect(ids(), ['b']);
  });

  test('a failed delete puts the notification back', () async {
    await start([_n('a', 1), _n('b', 2)]);
    repo.failDelete = true;

    bloc.add(const DeleteNotification('a'));
    await Future<void>.delayed(pastWindow);

    expect(ids(), ['a', 'b']);
    expect(loaded().unreadCount, 2);
  });

  test('broadcasts are only hidden, never deleted on the server', () async {
    await start([_n('broadcast_x', 1, broadcast: true), _n('b', 2)]);

    bloc.add(const DeleteNotification('broadcast_x'));
    await Future<void>.delayed(pastWindow);

    expect(repo.deleted, isEmpty);
    expect(ids(), ['b']);
  });

  test('closing the bloc finishes a delete that was not undone', () async {
    await start([_n('a', 1), _n('b', 2)]);

    bloc.add(const DeleteNotification('a'));
    await Future<void>.delayed(Duration.zero);
    await bloc.close();

    expect(repo.deleted, ['a']);
  });

  group('NotificationsScreen', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      repo = _FakeRepo([_n('a', 1), _n('b', 2, read: true)]);
      bloc = NotificationBloc(
        repository: repo,
        authBloc: _FakeAuthBloc(),
        // The screen keeps its snackbar up for as long as the bloc keeps the
        // delete undoable, so use the real window here.
      );
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<NotificationBloc>.value(
            value: bloc,
            child: const NotificationsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
    }

    testWidgets('swiping away then tapping Undo restores the notification',
        (tester) async {
      await pumpScreen(tester);
      expect(find.text('Title a'), findsOneWidget);

      await tester.drag(find.text('Title a'), const Offset(-700, 0));
      await tester.pumpAndSettle();

      expect(find.text('Title a'), findsNothing);
      expect(find.text('common.undo'), findsOneWidget);

      await tester.tap(find.text('common.undo'));
      await tester.pumpAndSettle();

      expect(find.text('Title a'), findsOneWidget);

      await tester.pump(const Duration(seconds: 6));
      expect(repo.deleted, isEmpty);
      await tester.runAsync(bloc.close);
    });

    testWidgets('leaving it alone deletes it once the snackbar is gone',
        (tester) async {
      await pumpScreen(tester);

      await tester.drag(find.text('Title a'), const Offset(-700, 0));
      await tester.pumpAndSettle();
      expect(repo.deleted, isEmpty);

      await tester.pump(const Duration(seconds: 6));
      await tester.pumpAndSettle();

      expect(repo.deleted, ['a']);
      expect(find.text('Title a'), findsNothing);
      expect(find.text('common.undo'), findsNothing);
      await tester.runAsync(bloc.close);
    });
  });
}
