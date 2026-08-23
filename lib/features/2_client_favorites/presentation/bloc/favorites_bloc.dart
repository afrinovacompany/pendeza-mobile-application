import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/utils/logger.dart';
import '../../domain/repositories/favorites_repository.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

/// BLoC for managing favorites feature.
///
/// This BLoC handles:
/// - Loading user's favorite salons
/// - Adding/removing favorites
/// - Toggling favorite status
/// - Guest to authenticated user migration
/// - Real-time updates for authenticated users
class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository _favoritesRepository;

  FavoritesBloc({
    required FavoritesRepository favoritesRepository,
  })  : _favoritesRepository = favoritesRepository,
        super(const FavoritesInitial()) {
    // Register event handlers
    on<LoadFavorites>(_onLoadFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<AddFavorite>(_onAddFavorite);
    on<RemoveFavorite>(_onRemoveFavorite);
    on<RefreshFavorites>(_onRefreshFavorites);
    on<CheckIsFavorited>(_onCheckIsFavorited);
    on<ClearAllFavorites>(_onClearAllFavorites);
    on<MigrateGuestFavorites>(_onMigrateGuestFavorites);
  }

  //============================================================================
  // LOAD FAVORITES
  //============================================================================

  Future<void> _onLoadFavorites(
      LoadFavorites event,
      Emitter<FavoritesState> emit,
      ) async {
    try {
      emit(const FavoritesLoading());

      log.i('Loading favorites for user: ${event.userId} (guest: ${event.isGuest})');

      // Get favorite salon IDs
      final salonIds = await _favoritesRepository.getFavoriteSalonIds(
        userId: event.userId,
        isGuest: event.isGuest,
      );

      // If no favorites, emit empty state
      if (salonIds.isEmpty) {
        emit(const FavoritesEmpty());
        return;
      }

      // Get full salon details
      final salons = await _favoritesRepository.getFavoriteSalons(
        userId: event.userId,
        isGuest: event.isGuest,
      );

      emit(FavoritesLoaded(
        favoriteSalons: salons,
        favoriteSalonIds: salonIds,
        totalCount: salonIds.length,
      ));

      log.i('Loaded ${salons.length} favorite salons');
    } catch (e, s) {
      log.e('Error loading favorites', error: e, stackTrace: s);
      emit(FavoritesError(
        message: 'Failed to load favorites. Please try again.',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // TOGGLE FAVORITE
  //============================================================================

  Future<void> _onToggleFavorite(
      ToggleFavorite event,
      Emitter<FavoritesState> emit,
      ) async {
    try {
      // Emit toggling state for optimistic UI update
      final currentState = state;
      bool wasAdding = true;

      // Check current status
      final isFav = await _favoritesRepository.isFavorited(
        userId: event.userId,
        salonId: event.salonId,
        isGuest: event.isGuest,
      );

      wasAdding = !isFav; // If not favorited, we're adding

      emit(FavoriteToggling(
        salonId: event.salonId,
        isAdding: wasAdding,
      ));

      // Perform the toggle
      final newStatus = await _favoritesRepository.toggleFavorite(
        userId: event.userId,
        salonId: event.salonId,
        isGuest: event.isGuest,
      );

      // Emit success state
      emit(FavoriteToggled(
        salonId: event.salonId,
        isFavorited: newStatus,
        message: newStatus
            ? 'Added to favorites'
            : 'Removed from favorites',
      ));

      // If we were in loaded state, update the list
      if (currentState is FavoritesLoaded) {
        // Refresh the favorites list
        add(RefreshFavorites(
          userId: event.userId,
          isGuest: event.isGuest,
        ));
      }

      log.i('Toggled favorite for salon ${event.salonId}: $newStatus');
    } catch (e, s) {
      log.e('Error toggling favorite', error: e, stackTrace: s);
      emit(FavoritesError(
        message: 'Failed to update favorite. Please try again.',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // ADD FAVORITE
  //============================================================================

  Future<void> _onAddFavorite(
      AddFavorite event,
      Emitter<FavoritesState> emit,
      ) async {
    try {
      emit(FavoriteToggling(
        salonId: event.salonId,
        isAdding: true,
      ));

      await _favoritesRepository.addFavorite(
        userId: event.userId,
        salonId: event.salonId,
        isGuest: event.isGuest,
      );

      emit(FavoriteToggled(
        salonId: event.salonId,
        isFavorited: true,
        message: 'Added to favorites',
      ));

      // Refresh list if we're viewing favorites
      if (state is FavoritesLoaded) {
        add(RefreshFavorites(
          userId: event.userId,
          isGuest: event.isGuest,
        ));
      }

      log.i('Added salon ${event.salonId} to favorites');
    } catch (e, s) {
      log.e('Error adding favorite', error: e, stackTrace: s);
      emit(FavoritesError(
        message: 'Failed to add favorite. Please try again.',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // REMOVE FAVORITE
  //============================================================================

  Future<void> _onRemoveFavorite(
      RemoveFavorite event,
      Emitter<FavoritesState> emit,
      ) async {
    try {
      emit(FavoriteToggling(
        salonId: event.salonId,
        isAdding: false,
      ));

      await _favoritesRepository.removeFavorite(
        userId: event.userId,
        salonId: event.salonId,
        isGuest: event.isGuest,
      );

      emit(FavoriteToggled(
        salonId: event.salonId,
        isFavorited: false,
        message: 'Removed from favorites',
      ));

      // Refresh list if we're viewing favorites
      if (state is FavoritesLoaded) {
        add(RefreshFavorites(
          userId: event.userId,
          isGuest: event.isGuest,
        ));
      }

      log.i('Removed salon ${event.salonId} from favorites');
    } catch (e, s) {
      log.e('Error removing favorite', error: e, stackTrace: s);
      emit(FavoritesError(
        message: 'Failed to remove favorite. Please try again.',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // REFRESH FAVORITES
  //============================================================================

  Future<void> _onRefreshFavorites(
      RefreshFavorites event,
      Emitter<FavoritesState> emit,
      ) async {
    try {
      // Don't show loading state on refresh (smoother UX)
      final salonIds = await _favoritesRepository.getFavoriteSalonIds(
        userId: event.userId,
        isGuest: event.isGuest,
      );

      if (salonIds.isEmpty) {
        emit(const FavoritesEmpty());
        return;
      }

      final salons = await _favoritesRepository.getFavoriteSalons(
        userId: event.userId,
        isGuest: event.isGuest,
      );

      emit(FavoritesLoaded(
        favoriteSalons: salons,
        favoriteSalonIds: salonIds,
        totalCount: salonIds.length,
      ));

      log.i('Refreshed ${salons.length} favorite salons');
    } catch (e, s) {
      log.e('Error refreshing favorites', error: e, stackTrace: s);
      emit(FavoritesError(
        message: 'Failed to refresh favorites.',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // CHECK IS FAVORITED
  //============================================================================

  Future<void> _onCheckIsFavorited(
      CheckIsFavorited event,
      Emitter<FavoritesState> emit,
      ) async {
    try {
      final isFav = await _favoritesRepository.isFavorited(
        userId: event.userId,
        salonId: event.salonId,
        isGuest: event.isGuest,
      );

      // This is mainly for single card updates
      // You might want to handle this differently in your UI
      log.d('Salon ${event.salonId} favorited: $isFav');
    } catch (e, s) {
      log.e('Error checking if favorited', error: e, stackTrace: s);
    }
  }

  //============================================================================
  // CLEAR ALL FAVORITES
  //============================================================================

  Future<void> _onClearAllFavorites(
      ClearAllFavorites event,
      Emitter<FavoritesState> emit,
      ) async {
    try {
      emit(const FavoritesLoading());

      await _favoritesRepository.clearAllFavorites(
        userId: event.userId,
        isGuest: event.isGuest,
      );

      emit(const FavoritesEmpty(
        message: 'All favorites cleared',
      ));

      log.i('Cleared all favorites for user ${event.userId}');
    } catch (e, s) {
      log.e('Error clearing favorites', error: e, stackTrace: s);
      emit(FavoritesError(
        message: 'Failed to clear favorites.',
        errorCode: e.toString(),
      ));
    }
  }

  //============================================================================
  // MIGRATE GUEST FAVORITES
  //============================================================================

  Future<void> _onMigrateGuestFavorites(
      MigrateGuestFavorites event,
      Emitter<FavoritesState> emit,
      ) async {
    try {
      // Get count of guest favorites to migrate
      final guestCount = await _favoritesRepository.getFavoritesCount(
        userId: event.guestUserId,
        isGuest: true,
      );

      if (guestCount == 0) {
        log.i('No guest favorites to migrate');
        return;
      }

      emit(FavoritesMigrating(totalToMigrate: guestCount));

      // Perform migration
      await _favoritesRepository.migrateGuestFavorites(
        guestUserId: event.guestUserId,
        authenticatedUserId: event.authenticatedUserId,
      );

      emit(FavoritesMigrated(
        migratedCount: guestCount,
        message: 'Migrated $guestCount favorites to your account',
      ));

      // Load the newly migrated favorites
      add(LoadFavorites(
        userId: event.authenticatedUserId,
        isGuest: false,
      ));

      log.i('Successfully migrated $guestCount favorites');
    } catch (e, s) {
      log.e('Error migrating guest favorites', error: e, stackTrace: s);
      emit(FavoritesError(
        message: 'Failed to migrate favorites. Don\'t worry, your favorites are safe!',
        errorCode: e.toString(),
      ));
    }
  }
}