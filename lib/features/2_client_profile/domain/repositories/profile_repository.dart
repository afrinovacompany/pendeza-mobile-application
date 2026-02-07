import 'dart:io';
import '../../data/models/profile_stats.dart';


/// The contract for all profile-related data operations.
/// Separating this from AuthRepository keeps the code clean and focused.
abstract class ProfileRepository {
  /// Fetches the social stats (bookings count, reviews, etc.) for a user.
  Future<ProfileStats> getUserStats(String userId);

  /// Uploads a new profile picture, gets the URL, and updates the User document.
  /// Returns the updated URL.
  Future<String> updateProfileImage({
    required String userId,
    required File imageFile,
  });

  /// Updates specific fields in the user's profile (e.g., name, phone).
  Future<void> updateProfileData({
    required String userId,
    required Map<String, dynamic> data,
  });

  /// Change app-specific settings (notifications, language preference).
  Future<void> updateAppSettings({
    required String userId,
    required Map<String, dynamic> settings,
  });
}