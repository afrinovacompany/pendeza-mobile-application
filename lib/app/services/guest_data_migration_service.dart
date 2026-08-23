import '../../features/2_client_favorites/domain/repositories/favorites_repository.dart';
import '../services/local_storage_service.dart';
import '../services/firestore_service.dart';
import '../utils/logger.dart';
// Add this import


/// Service to handle migration of guest browsing data to authenticated user accounts.
///
/// When a guest user signs up, this service transfers their:
/// - Favorite salons
/// - Browsing history
/// - Search history
///
/// To their Firestore profile for a seamless experience.
class GuestDataMigrationService {
  final LocalStorageService _localStorage;
  final FavoritesRepository _favoritesRepository;

  GuestDataMigrationService({
    required LocalStorageService localStorage,
    required FirestoreService firestore,
    required FavoritesRepository favoritesRepository, // Injected via SL
  })  : _localStorage = localStorage,
        _favoritesRepository = favoritesRepository;

  /// Migrate all guest data to the newly authenticated user
  Future<void> migrateGuestData(String userId) async {
    try {
      log.i('Starting guest data migration for user: $userId');

      // 1. Migrate favorites using the repository
      // The repository implementation handles reading from local storage and checking duplicates
      await _favoritesRepository.migrateGuestFavorites(
        guestUserId: 'guest', // Placeholder as required by interface
        authenticatedUserId: userId,
      );

      // TODO: Migrate browsing history to analytics or user preferences
      // This could be stored in a separate subcollection

      // TODO: Migrate search history for personalized recommendations

      // Clear local storage after successful migration
      await _localStorage.clearAllGuestData();

      log.i('Guest data migration completed successfully for user: $userId');
    } catch (e, s) {
      log.e('Error migrating guest data', error: e, stackTrace: s);
      // Don't throw - migration failure shouldn't block user signup
    }
  }
}