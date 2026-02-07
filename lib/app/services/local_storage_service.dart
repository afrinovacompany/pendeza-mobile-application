import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger.dart';

/// Service for managing local data storage using SharedPreferences.
///
/// This is used to persist guest browsing data like:
/// - Favorite salons (before authentication)
/// - Browsing history
/// - Search history
/// - Last viewed salons
/// - App Locale/Language settings
///
/// When a guest user signs up, this data can be migrated to their Firestore profile.
class LocalStorageService {
  static const String _keyFavoriteSalons = 'guest_favorite_salons';
  static const String _keyBrowsingHistory = 'guest_browsing_history';
  static const String _keySearchHistory = 'guest_search_history';
  static const String _keyLastViewedSalon = 'guest_last_viewed_salon';
  static const String _keyIsFirstLaunch = 'is_first_launch';
  static const String _keyAppLocale = 'app_locale'; // NEW

  final SharedPreferences _prefs;

  LocalStorageService(this._prefs);

  /// Factory method to initialize the service
  static Future<LocalStorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService(prefs);
  }

  // ============================================================================
  // APP SETTINGS (Locale)
  // ============================================================================

  /// Save the selected language code (e.g., 'en', 'sw')
  Future<void> setLocale(String languageCode) async {
    await _prefs.setString(_keyAppLocale, languageCode);
    log.i('App locale saved: $languageCode');
  }

  /// Get the saved language code. Returns null if not set.
  String? getLocale() {
    return _prefs.getString(_keyAppLocale);
  }

  // ============================================================================
  // GENERIC PREFERENCES
  // ============================================================================

  /// Get a boolean value from preferences
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  /// Set a boolean value in preferences
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  /// Get a string value from preferences
  String? getString(String key) {
    return _prefs.getString(key);
  }

  /// Set a string value in preferences
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  // ============================================================================
  // FIRST LAUNCH
  // ============================================================================

  /// Check if this is the first time the app is launched
  bool get isFirstLaunch {
    return _prefs.getBool(_keyIsFirstLaunch) ?? true;
  }

  /// Mark the app as launched (called after onboarding)
  Future<void> markAsLaunched() async {
    await _prefs.setBool(_keyIsFirstLaunch, false);
    log.i('App marked as launched');
  }

  // ============================================================================
  // FAVORITE SALONS (for guests)
  // ============================================================================

  /// Get list of favorite salon IDs for guest users
  List<String> getFavoriteSalons() {
    try {
      final favorites = _prefs.getStringList(_keyFavoriteSalons) ?? [];
      log.d('Retrieved ${favorites.length} favorite salons for guest');
      return favorites;
    } catch (e, s) {
      log.e('Error getting favorite salons', error: e, stackTrace: s);
      return [];
    }
  }

  /// Add a salon to favorites (for guest users)
  Future<bool> addFavoriteSalon(String salonId) async {
    try {
      final favorites = getFavoriteSalons();
      if (!favorites.contains(salonId)) {
        favorites.add(salonId);
        await _prefs.setStringList(_keyFavoriteSalons, favorites);
        log.i('Added salon $salonId to guest favorites');
        return true;
      }
      return false;
    } catch (e, s) {
      log.e('Error adding favorite salon', error: e, stackTrace: s);
      return false;
    }
  }

  /// Remove a salon from favorites (for guest users)
  Future<bool> removeFavoriteSalon(String salonId) async {
    try {
      final favorites = getFavoriteSalons();
      if (favorites.contains(salonId)) {
        favorites.remove(salonId);
        await _prefs.setStringList(_keyFavoriteSalons, favorites);
        log.i('Removed salon $salonId from guest favorites');
        return true;
      }
      return false;
    } catch (e, s) {
      log.e('Error removing favorite salon', error: e, stackTrace: s);
      return false;
    }
  }

  /// Check if a salon is favorited
  bool isSalonFavorited(String salonId) {
    return getFavoriteSalons().contains(salonId);
  }

  /// Clear all favorite salons (after migration to Firestore)
  Future<void> clearFavoriteSalons() async {
    await _prefs.remove(_keyFavoriteSalons);
    log.i('Cleared guest favorite salons');
  }

  // ============================================================================
  // BROWSING HISTORY
  // ============================================================================

  /// Get browsing history as list of salon IDs
  List<String> getBrowsingHistory() {
    try {
      final history = _prefs.getStringList(_keyBrowsingHistory) ?? [];
      log.d('Retrieved browsing history: ${history.length} items');
      return history;
    } catch (e, s) {
      log.e('Error getting browsing history', error: e, stackTrace: s);
      return [];
    }
  }

  /// Add a salon to browsing history
  Future<void> addToBrowsingHistory(String salonId) async {
    try {
      final history = getBrowsingHistory();

      // Remove if already exists (to move to front)
      history.remove(salonId);

      // Add to front
      history.insert(0, salonId);

      // Keep only last 20 items
      if (history.length > 20) {
        history.removeRange(20, history.length);
      }

      await _prefs.setStringList(_keyBrowsingHistory, history);
      log.d('Added salon $salonId to browsing history');
    } catch (e, s) {
      log.e('Error adding to browsing history', error: e, stackTrace: s);
    }
  }

  /// Clear browsing history
  Future<void> clearBrowsingHistory() async {
    await _prefs.remove(_keyBrowsingHistory);
    log.i('Cleared browsing history');
  }

  // ============================================================================
  // SEARCH HISTORY
  // ============================================================================

  /// Get search history
  List<String> getSearchHistory() {
    try {
      final history = _prefs.getStringList(_keySearchHistory) ?? [];
      return history;
    } catch (e, s) {
      log.e('Error getting search history', error: e, stackTrace: s);
      return [];
    }
  }

  /// Add a search term to history
  Future<void> addToSearchHistory(String searchTerm) async {
    try {
      if (searchTerm.trim().isEmpty) return;

      final history = getSearchHistory();

      // Remove if already exists
      history.remove(searchTerm);

      // Add to front
      history.insert(0, searchTerm);

      // Keep only last 10 items
      if (history.length > 10) {
        history.removeRange(10, history.length);
      }

      await _prefs.setStringList(_keySearchHistory, history);
      log.d('Added "$searchTerm" to search history');
    } catch (e, s) {
      log.e('Error adding to search history', error: e, stackTrace: s);
    }
  }

  /// Clear search history
  Future<void> clearSearchHistory() async {
    await _prefs.remove(_keySearchHistory);
    log.i('Cleared search history');
  }

  // ============================================================================
  // LAST VIEWED SALON
  // ============================================================================

  /// Get last viewed salon ID
  String? getLastViewedSalon() {
    return _prefs.getString(_keyLastViewedSalon);
  }

  /// Set last viewed salon
  Future<void> setLastViewedSalon(String salonId) async {
    await _prefs.setString(_keyLastViewedSalon, salonId);
    log.d('Set last viewed salon: $salonId');
  }

  // ============================================================================
  // CLEAR ALL GUEST DATA
  // ============================================================================

  /// Clear all guest data (call this after successful migration to Firestore)
  Future<void> clearAllGuestData() async {
    await Future.wait([
      clearFavoriteSalons(),
      clearBrowsingHistory(),
      clearSearchHistory(),
      _prefs.remove(_keyLastViewedSalon),
    ]);
    log.i('Cleared all guest data');
  }

  // ============================================================================
  // MIGRATION HELPER
  // ============================================================================

  /// Get all guest data for migration to Firestore
  Map<String, dynamic> getGuestDataForMigration() {
    return {
      'favoriteSalons': getFavoriteSalons(),
      'browsingHistory': getBrowsingHistory(),
      'searchHistory': getSearchHistory(),
      'lastViewedSalon': getLastViewedSalon(),
    };
  }
}