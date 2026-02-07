import 'package:equatable/equatable.dart';

abstract class SalonProfileEvent extends Equatable {
  const SalonProfileEvent();

  @override
  List<Object?> get props => [];
}

//============================================================================
// EXISTING EVENTS (unchanged)
//============================================================================

/// Load salon profile
class LoadSalonProfile extends SalonProfileEvent {
  const LoadSalonProfile();
}

/// Refresh salon profile
class RefreshSalonProfile extends SalonProfileEvent {
  const RefreshSalonProfile();
}

/// Update basic info (name, description, address)
class UpdateBasicInfo extends SalonProfileEvent {
  final String salonName;
  final String? description;
  final String address;

  const UpdateBasicInfo({
    required this.salonName,
    this.description,
    required this.address,
  });

  @override
  List<Object?> get props => [salonName, description, address];
}

/// Update contact info
class UpdateContactInfo extends SalonProfileEvent {
  final String phoneNumber;
  final String? whatsappNumber;
  final String? instagram;
  final String? facebook;

  const UpdateContactInfo({
    required this.phoneNumber,
    this.whatsappNumber,
    this.instagram,
    this.facebook,
  });

  @override
  List<Object?> get props => [phoneNumber, whatsappNumber, instagram, facebook];
}

/// Upload primary or gallery image
class UploadSalonImage extends SalonProfileEvent {
  final String imagePath;
  final bool isPrimary;

  const UploadSalonImage(this.imagePath, {this.isPrimary = false});

  @override
  List<Object?> get props => [imagePath, isPrimary];
}

/// Delete primary image
class DeletePrimaryImage extends SalonProfileEvent {
  const DeletePrimaryImage();
}

/// Delete gallery image
class DeleteGalleryImage extends SalonProfileEvent {
  final int index;

  const DeleteGalleryImage(this.index);

  @override
  List<Object?> get props => [index];
}

/// Update business hours
class UpdateBusinessHours extends SalonProfileEvent {
  final String openingTime;
  final String closingTime;

  const UpdateBusinessHours({
    required this.openingTime,
    required this.closingTime,
  });

  @override
  List<Object?> get props => [openingTime, closingTime];
}

/// Update amenities
class UpdateAmenities extends SalonProfileEvent {
  final List<String> amenities;

  const UpdateAmenities(this.amenities);

  @override
  List<Object?> get props => [amenities];
}

//============================================================================
// 🎬 NEW: VIDEO EVENTS
//============================================================================

/// Load salon videos
class LoadSalonVideos extends SalonProfileEvent {
  const LoadSalonVideos();
}

/// Upload a new video
class UploadSalonVideo extends SalonProfileEvent {
  final String videoPath;
  final String? caption;

  const UploadSalonVideo({
    required this.videoPath,
    this.caption,
  });

  @override
  List<Object?> get props => [videoPath, caption];
}

/// Update video caption
class UpdateVideoCaption extends SalonProfileEvent {
  final String videoId;
  final String caption;

  const UpdateVideoCaption({
    required this.videoId,
    required this.caption,
  });

  @override
  List<Object?> get props => [videoId, caption];
}

/// Delete a video
class DeleteSalonVideo extends SalonProfileEvent {
  final String videoId;

  const DeleteSalonVideo(this.videoId);

  @override
  List<Object?> get props => [videoId];
}
