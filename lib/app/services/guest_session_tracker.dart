import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Service to track guest user behavior and session data.
///
/// This service monitors:
/// - Salons viewed/browsed
/// - Time spent in the app
/// - Favorites attempted (without auth)
/// - Search queries made
/// - Features explored
///
/// Used by GuestPromptService to determine when to show auth prompts.
class GuestSessionTracker {
  final SharedPreferences _prefs;

  // Storage keys
  static const String _keySessionStart = 'guest_session_start';
  static const String _keySalonsViewed = 'guest_salons_viewed';
  static const String _keyFavoritesAttempted = 'guest_favorites_attempted';
  static const String _keySearchesMade = 'guest_searches_made';
  static const String _keyServicesViewed = 'guest_services_viewed';
  static const String _keyLastPromptShown = 'guest_last_prompt_shown';
  static const String _keyPromptDismissCount = 'guest_prompt_dismiss_count';
  static const String _keyFeatureInteractions = 'guest_feature_interactions';

  GuestSessionTracker(this._prefs);

  /// Factory method to initialize the tracker
  static Future<GuestSessionTracker> init() async {
    final prefs = await SharedPreferences.getInstance();
    return GuestSessionTracker(prefs);
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Start a new guest session
  Future<void> startSession() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt(_keySessionStart, now);
    log.i('Guest session started at $now');
  }

  /// Get session duration in minutes
  int getSessionDurationMinutes() {
    final start = _prefs.getInt(_keySessionStart);
    if (start == null) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    final durationMs = now - start;
    final durationMinutes = (durationMs / 1000 / 60).floor();

    return durationMinutes;
  }

  /// Check if this is a new session (no start time recorded)
  bool get isNewSession {
    return _prefs.getInt(_keySessionStart) == null;
  }

  // ============================================================================
  // BROWSING BEHAVIOR TRACKING
  // ============================================================================

  /// Track when a guest views a salon
  Future<void> trackSalonView(String salonId) async {
    try {
      final viewedSalons = getSalonsViewed();
      if (!viewedSalons.contains(salonId)) {
        viewedSalons.add(salonId);
        await _prefs.setStringList(_keySalonsViewed, viewedSalons);
        log.d('Guest viewed salon: $salonId (Total: ${viewedSalons.length})');
      }
    } catch (e, s) {
      log.e('Error tracking salon view', error: e, stackTrace: s);
    }
  }

  /// Get list of salon IDs viewed in this session
  List<String> getSalonsViewed() {
    return _prefs.getStringList(_keySalonsViewed) ?? [];
  }

  /// Get count of salons viewed
  int get salonsViewedCount => getSalonsViewed().length;

  /// Track when a guest attempts to favorite (before auth)
  Future<void> trackFavoriteAttempt(String salonId) async {
    try {
      final attempts = getFavoriteAttempts();
      if (!attempts.contains(salonId)) {
        attempts.add(salonId);
        await _prefs.setStringList(_keyFavoritesAttempted, attempts);
        log.d('Guest attempted to favorite: $salonId (Total attempts: ${attempts.length})');
      }
    } catch (e, s) {
      log.e('Error tracking favorite attempt', error: e, stackTrace: s);
    }
  }

  /// Get list of salon IDs guest tried to favorite
  List<String> getFavoriteAttempts() {
    return _prefs.getStringList(_keyFavoritesAttempted) ?? [];
  }

  /// Get count of favorite attempts
  int get favoriteAttemptsCount => getFavoriteAttempts().length;

  /// Track search queries made
  Future<void> trackSearch(String query) async {
    try {
      final searches = getSearchesMade();
      searches.add(query);
      await _prefs.setStringList(_keySearchesMade, searches);
      log.d('Guest searched for: "$query" (Total searches: ${searches.length})');
    } catch (e, s) {
      log.e('Error tracking search', error: e, stackTrace: s);
    }
  }

  /// Get list of search queries
  List<String> getSearchesMade() {
    return _prefs.getStringList(_keySearchesMade) ?? [];
  }

  /// Get count of searches made
  int get searchesMadeCount => getSearchesMade().length;

  /// Track when guest views services (on salon detail page)
  Future<void> trackServiceView(String salonId) async {
    try {
      final servicesViewed = getServicesViewed();
      if (!servicesViewed.contains(salonId)) {
        servicesViewed.add(salonId);
        await _prefs.setStringList(_keyServicesViewed, servicesViewed);
        log.d('Guest viewed services for salon: $salonId');
      }
    } catch (e, s) {
      log.e('Error tracking service view', error: e, stackTrace: s);
    }
  }

  /// Get list of salons where services were viewed
  List<String> getServicesViewed() {
    return _prefs.getStringList(_keyServicesViewed) ?? [];
  }

  /// Get count of service views
  int get servicesViewedCount => getServicesViewed().length;

  /// Track feature interactions (e.g., "filter_used", "category_selected")
  Future<void> trackFeatureInteraction(String featureName) async {
    try {
      final interactions = getFeatureInteractions();
      interactions.add('${featureName}_${DateTime.now().millisecondsSinceEpoch}');

      // Keep only last 50 interactions to avoid bloat
      if (interactions.length > 50) {
        interactions.removeRange(0, interactions.length - 50);
      }

      await _prefs.setStringList(_keyFeatureInteractions, interactions);
      log.d('Guest interacted with feature: $featureName');
    } catch (e, s) {
      log.e('Error tracking feature interaction', error: e, stackTrace: s);
    }
  }

  /// Get list of feature interactions
  List<String> getFeatureInteractions() {
    return _prefs.getStringList(_keyFeatureInteractions) ?? [];
  }

  // ============================================================================
  // PROMPT MANAGEMENT
  // ============================================================================

  /// Record when a prompt was shown
  Future<void> recordPromptShown() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _prefs.setInt(_keyLastPromptShown, now);
    log.d('Auth prompt shown to guest');
  }

  /// Get timestamp of last prompt shown
  int? getLastPromptTimestamp() {
    return _prefs.getInt(_keyLastPromptShown);
  }

  /// Get minutes since last prompt was shown
  int? getMinutesSinceLastPrompt() {
    final lastPrompt = getLastPromptTimestamp();
    if (lastPrompt == null) return null;

    final now = DateTime.now().millisecondsSinceEpoch;
    final durationMs = now - lastPrompt;
    return (durationMs / 1000 / 60).floor();
  }

  /// Record when user dismisses a prompt
  Future<void> recordPromptDismissed() async {
    try {
      final count = getPromptDismissCount();
      await _prefs.setInt(_keyPromptDismissCount, count + 1);
      log.d('Guest dismissed auth prompt (Total dismissals: ${count + 1})');
    } catch (e, s) {
      log.e('Error recording prompt dismissal', error: e, stackTrace: s);
    }
  }

  /// Get count of times user dismissed prompts
  int getPromptDismissCount() {
    return _prefs.getInt(_keyPromptDismissCount) ?? 0;
  }

  // ============================================================================
  // ENGAGEMENT METRICS
  // ============================================================================

  /// Calculate engagement score (0-100)
  /// Higher score = more engaged = more likely to convert
  int calculateEngagementScore() {
    int score = 0;

    // Time spent (max 20 points)
    final minutes = getSessionDurationMinutes();
    score += (minutes * 4).clamp(0, 20);

    // Salons viewed (max 30 points)
    score += (salonsViewedCount * 6).clamp(0, 30);

    // Services viewed (max 20 points)
    score += (servicesViewedCount * 10).clamp(0, 20);

    // Searches made (max 15 points)
    score += (searchesMadeCount * 5).clamp(0, 15);

    // Favorite attempts (max 15 points)
    score += (favoriteAttemptsCount * 7).clamp(0, 15);

    return score.clamp(0, 100);
  }

  /// Check if user is highly engaged (score > 50)
  bool get isHighlyEngaged => calculateEngagementScore() > 50;

  /// Check if user shows intent to use premium features
  bool get showsPremiumIntent {
    return favoriteAttemptsCount > 0 || servicesViewedCount > 2;
  }

  // ============================================================================
  // RESET & CLEAR
  // ============================================================================

  /// Clear all session data (call after successful signup)
  Future<void> clearSessionData() async {
    await Future.wait([
      _prefs.remove(_keySessionStart),
      _prefs.remove(_keySalonsViewed),
      _prefs.remove(_keyFavoritesAttempted),
      _prefs.remove(_keySearchesMade),
      _prefs.remove(_keyServicesViewed),
      _prefs.remove(_keyLastPromptShown),
      _prefs.remove(_keyPromptDismissCount),
      _prefs.remove(_keyFeatureInteractions),
    ]);
    log.i('Guest session data cleared');
  }

  /// Reset only prompt-related data (for testing or after major dismissals)
  Future<void> resetPromptData() async {
    await Future.wait([
      _prefs.remove(_keyLastPromptShown),
      _prefs.remove(_keyPromptDismissCount),
    ]);
    log.i('Guest prompt data reset');
  }

  // ============================================================================
  // DEBUG & ANALYTICS
  // ============================================================================

  /// Get comprehensive session summary for debugging
  Map<String, dynamic> getSessionSummary() {
    return {
      'sessionDurationMinutes': getSessionDurationMinutes(),
      'salonsViewedCount': salonsViewedCount,
      'servicesViewedCount': servicesViewedCount,
      'searchesMadeCount': searchesMadeCount,
      'favoriteAttemptsCount': favoriteAttemptsCount,
      'promptDismissCount': getPromptDismissCount(),
      'minutesSinceLastPrompt': getMinutesSinceLastPrompt(),
      'engagementScore': calculateEngagementScore(),
      'isHighlyEngaged': isHighlyEngaged,
      'showsPremiumIntent': showsPremiumIntent,
    };
  }

  /// Log current session stats (for debugging)
  void logSessionStats() {
    final summary = getSessionSummary();
    log.i('Guest Session Stats: $summary');
  }
}