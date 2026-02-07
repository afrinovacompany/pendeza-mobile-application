import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_model.dart';

/// Base class for all favorite states
abstract class FavoritesState extends Equatable {
  const FavoritesState();

  @override
  List<Object?> get props => [];
}

/// Initial state when favorites haven't been loaded yet
class FavoritesInitial extends FavoritesState {
  const FavoritesInitial();
}

/// Loading state while fetching favorites
class FavoritesLoading extends FavoritesState {
  const FavoritesLoading();
}

/// Successfully loaded favorites with salon data
class FavoritesLoaded extends FavoritesState {
  final List<SalonModel> favoriteSalons;
  final List<String> favoriteSalonIds;
  final int totalCount;

  const FavoritesLoaded({
    required this.favoriteSalons,
    required this.favoriteSalonIds,
    required this.totalCount,
  });

  /// Check if a specific salon is favorited
  bool isFavorited(String salonId) {
    return favoriteSalonIds.contains(salonId);
  }

  /// Check if there are any favorites
  bool get hasFavorites => favoriteSalons.isNotEmpty;

  @override
  List<Object?> get props => [favoriteSalons, favoriteSalonIds, totalCount];

  /// Copy method for easy state updates
  FavoritesLoaded copyWith({
    List<SalonModel>? favoriteSalons,
    List<String>? favoriteSalonIds,
    int? totalCount,
  }) {
    return FavoritesLoaded(
      favoriteSalons: favoriteSalons ?? this.favoriteSalons,
      favoriteSalonIds: favoriteSalonIds ?? this.favoriteSalonIds,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// State when a single favorite is being toggled (optimistic update)
class FavoriteToggling extends FavoritesState {
  final String salonId;
  final bool isAdding; // true = adding, false = removing

  const FavoriteToggling({
    required this.salonId,
    required this.isAdding,
  });

  @override
  List<Object?> get props => [salonId, isAdding];
}

/// State after successfully toggling a favorite
class FavoriteToggled extends FavoritesState {
  final String salonId;
  final bool isFavorited; // Current favorite status after toggle
  final String message; // Success message to show to user

  const FavoriteToggled({
    required this.salonId,
    required this.isFavorited,
    required this.message,
  });

  @override
  List<Object?> get props => [salonId, isFavorited, message];
}

/// Empty state when user has no favorites
class FavoritesEmpty extends FavoritesState {
  final String message;

  const FavoritesEmpty({
    this.message = 'No favorites yet. Start exploring salons!',
  });

  @override
  List<Object?> get props => [message];
}

/// Error state when something goes wrong
class FavoritesError extends FavoritesState {
  final String message;
  final String? errorCode;

  const FavoritesError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

/// State during migration of guest favorites
class FavoritesMigrating extends FavoritesState {
  final int totalToMigrate;

  const FavoritesMigrating({
    required this.totalToMigrate,
  });

  @override
  List<Object?> get props => [totalToMigrate];
}

/// State after successful migration
class FavoritesMigrated extends FavoritesState {
  final int migratedCount;
  final String message;

  const FavoritesMigrated({
    required this.migratedCount,
    required this.message,
  });

  @override
  List<Object?> get props => [migratedCount, message];
}