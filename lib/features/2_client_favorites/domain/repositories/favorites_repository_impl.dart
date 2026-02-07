import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/app/services/local_storage_service.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import '../../../../shared/models/favorite_model.dart';
import '../../domain/repositories/favorites_repository.dart';


/// Implementation of FavoritesRepository that handles both:
/// - Guest favorites (via LocalStorageService)
/// - Authenticated user favorites (via FirestoreService)
class FavoritesRepositoryImpl implements FavoritesRepository {
  final FirestoreService _firestoreService;
  final LocalStorageService _localStorageService;

  FavoritesRepositoryImpl({
    required FirestoreService firestoreService,
    required LocalStorageService localStorageService,
  })  : _firestoreService = firestoreService,
        _localStorageService = localStorageService;

  @override
  Future<void> addFavorite({
    required String userId,
    required String salonId,
    bool isGuest = false,
  }) async {
    try {
      if (isGuest) {
        // Guest: Use local storage
        await _localStorageService.addFavoriteSalon(salonId);
        log.i('Added salon $salonId to guest favorites');
      } else {
        // Authenticated: Use Firestore
        await _firestoreService.addFavoriteSalon(
          userId: userId,
          salonId: salonId,
        );
        log.i('Added salon $salonId to favorites for user $userId');
      }
    } catch (e, s) {
      log.e('Error adding favorite', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> removeFavorite({
    required String userId,
    required String salonId,
    bool isGuest = false,
  }) async {
    try {
      if (isGuest) {
        // Guest: Use local storage
        await _localStorageService.removeFavoriteSalon(salonId);
        log.i('Removed salon $salonId from guest favorites');
      } else {
        // Authenticated: Use Firestore
        await _firestoreService.removeFavoriteSalon(
          userId: userId,
          salonId: salonId,
        );
        log.i('Removed salon $salonId from favorites for user $userId');
      }
    } catch (e, s) {
      log.e('Error removing favorite', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<bool> toggleFavorite({
    required String userId,
    required String salonId,
    bool isGuest = false,
  }) async {
    try {
      final isFav = await isFavorited(
        userId: userId,
        salonId: salonId,
        isGuest: isGuest,
      );

      if (isFav) {
        await removeFavorite(
          userId: userId,
          salonId: salonId,
          isGuest: isGuest,
        );
        return false; // Now not favorited
      } else {
        await addFavorite(
          userId: userId,
          salonId: salonId,
          isGuest: isGuest,
        );
        return true; // Now favorited
      }
    } catch (e, s) {
      log.e('Error toggling favorite', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<bool> isFavorited({
    required String userId,
    required String salonId,
    bool isGuest = false,
  }) async {
    try {
      if (isGuest) {
        // Guest: Check local storage
        return _localStorageService.isSalonFavorited(salonId);
      } else {
        // Authenticated: Check Firestore
        return await _firestoreService.isSalonFavorited(
          userId: userId,
          salonId: salonId,
        );
      }
    } catch (e, s) {
      log.e('Error checking if favorited', error: e, stackTrace: s);
      return false;
    }
  }

  @override
  Future<List<String>> getFavoriteSalonIds({
    required String userId,
    bool isGuest = false,
  }) async {
    try {
      if (isGuest) {
        // Guest: Get from local storage
        return _localStorageService.getFavoriteSalons();
      } else {
        // Authenticated: Get from Firestore
        return await _firestoreService.getFavoriteSalonIds(userId: userId);
      }
    } catch (e, s) {
      log.e('Error getting favorite salon IDs', error: e, stackTrace: s);
      return [];
    }
  }

  @override
  Future<List<SalonModel>> getFavoriteSalons({
    required String userId,
    bool isGuest = false,
  }) async {
    try {
      // First, get the list of favorited salon IDs
      final salonIds = await getFavoriteSalonIds(
        userId: userId,
        isGuest: isGuest,
      );

      if (salonIds.isEmpty) {
        return [];
      }

      // Then fetch full salon details for each ID
      final salons = await _firestoreService.getSalonsByIds(salonIds);

      log.i('Retrieved ${salons.length} favorite salons for user $userId');
      return salons;
    } catch (e, s) {
      log.e('Error getting favorite salons', error: e, stackTrace: s);
      return [];
    }
  }

  @override
  Future<List<FavoriteModel>> getFavoriteModels({
    required String userId,
  }) async {
    try {
      // This only works for authenticated users (has metadata)
      return await _firestoreService.getFavoriteModels(userId: userId);
    } catch (e, s) {
      log.e('Error getting favorite models', error: e, stackTrace: s);
      return [];
    }
  }

  @override
  Future<void> migrateGuestFavorites({
    required String guestUserId,
    required String authenticatedUserId,
  }) async {
    try {
      log.i('Starting favorite migration from guest to user $authenticatedUserId');

      // Get guest favorites from local storage
      final guestFavorites = _localStorageService.getFavoriteSalons();

      if (guestFavorites.isEmpty) {
        log.i('No guest favorites to migrate');
        return;
      }

      // Add each favorite to Firestore for authenticated user
      for (final salonId in guestFavorites) {
        await _firestoreService.addFavoriteSalon(
          userId: authenticatedUserId,
          salonId: salonId,
        );
      }

      // Clear guest favorites after successful migration
      await _localStorageService.clearFavoriteSalons();

      log.i('Migrated ${guestFavorites.length} favorites successfully');
    } catch (e, s) {
      log.e('Error migrating guest favorites', error: e, stackTrace: s);
      // Don't rethrow - migration failure shouldn't block user signup
    }
  }

  @override
  Stream<List<String>> watchFavoriteSalonIds({
    required String userId,
  }) {
    try {
      // Real-time updates for authenticated users only
      return _firestoreService.watchFavoriteSalonIds(userId: userId);
    } catch (e, s) {
      log.e('Error watching favorite salon IDs', error: e, stackTrace: s);
      // Return empty stream on error
      return Stream.value([]);
    }
  }

  @override
  Future<int> getFavoritesCount({
    required String userId,
    bool isGuest = false,
  }) async {
    try {
      final salonIds = await getFavoriteSalonIds(
        userId: userId,
        isGuest: isGuest,
      );
      return salonIds.length;
    } catch (e, s) {
      log.e('Error getting favorites count', error: e, stackTrace: s);
      return 0;
    }
  }

  @override
  Future<void> clearAllFavorites({
    required String userId,
    bool isGuest = false,
  }) async {
    try {
      if (isGuest) {
        // Guest: Clear local storage
        await _localStorageService.clearFavoriteSalons();
        log.i('Cleared all guest favorites');
      } else {
        // Authenticated: Clear Firestore favorites
        await _firestoreService.clearAllFavorites(userId: userId);
        log.i('Cleared all favorites for user $userId');
      }
    } catch (e, s) {
      log.e('Error clearing favorites', error: e, stackTrace: s);
      rethrow;
    }
  }
}