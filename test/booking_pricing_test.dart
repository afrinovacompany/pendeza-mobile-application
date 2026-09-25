import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';
import 'package:pendeza/features/2_client_booking/presentation/widgets/service_price.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/service_model.dart';

/// The price on a service card, the booking total and the stored appointment
/// total must all be the same number: the discounted price when there is one.
void main() {
  ServiceModel service(double price, {double? discounted}) => ServiceModel(
        id: 'x',
        salonId: 's',
        name: 'Silk Press',
        price: price,
        discountedPrice: discounted,
        durationMinutes: 60,
        category: 'Hair',
      );

  group('ServiceModel.effectivePrice', () {
    test('is the discounted price when there is a real discount', () {
      final s = service(120000, discounted: 99000);
      expect(s.hasDiscount, isTrue);
      expect(s.effectivePrice, 99000);
    });

    test('is the list price without a discount', () {
      expect(service(45000).effectivePrice, 45000);
    });

    test('never exceeds the list price', () {
      // A "discount" above the price is not a discount.
      final s = service(45000, discounted: 60000);
      expect(s.hasDiscount, isFalse);
      expect(s.effectivePrice, 45000);
    });
  });

  test('the booking total is built from what the customer is shown', () {
    final state = BookingInProgress(
      salon: SalonModel(
        id: 's',
        ownerId: 'o',
        salonName: 'Glow',
        address: 'Masaki',
        serviceCategories: const [],
        createdAt: DateTime(2025),
      ),
      status: BookingStatus.reviewing,
      availableServices: const [],
      selectedServices: [
        service(120000, discounted: 99000),
        service(25000),
      ],
      availableTimeSlots: const [],
    );

    expect(state.totalPrice, 124000); // 99,000 + 25,000, not 145,000
  });

  group('ServicePrice', () {
    Future<void> pump(WidgetTester tester, ServiceModel s) => tester.pumpWidget(
          MaterialApp(home: Scaffold(body: ServicePrice(service: s))),
        );

    testWidgets('shows the discounted price with the list price crossed out',
        (tester) async {
      await pump(tester, service(120000, discounted: 99000));

      expect(find.textContaining('99,000'), findsOneWidget);
      final listPrice = tester.widget<Text>(find.textContaining('120,000'));
      expect(listPrice.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('shows only the price when there is no discount',
        (tester) async {
      await pump(tester, service(45000));

      expect(find.textContaining('45,000'), findsOneWidget);
    });
  });
}
