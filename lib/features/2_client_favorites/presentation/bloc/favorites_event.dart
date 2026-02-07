import 'package:equatable/equatable.dart';

/// Base class for all favorite events
abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();

  @override
  List<Object?> get props => [];
}

/// Load user's favorite salons
class LoadFavorites extends FavoritesEvent {
  final String userId;
  final bool isGuest;

  const LoadFavorites({
    required this.userId,
    this.isGuest = false,
  });

  @override
  List<Object?> get props => [userId, isGuest];
}

/// Toggle favorite status for a salon
class ToggleFavorite extends FavoritesEvent {
  final String userId;
  final String salonId;
  final bool isGuest;

  const ToggleFavorite({
    required this.userId,
    required this.salonId,
    this.isGuest = false,
  });

  @override
  List<Object?> get props => [userId, salonId, isGuest];
}

/// Add a salon to favorites
class AddFavorite extends FavoritesEvent {
  final String userId;
  final String salonId;
  final bool isGuest;

  const AddFavorite({
    required this.userId,
    required this.salonId,
    this.isGuest = false,
  });

  @override
  List<Object?> get props => [userId, salonId, isGuest];
}

/// Remove a salon from favorites
class RemoveFavorite extends FavoritesEvent {
  final String userId;
  final String salonId;
  final bool isGuest;

  const RemoveFavorite({
    required this.userId,
    required this.salonId,
    this.isGuest = false,
  });

  @override
  List<Object?> get props => [userId, salonId, isGuest];
}

/// Refresh favorites list
class RefreshFavorites extends FavoritesEvent {
  final String userId;
  final bool isGuest;

  const RefreshFavorites({
    required this.userId,
    this.isGuest = false,
  });

  @override
  List<Object?> get props => [userId, isGuest];
}

/// Check if a specific salon is favorited (for individual card updates)
class CheckIsFavorited extends FavoritesEvent {
  final String userId;
  final String salonId;
  final bool isGuest;

  const CheckIsFavorited({
    required this.userId,
    required this.salonId,
    this.isGuest = false,
  });

  @override
  List<Object?> get props => [userId, salonId, isGuest];
}

/// Clear all favorites
class ClearAllFavorites extends FavoritesEvent {
  final String userId;
  final bool isGuest;

  const ClearAllFavorites({
    required this.userId,
    this.isGuest = false,
  });

  @override
  List<Object?> get props => [userId, isGuest];
}

/// Migrate guest favorites to authenticated user (called after signup/login)
class MigrateGuestFavorites extends FavoritesEvent {
  final String guestUserId;
  final String authenticatedUserId;

  const MigrateGuestFavorites({
    required this.guestUserId,
    required this.authenticatedUserId,
  });

  @override
  List<Object?> get props => [guestUserId, authenticatedUserId];
}