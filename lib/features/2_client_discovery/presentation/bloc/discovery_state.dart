import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'discovery_event.dart';

/// Base class for all discovery states
abstract class DiscoveryState extends Equatable {
  const DiscoveryState();

  @override
  List<Object?> get props => [];
}

/// Initial state when screen is first opened
class DiscoveryInitial extends DiscoveryState {
  const DiscoveryInitial();
}

/// Loading state while fetching salons
class DiscoveryLoading extends DiscoveryState {
  const DiscoveryLoading();
}

/// Successfully loaded salons with current filters
class DiscoveryLoaded extends DiscoveryState {
  final List<SalonModel> allSalons;        // All fetched salons
  final List<SalonModel> filteredSalons;   // After applying filters
  final DiscoveryFilters filters;          // Current active filters
  final String? searchQuery;                // Current search text

  const DiscoveryLoaded({
    required this.allSalons,
    required this.filteredSalons,
    required this.filters,
    this.searchQuery,
  });

  /// Helper to check if any filters are active
  bool get hasActiveFilters =>
      filters.categoryId != null ||
          filters.maxDistanceKm != null ||
          filters.minRating != null ||
          filters.sortType != SortType.distance ||
          (searchQuery != null && searchQuery!.isNotEmpty);

  /// Count of active filters (for badge)
  int get activeFilterCount {
    int count = 0;
    if (filters.categoryId != null) count++;
    if (filters.maxDistanceKm != null) count++;
    if (filters.minRating != null) count++;
    return count;
  }

  @override
  List<Object?> get props => [
    allSalons,
    filteredSalons,
    filters,
    searchQuery,
  ];

  /// Copy method for easy state updates
  DiscoveryLoaded copyWith({
    List<SalonModel>? allSalons,
    List<SalonModel>? filteredSalons,
    DiscoveryFilters? filters,
    String? searchQuery,
    bool clearSearch = false,
  }) {
    return DiscoveryLoaded(
      allSalons: allSalons ?? this.allSalons,
      filteredSalons: filteredSalons ?? this.filteredSalons,
      filters: filters ?? this.filters,
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }
}

/// Error state when fetching fails
class DiscoveryError extends DiscoveryState {
  final String message;

  const DiscoveryError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Data class to hold all filter values
class DiscoveryFilters extends Equatable {
  final String? categoryId;
  final double? maxDistanceKm;
  final double? minRating;
  final SortType sortType;

  const DiscoveryFilters({
    this.categoryId,
    this.maxDistanceKm,
    this.minRating,
    this.sortType = SortType.distance,
  });

  /// Default filters (no filtering applied)
  factory DiscoveryFilters.defaults() {
    return const DiscoveryFilters();
  }

  /// Copy method for updating filters
  DiscoveryFilters copyWith({
    String? categoryId,
    double? maxDistanceKm,
    double? minRating,
    SortType? sortType,
    bool clearCategory = false,
    bool clearDistance = false,
    bool clearRating = false,
  }) {
    return DiscoveryFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      maxDistanceKm: clearDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      minRating: clearRating ? null : (minRating ?? this.minRating),
      sortType: sortType ?? this.sortType,
    );
  }

  @override
  List<Object?> get props => [categoryId, maxDistanceKm, minRating, sortType];
}