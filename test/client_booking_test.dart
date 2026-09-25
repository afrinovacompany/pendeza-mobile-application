import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_event.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import 'package:pendeza/features/2_client_booking/presentation/screens/booking_confirmation_screen.dart';
import 'package:pendeza/features/2_client_booking/presentation/screens/service_selection_screen.dart';
import 'package:pendeza/features/2_client_booking/presentation/screens/timeslot_selection_screen.dart';
import 'package:pendeza/features/2_client_booking/presentation/widgets/booking_step_header.dart';
import 'package:pendeza/features/2_client_booking/presentation/widgets/booking_summary_footer.dart';
import 'package:pendeza/features/2_client_booking/presentation/widgets/calendar_view.dart';
import 'package:pendeza/features/2_client_booking/presentation/widgets/service_list_tile.dart';
import 'package:pendeza/features/2_client_booking/presentation/widgets/time_slot_chip.dart';
import 'package:pendeza/features/2_client_discovery/presentation/widgets/salon_services_tab.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

/// The booking-journey redesign is visual only: these pin the behaviour
/// (selection, navigation, events dispatched) so a restyle can't rewire it.

class _FakeBookingBloc extends Fake implements BookingBloc {
  _FakeBookingBloc(this._state);
  final BookingState _state;
  final List<BookingEvent> events = [];

  @override
  BookingState get state => _state;
  @override
  Stream<BookingState> get stream => const Stream.empty();
  @override
  void add(BookingEvent event) => events.add(event);
  @override
  Future<void> close() async {}
  @override
  bool get isClosed => false;
}

class _FakeAuthBloc extends Fake implements AuthBloc {
  _FakeAuthBloc(this._state);
  final AuthState _state;
  @override
  AuthState get state => _state;
  @override
  Stream<AuthState> get stream => const Stream.empty();
  @override
  void add(AuthEvent event) {}
  @override
  Future<void> close() async {}
  @override
  bool get isClosed => false;
}

final _salon = SalonModel(
  id: 's1',
  ownerId: 'o1',
  salonName: 'Glow Beauty Lounge',
  address: 'Masaki',
  serviceCategories: const ['Hair Services'],
  createdAt: DateTime(2025, 1, 1),
);

const _silk = ServiceModel(
  id: 'a',
  salonId: 's1',
  name: 'Silk Press',
  price: 45000,
  durationMinutes: 90,
  category: 'Hair Services',
  isFeatured: true,
);
const _mani = ServiceModel(
  id: 'b',
  salonId: 's1',
  name: 'Gel Manicure',
  price: 25000,
  durationMinutes: 45,
  category: 'Nails',
);

BookingInProgress _booking({
  BookingStatus status = BookingStatus.selectingServices,
  List<ServiceModel> selected = const [],
  DateTime? date,
  String? slot,
  List<String> slots = const [],
}) =>
    BookingInProgress(
      salon: _salon,
      status: status,
      availableServices: const [_silk, _mani],
      selectedServices: selected,
      selectedDate: date,
      selectedTimeSlot: slot,
      availableTimeSlots: slots,
    );

final _user = UserModel(
  uid: 'u1',
  email: 'a@b.co',
  fullName: 'Amina Hassan',
  role: 'client',
  fcmTokens: const [],
  createdAt: DateTime(2025, 1, 1),
);

void main() {
  Future<void> setPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Mounts [screen] at '/' with the booking journey's routes recorded.
  Future<List<String>> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required _FakeBookingBloc bloc,
    AuthState? auth,
  }) async {
    await setPhone(tester);
    final visited = <String>[];
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => screen),
        GoRoute(
          path: '/salon/:salonId/schedule',
          builder: (_, s) {
            visited.add(s.uri.path);
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
        GoRoute(
          path: '/salon/:salonId/confirm',
          builder: (_, s) {
            visited.add(s.uri.path);
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
        GoRoute(
          path: '/client/bookings',
          builder: (_, s) {
            visited.add(s.uri.path);
            return const Scaffold(body: SizedBox.shrink());
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BookingBloc>.value(value: bloc),
          BlocProvider<AuthBloc>.value(
            value: _FakeAuthBloc(auth ?? Authenticated(_user)),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    return visited;
  }

  /// Lets NavigationGuard's 500 ms reset timer finish.
  Future<void> flushGuard(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 1));

  group('BookingSummaryFooter', () {
    Future<void> pumpFooter(
      WidgetTester tester, {
      VoidCallback? onPressed,
      bool loading = false,
    }) async {
      await setPhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: BookingSummaryFooter(
                totalPrice: 70000,
                totalDurationMinutes: 135,
                buttonText: 'NEXT',
                buttonIcon: CupertinoIcons.arrow_right,
                onButtonPressed: onPressed,
                isButtonLoading: loading,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('enabled button fires its callback', (tester) async {
      var taps = 0;
      await pumpFooter(tester, onPressed: () => taps++);
      await tester.tap(find.text('NEXT'));
      expect(taps, 1);
    });

    testWidgets('disabled button does nothing', (tester) async {
      await pumpFooter(tester);
      await tester.tap(find.byType(ClientPrimaryButton), warnIfMissed: false);
      // No callback to observe; the button must simply not throw and stay
      // labelled.
      expect(find.text('NEXT'), findsOneWidget);
    });

    testWidgets('loading shows a spinner and ignores taps', (tester) async {
      var taps = 0;
      await pumpFooter(tester, onPressed: () => taps++, loading: true);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('NEXT'), findsNothing);
      await tester.tap(find.byType(ClientPrimaryButton));
      expect(taps, 0);
    });
  });

  group('BookingStepHeader', () {
    testWidgets('lists the three steps and the back button pops',
        (tester) async {
      await setPhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        body: BookingStepHeader(
                          step: 2,
                          title: 'Pick a time',
                          subtitle: 'Glow',
                        ),
                      ),
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Pick a time'), findsOneWidget);
      expect(find.text('Glow'), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.back));
      await tester.pumpAndSettle();
      expect(find.text('Pick a time'), findsNothing);
    });
  });

  group('selection widgets', () {
    testWidgets('ServiceSelectionCard taps toggle via the callback',
        (tester) async {
      await setPhone(tester);
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceSelectionCard(
              service: _silk,
              isSelected: false,
              onTap: () => taps++,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Silk Press'));
      expect(taps, 1);
    });

    testWidgets('TimeSlotChip reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: TimeSlotChip(
                slot: '10:30',
                isSelected: false,
                onTap: () => taps++,
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('10:30'));
      expect(taps, 1);
    });

    testWidgets('HorizontalDayPicker reports the tapped day', (tester) async {
      await setPhone(tester);
      DateTime? picked;
      final today = DateTime.now();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HorizontalDayPicker(
              selectedDate: today,
              onDateSelected: (d) => picked = d,
            ),
          ),
        ),
      );
      final tomorrow = today.add(const Duration(days: 1));
      // Days are laid out in order; the second item is tomorrow.
      await tester.tap(find.text('${tomorrow.day}').first);
      expect(picked, isNotNull);
      expect(picked!.day, tomorrow.day);
    });
  });

  group('SalonServicesTab', () {
    testWidgets('tapping a service reports it', (tester) async {
      await setPhone(tester);
      final tapped = <ServiceModel>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SalonServicesTab(
              salon: _salon,
              services: const [_silk, _mani],
              onServiceTap: tapped.add,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Gel Manicure').first);
      expect(tapped, [_mani]);
    });

    testWidgets('a category header collapses its services', (tester) async {
      await setPhone(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SalonServicesTab(
              salon: _salon,
              services: const [_mani],
              onServiceTap: (_) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      CrossFadeState fade() => tester
          .widget<AnimatedCrossFade>(find.byType(AnimatedCrossFade))
          .crossFadeState;
      expect(fade(), CrossFadeState.showSecond);

      await tester.tap(find.text('Nails'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(fade(), CrossFadeState.showFirst);

      await tester.tap(find.text('Nails'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(fade(), CrossFadeState.showSecond);
    });
  });

  group('ServiceSelectionScreen', () {
    testWidgets('continue is off until something is selected', (tester) async {
      final bloc = _FakeBookingBloc(_booking());
      final visited = await pumpScreen(
        tester,
        const ServiceSelectionScreen(salonName: 'Glow'),
        bloc: bloc,
      );

      await tester.tap(find.byType(ClientPrimaryButton));
      await flushGuard(tester);
      expect(visited, isEmpty);
      expect(bloc.events, isEmpty);
    });

    testWidgets('selecting a service and continuing goes to the schedule',
        (tester) async {
      final bloc = _FakeBookingBloc(_booking());
      final visited = await pumpScreen(
        tester,
        const ServiceSelectionScreen(salonName: 'Glow'),
        bloc: bloc,
      );

      await tester.tap(find.text('Silk Press'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byType(ClientPrimaryButton));
      await tester.pumpAndSettle();

      expect(bloc.events.whereType<ServicesSelected>().single.services,
          [_silk]);
      expect(visited, ['/salon/s1/schedule']);
    });

    testWidgets('a service picked on the salon page starts selected',
        (tester) async {
      final bloc = _FakeBookingBloc(_booking());
      final visited = await pumpScreen(
        tester,
        const ServiceSelectionScreen(
          salonName: 'Glow',
          preselectedService: _mani,
        ),
        bloc: bloc,
      );

      // Continue is already enabled: no extra tap needed to select.
      await tester.tap(find.byType(ClientPrimaryButton));
      await tester.pumpAndSettle();

      expect(bloc.events.whereType<ServicesSelected>().single.services,
          [_mani]);
      expect(visited, ['/salon/s1/schedule']);
    });
  });

  group('TimeslotSelectionScreen', () {
    final date = DateTime.now().add(const Duration(days: 1));

    testWidgets('tapping a slot dispatches TimeSlotSelected', (tester) async {
      final bloc = _FakeBookingBloc(_booking(
        status: BookingStatus.selectingTime,
        selected: const [_silk],
        date: date,
        slots: const ['09:00', '14:30', '18:00'],
      ));
      await pumpScreen(tester, const TimeslotSelectionScreen(), bloc: bloc);

      await tester.tap(find.text('14:30'));
      await tester.pump();

      expect(bloc.events.whereType<TimeSlotSelected>().single.timeSlot,
          '14:30');
    });

    testWidgets('review goes to the confirmation once a slot is chosen',
        (tester) async {
      final bloc = _FakeBookingBloc(_booking(
        status: BookingStatus.selectingTime,
        selected: const [_silk],
        date: date,
        slot: '09:00',
        slots: const ['09:00', '14:30'],
      ));
      final visited =
          await pumpScreen(tester, const TimeslotSelectionScreen(), bloc: bloc);

      await tester.tap(find.byType(ClientPrimaryButton));
      await tester.pumpAndSettle();

      expect(visited, ['/salon/s1/confirm']);
    });

    testWidgets('review stays off without a chosen slot', (tester) async {
      final bloc = _FakeBookingBloc(_booking(
        status: BookingStatus.selectingTime,
        selected: const [_silk],
        date: date,
        slots: const ['09:00'],
      ));
      final visited =
          await pumpScreen(tester, const TimeslotSelectionScreen(), bloc: bloc);

      await tester.tap(find.byType(ClientPrimaryButton));
      await flushGuard(tester);
      expect(visited, isEmpty);
    });
  });

  group('BookingConfirmationScreen', () {
    final date = DateTime.now().add(const Duration(days: 1));

    testWidgets('confirm dispatches ConfirmBooking', (tester) async {
      final bloc = _FakeBookingBloc(_booking(
        status: BookingStatus.reviewing,
        selected: const [_silk, _mani],
        date: date,
        slot: '10:30',
      ));
      await pumpScreen(tester, const BookingConfirmationScreen(), bloc: bloc);

      await tester.tap(find.byType(ClientPrimaryButton));
      await tester.pump();

      expect(bloc.events.whereType<ConfirmBooking>(), hasLength(1));
    });

    testWidgets('while processing the button spins and cannot be re-tapped',
        (tester) async {
      final bloc = _FakeBookingBloc(_booking(
        status: BookingStatus.processing,
        selected: const [_silk],
        date: date,
        slot: '10:30',
      ));
      await pumpScreen(tester, const BookingConfirmationScreen(), bloc: bloc);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(ClientPrimaryButton));
      await tester.pump();
      expect(bloc.events, isEmpty);
    });

    testWidgets('shows the chosen services and total', (tester) async {
      final bloc = _FakeBookingBloc(_booking(
        status: BookingStatus.reviewing,
        selected: const [_silk, _mani],
        date: date,
        slot: '10:30',
      ));
      await pumpScreen(tester, const BookingConfirmationScreen(), bloc: bloc);

      expect(find.text('Silk Press'), findsOneWidget);
      expect(find.text('Gel Manicure'), findsOneWidget);
      expect(find.textContaining('70,000'), findsWidgets);
    });
  });
}
