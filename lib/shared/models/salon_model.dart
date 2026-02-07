import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// **ENHANCED** Salon Model - Production Ready!
///
/// This model now includes:
/// - Multi-select business types
/// - Owner verification system
/// - Tanzania location structure (Region + District)
/// - All existing features maintained
class SalonModel extends Equatable {
  //============================================================================
  // CORE FIELDS (Required)
  //============================================================================
  final String id;
  final String ownerId;
  final String salonName;
  final String address;
  final List<String> serviceCategories; // e.g., ["Hair Services", "Nails", "Makeup"]
  final DateTime createdAt;

  //============================================================================
  // **NEW**: BUSINESS TYPES (Multi-select)
  //============================================================================
  /// List of business type IDs selected during onboarding
  /// Examples: ["barbershop_male", "spa_massage"]
  final List<String> businessTypeIds;

  /// List of human-readable business type names
  /// Examples: ["Barbershop (Men)", "Spa & Massage"]
  final List<String> businessTypeNames;

  //============================================================================
  // **NEW**: LOCATION (Tanzania Structure)
  //============================================================================
  /// Region name (e.g., "Dar es Salaam", "Arusha")
  final String? region;

  /// District name (e.g., "Kinondoni", "Temeke")
  final String? district;

  //============================================================================
  // **NEW**: VERIFICATION SYSTEM
  //============================================================================
  /// Verification status: 'pending', 'approved', 'rejected'
  final String verificationStatus;

  /// When the owner submitted for verification
  final DateTime? submittedAt;

  /// When the verification was reviewed (approved/rejected)
  final DateTime? reviewedAt;

  /// Reason for rejection (if status is 'rejected')
  final String? rejectionReason;

  // NOTE: No 'reviewedBy' field as per your requirement

  //============================================================================
  // IMAGES (Simple!)
  //============================================================================
  final String? primaryImage; // Main salon photo
  final List<String>? imageGallery; // Additional photos (just URLs!)

  //============================================================================
  // CONTACT INFO
  //============================================================================
  final String? phoneNumber; // Main phone
  final String? whatsappNumber; // WhatsApp (can be same as phone)
  final String? instagram; // Instagram username (no @)
  final String? facebook; // Facebook page URL

  //============================================================================
  // BUSINESS INFO
  //============================================================================
  final String? description; // About the salon
  final String? openingTime; // "08:00" (optional)
  final String? closingTime; // "20:00" (optional)

  //============================================================================
  // AMENITIES (Simple list!)
  //============================================================================
  final List<String>? amenities; // ["WiFi", "Parking", "AC"]

  const SalonModel({
    // Core fields
    required this.id,
    required this.ownerId,
    required this.salonName,
    required this.address,
    required this.serviceCategories,
    required this.createdAt,
    // Business types (NEW - with defaults for backward compatibility)
    this.businessTypeIds = const [],
    this.businessTypeNames = const [],
    // Location (NEW)
    this.region,
    this.district,
    // Verification (NEW - defaults to approved for existing salons)
    this.verificationStatus = 'approved',
    this.submittedAt,
    this.reviewedAt,
    this.rejectionReason,
    // Images
    this.primaryImage,
    this.imageGallery,
    // Contact
    this.phoneNumber,
    this.whatsappNumber,
    this.instagram,
    this.facebook,
    // Business info
    this.description,
    this.openingTime,
    this.closingTime,
    // Amenities
    this.amenities,
  });

  //============================================================================
  // FACTORY CONSTRUCTORS
  //============================================================================

  /// From Firestore document
  factory SalonModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SalonModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      salonName: data['salonName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      serviceCategories: List<String>.from(data['serviceCategories'] ?? []),
      createdAt: _parseDateTime(data['createdAt']),
      // Business types (NEW)
      businessTypeIds: List<String>.from(data['businessTypeIds'] ?? []),
      businessTypeNames: List<String>.from(data['businessTypeNames'] ?? []),
      // Location (NEW)
      region: data['region'] as String?,
      district: data['district'] as String?,
      // Verification (NEW)
      verificationStatus: data['verificationStatus'] as String? ?? 'approved',
      submittedAt: data['submittedAt'] != null
          ? _parseDateTime(data['submittedAt'])
          : null,
      reviewedAt: data['reviewedAt'] != null
          ? _parseDateTime(data['reviewedAt'])
          : null,
      rejectionReason: data['rejectionReason'] as String?,
      // Images
      primaryImage: data['primaryImage'] as String?,
      imageGallery: data['imageGallery'] != null
          ? List<String>.from(data['imageGallery'])
          : null,
      // Contact
      phoneNumber: data['phoneNumber'] as String?,
      whatsappNumber: data['whatsappNumber'] as String?,
      instagram: data['instagram'] as String?,
      facebook: data['facebook'] as String?,
      // Business info
      description: data['description'] as String?,
      openingTime: data['openingTime'] as String?,
      closingTime: data['closingTime'] as String?,
      // Amenities
      amenities: data['amenities'] != null
          ? List<String>.from(data['amenities'])
          : null,
    );
  }

  /// Parse DateTime from various formats
  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    if (value is DateTime) return value;
    return DateTime.now();
  }

  //============================================================================
  // TO FIRESTORE
  //============================================================================

  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'salonName': salonName,
      'address': address,
      'serviceCategories': serviceCategories,
      'createdAt': Timestamp.fromDate(createdAt),
      // Business types (NEW)
      'businessTypeIds': businessTypeIds,
      'businessTypeNames': businessTypeNames,
      // Location (NEW)
      if (region != null) 'region': region,
      if (district != null) 'district': district,
      // Verification (NEW)
      'verificationStatus': verificationStatus,
      if (submittedAt != null) 'submittedAt': Timestamp.fromDate(submittedAt!),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      // Images
      if (primaryImage != null) 'primaryImage': primaryImage,
      'imageGallery': imageGallery ?? [],
      // Contact
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (whatsappNumber != null) 'whatsappNumber': whatsappNumber,
      if (instagram != null) 'instagram': instagram,
      if (facebook != null) 'facebook': facebook,
      // Business info
      if (description != null) 'description': description,
      if (openingTime != null) 'openingTime': openingTime,
      if (closingTime != null) 'closingTime': closingTime,
      // Amenities
      'amenities': amenities ?? [],
    };
  }

  //============================================================================
  // HELPER GETTERS
  //============================================================================

  /// Check if salon has any images
  bool get hasImages =>
      primaryImage != null || (imageGallery?.isNotEmpty ?? false);

  /// Get total image count
  int get imageCount {
    int count = 0;
    if (primaryImage != null) count++;
    if (imageGallery != null) count += imageGallery!.length;
    return count;
  }

  /// Get all images as list (primary + gallery)
  List<String> get allImages {
    final images = <String>[];
    if (primaryImage != null) images.add(primaryImage!);
    if (imageGallery != null) images.addAll(imageGallery!);
    return images;
  }

  /// Check if salon has contact info
  bool get hasContactInfo =>
      phoneNumber != null ||
          whatsappNumber != null ||
          instagram != null ||
          facebook != null;

  /// Check if salon has amenities
  bool get hasAmenities => amenities?.isNotEmpty ?? false;

  /// **NEW**: Check if salon has business types
  bool get hasBusinessTypes => businessTypeIds.isNotEmpty;

  /// **NEW**: Check if salon has location info
  bool get hasLocation => region != null && district != null;

  /// **NEW**: Check if salon is pending verification
  bool get isPending => verificationStatus == 'pending';

  /// **NEW**: Check if salon is approved
  bool get isApproved => verificationStatus == 'approved';

  /// **NEW**: Check if salon is rejected
  bool get isRejected => verificationStatus == 'rejected';

  /// **NEW**: Get full location string
  String? get fullLocation {
    if (region != null && district != null) {
      return '$district, $region';
    }
    return null;
  }

  /// Whether the salon has business hours set
  bool get hasBusinessHours => openingTime != null && closingTime != null;

  /// Check if salon is currently open based on opening/closing times.
  /// Returns true if hours are not set (assume open).
  bool get isOpen {
    if (!hasBusinessHours) return true;
    try {
      final now = DateTime.now();
      final openParts = openingTime!.split(':');
      final closeParts = closingTime!.split(':');

      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);

      final openTime = DateTime(now.year, now.month, now.day, openHour, openMinute);
      final closeTime = DateTime(now.year, now.month, now.day, closeHour, closeMinute);

      return now.isAfter(openTime) && now.isBefore(closeTime);
    } catch (_) {
      return true;
    }
  }

  /// Check if booking is allowed (only blocked for pending approval salons)
  bool get isBookable => verificationStatus != 'pending';

  //============================================================================
  // COPY WITH
  //============================================================================

  SalonModel copyWith({
    String? id,
    String? ownerId,
    String? salonName,
    String? address,
    List<String>? serviceCategories,
    DateTime? createdAt,
    // Business types
    List<String>? businessTypeIds,
    List<String>? businessTypeNames,
    // Location
    String? region,
    String? district,
    // Verification
    String? verificationStatus,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? rejectionReason,
    // Images
    String? primaryImage,
    List<String>? imageGallery,
    // Contact
    String? phoneNumber,
    String? whatsappNumber,
    String? instagram,
    String? facebook,
    // Business info
    String? description,
    String? openingTime,
    String? closingTime,
    // Amenities
    List<String>? amenities,
  }) {
    return SalonModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      salonName: salonName ?? this.salonName,
      address: address ?? this.address,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      createdAt: createdAt ?? this.createdAt,
      // Business types
      businessTypeIds: businessTypeIds ?? this.businessTypeIds,
      businessTypeNames: businessTypeNames ?? this.businessTypeNames,
      // Location
      region: region ?? this.region,
      district: district ?? this.district,
      // Verification
      verificationStatus: verificationStatus ?? this.verificationStatus,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      // Images
      primaryImage: primaryImage ?? this.primaryImage,
      imageGallery: imageGallery ?? this.imageGallery,
      // Contact
      phoneNumber: phoneNumber ?? this.phoneNumber,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      // Business info
      description: description ?? this.description,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      // Amenities
      amenities: amenities ?? this.amenities,
    );
  }

  //============================================================================
  // EQUATABLE
  //============================================================================

  @override
  List<Object?> get props => [
    id,
    ownerId,
    salonName,
    address,
    serviceCategories,
    createdAt,
    businessTypeIds,
    businessTypeNames,
    region,
    district,
    verificationStatus,
    submittedAt,
    reviewedAt,
    rejectionReason,
    primaryImage,
    imageGallery,
    phoneNumber,
    whatsappNumber,
    instagram,
    facebook,
    description,
    openingTime,
    closingTime,
    amenities,
  ];
}