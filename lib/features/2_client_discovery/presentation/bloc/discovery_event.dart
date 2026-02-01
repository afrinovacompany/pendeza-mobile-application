import 'package:equatable/equatable.dart';

/// Base class for all discovery events
abstract class DiscoveryEvent extends Equatable {
  const DiscoveryEvent();

  @override
  List<Object?> get props => [];
}

/// Fetches initial list of salons
class LoadSalons extends DiscoveryEvent {
  const LoadSalons();
}

/// Refreshes the salon list
class RefreshSalons extends DiscoveryEvent {
  const RefreshSalons();
}

/// Searches salons by query text
class SearchSalons extends DiscoveryEvent {
  final String query;

  const SearchSalons(this.query);

  @override
  List<Object?> get props => [query];
}

/// Filters salons by category
class FilterByCategory extends DiscoveryEvent {
  final String? categoryId; // null means "All"

  const FilterByCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Filters salons by distance
class FilterByDistance extends DiscoveryEvent {
  final double maxDistanceKm;

  const FilterByDistance(this.maxDistanceKm);

  @override
  List<Object?> get props => [maxDistanceKm];
}

/// Filters salons by minimum rating
class FilterByRating extends DiscoveryEvent {
  final double minRating;

  const FilterByRating(this.minRating);

  @override
  List<Object?> get props => [minRating];
}

/// Sorts salons by different criteria
class SortSalons extends DiscoveryEvent {
  final SortType sortType;

  const SortSalons(this.sortType);

  @override
  List<Object?> get props => [sortType];
}

/// Applies multiple filters at once (from filter panel)
class ApplyFilters extends DiscoveryEvent {
  final String? categoryId;
  final double? maxDistanceKm;
  final double? minRating;
  final SortType sortType;

  const ApplyFilters({
    this.categoryId,
    this.maxDistanceKm,
    this.minRating,
    this.sortType = SortType.distance,
  });

  @override
  List<Object?> get props => [categoryId, maxDistanceKm, minRating, sortType];
}

/// Resets all filters to default
class ResetFilters extends DiscoveryEvent {
  const ResetFilters();
}

/// Sort options for salons
enum SortType {
  distance,   // Closest first
  rating,     // Highest rated first
  popularity, // Most popular first
}

/// Extension to get display names for sort types
extension SortTypeExtension on SortType {
  String get displayName {
    switch (this) {
      case SortType.distance:
        return 'Closest';
      case SortType.rating:
        return 'Rating';
      case SortType.popularity:
        return 'Popular';
    }
  }
}