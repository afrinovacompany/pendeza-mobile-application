import 'package:firebase_analytics/firebase_analytics.dart';
import '../utils/logger.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // Singleton
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  // Track screens
  Future<void> setCurrentScreen(String screenName) async {
    // FIX: setCurrentScreen is deprecated, used logScreenView instead
    await _analytics.logScreenView(screenName: screenName);
    log.d('Analytics: Screen viewed - $screenName');
  }

  // Track events
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters, // FIX: Changed dynamic to Object to match Firebase API
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
    log.d('Analytics: Event logged - $name');
  }

  // User properties
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Predefined events
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  Future<void> logViewItem({
    required String itemId,
    required String itemName,
    required String itemCategory,
  }) async {
    // FIX: Updated to use AnalyticsEventItem as required by newer Firebase versions
    await _analytics.logViewItem(
      items: [
        AnalyticsEventItem(
          itemId: itemId,
          itemName: itemName,
          itemCategory: itemCategory,
        ),
      ],
    );
  }

  // Custom business events
  Future<void> logBookingStarted({
    required String salonId,
    required String salonName,
  }) async {
    await logEvent(
      name: 'booking_started',
      parameters: {
        'salon_id': salonId,
        'salon_name': salonName,
      },
    );
  }

  Future<void> logBookingCompleted({
    required String salonId,
    required double amount,
    required int serviceCount,
  }) async {
    await logEvent(
      name: 'booking_completed',
      parameters: {
        'salon_id': salonId,
        'value': amount, // Note: numeric values are allowed objects
        'currency': 'TZS',
        'service_count': serviceCount,
      },
    );
  }

  Future<void> logFavoriteAdded(String salonId) async {
    await logEvent(
      name: 'favorite_added',
      parameters: {'salon_id': salonId},
    );
  }

  Future<void> logReviewSubmitted({
    required String salonId,
    required double rating,
  }) async {
    await logEvent(
      name: 'review_submitted',
      parameters: {
        'salon_id': salonId,
        'rating': rating,
      },
    );
  }
}