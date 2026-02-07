import 'package:pendeza/shared/models/salon_model.dart';

import '../../../../shared/models/favorite_model.dart';


/// Abstract repository interface for managing user favorites.
///
/// This repository handles:
/// - Adding/removing favorites (for both guests and authenticated users)
/// - Fetching user's favorite salons
/// - Checking if a salon is favorited
/// - Migrating guest favorites to authenticated user account
abstract class FavoritesRepository {
  /// Add a salon to user's favorites
  /// - For guests: Saves to local storage
  /// - For authenticated users: Saves to Firestore
  Future<void> addFavorite({
    required String userId,
    required String salonId,
    bool isGuest = false,
  });

  /// Remove a salon from user's favorites
  /// - For guests: Removes from local storage
  /// - For authenticated users: Removes from Firestore
  Future<void> removeFavorite({
    required String userId,
    required String salonId,
    bool isGuest = false,
  });

  /// Toggle favorite status (add if not favorited, remove if favorited)
  Future<bool> toggleFavorite({
    required String userId,
    required String salonId,
    bool isGuest = false,
  });

  /// Check if a salon is in user's favorites
  /// - For guests: Checks local storage
  /// - For authenticated users: Checks Firestore
  Future<bool> isFavorited({
    required String userId,
    required String salonId,
    bool isGuest = false,
  });

  /// Get list of user's favorite salon IDs
  /// - For guests: Returns from local storage
  /// - For authenticated users: Returns from Firestore
  Future<List<String>> getFavoriteSalonIds({
    required String userId,
    bool isGuest = false,
  });

  /// Get full salon details for user's favorites
  /// - Fetches salon IDs first, then gets full salon data
  Future<List<SalonModel>> getFavoriteSalons({
    required String userId,
    bool isGuest = false,
  });

  /// Get favorite models with metadata (authenticated users only)
  Future<List<FavoriteModel>> getFavoriteModels({
    required String userId,
  });

  /// Migrate guest favorites to authenticated user account
  /// Called after successful signup/signin
  Future<void> migrateGuestFavorites({
    required String guestUserId,
    required String authenticatedUserId,
  });

  /// Stream of favorite salon IDs (for real-time updates)
  /// Authenticated users only - guests don't get real-time updates
  Stream<List<String>> watchFavoriteSalonIds({
    required String userId,
  });

  /// Get count of user's favorites
  Future<int> getFavoritesCount({
    required String userId,
    bool isGuest = false,
  });

  /// Clear all favorites (mainly for guests on logout/cleanup)
  Future<void> clearAllFavorites({
    required String userId,
    bool isGuest = false,
  });
}