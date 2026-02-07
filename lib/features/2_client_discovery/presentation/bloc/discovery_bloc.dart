import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/2_client_booking/domain/repositories/booking_repository.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'discovery_event.dart';
import 'discovery_state.dart';

/// BLoC for managing salon discovery with filtering and sorting
class DiscoveryBloc extends Bloc<DiscoveryEvent, DiscoveryState> {
  final BookingRepository _bookingRepository;

  DiscoveryBloc(this._bookingRepository) : super(const DiscoveryInitial()) {
    on<LoadSalons>(_onLoadSalons);
    on<RefreshSalons>(_onRefreshSalons);
    on<SearchSalons>(_onSearchSalons);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByDistance>(_onFilterByDistance);
    on<FilterByRating>(_onFilterByRating);
    on<SortSalons>(_onSortSalons);
    on<ApplyFilters>(_onApplyFilters);
    on<ResetFilters>(_onResetFilters);
  }

  /// Loads initial salon list
  Future<void> _onLoadSalons(
      LoadSalons event,
      Emitter<DiscoveryState> emit,
      ) async {
    emit(const DiscoveryLoading());

    try {
      final salons = await _bookingRepository.getSalons();

      // Apply default sorting (by popularity)
      final sortedSalons = _sortSalons(salons, SortType.popularity);

      emit(DiscoveryLoaded(
        allSalons: salons,
        filteredSalons: sortedSalons,
        filters: DiscoveryFilters.defaults(),
      ));
    } catch (e) {
      emit(DiscoveryError('Failed to load: ${e.toString()}'));
    }
  }

  /// Refreshes salon list
  Future<void> _onRefreshSalons(
      RefreshSalons event,
      Emitter<DiscoveryState> emit,
      ) async {
    final currentState = state;

    try {
      final salons = await _bookingRepository.getSalons();

      if (currentState is DiscoveryLoaded) {
        // Reapply current filters to refreshed data
        final filtered = _applyAllFilters(
          salons,
          currentState.filters,
          currentState.searchQuery,
        );

        emit(currentState.copyWith(
          allSalons: salons,
          filteredSalons: filtered,
        ));
      } else {
        // Fresh load
        final sortedSalons = _sortSalons(salons, SortType.popularity);
        emit(DiscoveryLoaded(
          allSalons: salons,
          filteredSalons: sortedSalons,
          filters: DiscoveryFilters.defaults(),
        ));
      }
    } catch (e) {
      emit(DiscoveryError('Failed to refresh: ${e.toString()}'));
    }
  }

  /// Searches salons by query
  void _onSearchSalons(
      SearchSalons event,
      Emitter<DiscoveryState> emit,
      ) {
    final currentState = state;
    if (currentState is! DiscoveryLoaded) return;

    final filtered = _applyAllFilters(
      currentState.allSalons,
      currentState.filters,
      event.query,
    );

    emit(currentState.copyWith(
      filteredSalons: filtered,
      searchQuery: event.query,
    ));
  }

  /// Filters by category
  void _onFilterByCategory(
      FilterByCategory event,
      Emitter<DiscoveryState> emit,
      ) {
    final currentState = state;
    if (currentState is! DiscoveryLoaded) return;

    final newFilters = currentState.filters.copyWith(
      categoryId: event.categoryId,
      clearCategory: event.categoryId == null,
    );

    final filtered = _applyAllFilters(
      currentState.allSalons,
      newFilters,
      currentState.searchQuery,
    );

    emit(currentState.copyWith(
      filteredSalons: filtered,
      filters: newFilters,
    ));
  }

  /// Filters by distance
  void _onFilterByDistance(
      FilterByDistance event,
      Emitter<DiscoveryState> emit,
      ) {
    final currentState = state;
    if (currentState is! DiscoveryLoaded) return;

    final newFilters = currentState.filters.copyWith(
      maxDistanceKm: event.maxDistanceKm,
    );

    final filtered = _applyAllFilters(
      currentState.allSalons,
      newFilters,
      currentState.searchQuery,
    );

    emit(currentState.copyWith(
      filteredSalons: filtered,
      filters: newFilters,
    ));
  }

  /// Filters by rating
  void _onFilterByRating(
      FilterByRating event,
      Emitter<DiscoveryState> emit,
      ) {
    final currentState = state;
    if (currentState is! DiscoveryLoaded) return;

    final newFilters = currentState.filters.copyWith(
      minRating: event.minRating,
    );

    final filtered = _applyAllFilters(
      currentState.allSalons,
      newFilters,
      currentState.searchQuery,
    );

    emit(currentState.copyWith(
      filteredSalons: filtered,
      filters: newFilters,
    ));
  }

  /// Sorts salons
  void _onSortSalons(
      SortSalons event,
      Emitter<DiscoveryState> emit,
      ) {
    final currentState = state;
    if (currentState is! DiscoveryLoaded) return;

    final newFilters = currentState.filters.copyWith(
      sortType: event.sortType,
    );

    final filtered = _applyAllFilters(
      currentState.allSalons,
      newFilters,
      currentState.searchQuery,
    );

    emit(currentState.copyWith(
      filteredSalons: filtered,
      filters: newFilters,
    ));
  }

  /// Applies multiple filters at once (from filter panel)
  void _onApplyFilters(
      ApplyFilters event,
      Emitter<DiscoveryState> emit,
      ) {
    final currentState = state;
    if (currentState is! DiscoveryLoaded) return;

    final newFilters = DiscoveryFilters(
      categoryId: event.categoryId,
      maxDistanceKm: event.maxDistanceKm,
      minRating: event.minRating,
      sortType: event.sortType,
    );

    final filtered = _applyAllFilters(
      currentState.allSalons,
      newFilters,
      currentState.searchQuery,
    );

    emit(currentState.copyWith(
      filteredSalons: filtered,
      filters: newFilters,
    ));
  }

  /// Resets all filters
  void _onResetFilters(
      ResetFilters event,
      Emitter<DiscoveryState> emit,
      ) {
    final currentState = state;
    if (currentState is! DiscoveryLoaded) return;

    final defaultFilters = DiscoveryFilters.defaults();
    final filtered = _sortSalons(currentState.allSalons, SortType.popularity);

    emit(currentState.copyWith(
      filteredSalons: filtered,
      filters: defaultFilters,
      clearSearch: true,
    ));
  }

  //============================================================================
  // HELPER METHODS
  //============================================================================

  /// Applies all filters and returns filtered list
  List<SalonModel> _applyAllFilters(
      List<SalonModel> salons,
      DiscoveryFilters filters,
      String? searchQuery,
      ) {
    var filtered = List<SalonModel>.from(salons);

    // Apply search filter
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filtered = _filterBySearch(filtered, searchQuery);
    }

    // Apply category filter
    if (filters.categoryId != null) {
      filtered = _filterByCategory(filtered, filters.categoryId!);
    }

    // Apply distance filter (mock for now - would use real geolocation)
    if (filters.maxDistanceKm != null) {
      filtered = _filterByDistance(filtered, filters.maxDistanceKm!);
    }

    // Apply rating filter (mock for now - would use real ratings)
    if (filters.minRating != null) {
      filtered = _filterByRating(filtered, filters.minRating!);
    }

    // Apply sorting
    filtered = _sortSalons(filtered, filters.sortType);

    return filtered;
  }

  /// Filters salons by search query (name, address, categories)
  List<SalonModel> _filterBySearch(List<SalonModel> salons, String query) {
    final lowerQuery = query.toLowerCase();
    return salons.where((salon) {
      return salon.salonName.toLowerCase().contains(lowerQuery) ||
          salon.address.toLowerCase().contains(lowerQuery) ||
          salon.serviceCategories.any(
                (cat) => cat.toLowerCase().contains(lowerQuery),
          );
    }).toList();
  }

  /// 🔥 SMART CATEGORY FILTER 🔥
  /// Matches salons if ANY of their categories contain the filter text.
  /// Example: Filter "massage" matches "Massage Therapy", "Thai Massage", etc.
  List<SalonModel> _filterByCategory(List<SalonModel> salons, String categoryId) {
    final filterKey = categoryId.toLowerCase();

    return salons.where((salon) {
      // Check if ANY of the salon's categories contain our filter key
      // e.g. if salon has "Massage Therapy", and filter is "massage" -> MATCH!
      return salon.serviceCategories.any((cat) =>
          cat.toLowerCase().contains(filterKey)
      );
    }).toList();
  }

  /// Filters salons by distance (mock - would use real geolocation)
  List<SalonModel> _filterByDistance(List<SalonModel> salons, double maxKm) {
    // TODO: Implement real distance calculation using user location
    // For now, return all salons
    return salons;
  }

  /// Filters salons by rating (mock - would use real ratings from reviews)
  List<SalonModel> _filterByRating(List<SalonModel> salons, double minRating) {
    // TODO: Implement real rating filtering from reviews collection
    // For now, return all salons
    return salons;
  }

  /// Sorts salons by specified criteria
  List<SalonModel> _sortSalons(List<SalonModel> salons, SortType sortType) {
    final sorted = List<SalonModel>.from(salons);

    switch (sortType) {
      case SortType.popularity:
        // Sort by booking count or views
        // For now, sort alphabetically as a baseline
        sorted.sort((a, b) => a.salonName.compareTo(b.salonName));
        break;

      case SortType.rating:
        // TODO: Sort by actual rating from reviews
        // For now, sort by name reversed
        sorted.sort((a, b) => b.salonName.compareTo(a.salonName));
        break;

      case SortType.newest:
        // Sort by creation date (newest first)
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    return sorted;
  }
}