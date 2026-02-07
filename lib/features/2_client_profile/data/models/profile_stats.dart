import 'package:equatable/equatable.dart';

/// A lightweight model to hold user engagement statistics.
/// This adds the "Social Proof" element to the profile (e.g., "12 Bookings").
class ProfileStats extends Equatable {
  final int totalBookings;
  final int totalReviews;
  final int totalFavorites;

  const ProfileStats({
    this.totalBookings = 0,
    this.totalReviews = 0,
    this.totalFavorites = 0,
  });

  @override
  List<Object?> get props => [totalBookings, totalReviews, totalFavorites];
}