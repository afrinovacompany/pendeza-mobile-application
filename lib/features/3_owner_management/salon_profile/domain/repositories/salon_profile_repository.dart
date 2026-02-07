import 'package:pendeza/shared/models/salon_model.dart';

/// Repository interface for salon profile operations
abstract class SalonProfileRepository {
  /// Get salon profile by ID
  Future<SalonModel> getSalonProfile(String salonId);

  /// Update basic salon information
  Future<void> updateBasicInfo({
    required String salonId,
    required String salonName,
    String? description,
    required String address,
  });

  /// Update contact information
  Future<void> updateContactInfo({
    required String salonId,
    required String phoneNumber,
    String? whatsappNumber,
    String? instagram,
    String? facebook,
  });

  /// Upload image to Firebase Storage
  /// Returns the download URL
  Future<String> uploadImage({
    required String salonId,
    required String imagePath,
    required bool isPrimary,
    Function(double)? onProgress,
  });

  /// Update primary image URL in Firestore
  Future<void> updatePrimaryImage(String salonId, String imageUrl);

  /// Add image to gallery
  Future<void> addGalleryImage(String salonId, String imageUrl);

  /// Delete image from Storage
  Future<void> deleteImage(String imageUrl);

  /// Delete primary image
  Future<void> deletePrimaryImage(String salonId);

  /// Delete gallery image by index
  Future<void> deleteGalleryImage(String salonId, int index);

  /// Update business hours
  Future<void> updateBusinessHours({
    required String salonId,
    required String openingTime,
    required String closingTime,
  });

  /// Update amenities
  Future<void> updateAmenities({
    required String salonId,
    required List<String> amenities,
  });
}