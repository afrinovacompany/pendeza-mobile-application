
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a specific, bookable service offered by a salon.
/// Enhanced with advanced features for world-class salon management.
class ServiceModel extends Equatable {
  final String id;
  final String salonId;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String category;
  final bool isActive;

  // Enhanced fields for better service management
  final String? imageUrl;
  final int bookingsCount; // Track popularity
  final double? discountedPrice; // For promotions
  final List<String> tags; // For better searchability
  final bool isFeatured; // Highlight popular services
  final int sortOrder; // Custom ordering
  final String? staffNote; // Internal notes for staff
  final bool requiresDeposit;
  final double? depositAmount;
  final int? maxDailyBookings; // Limit bookings per day
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ServiceModel({
    required this.id,
    required this.salonId,
    required this.name,
    this.description = '',
    required this.price,
    required this.durationMinutes,
    required this.category,
    this.isActive = true,
    this.imageUrl,
    this.bookingsCount = 0,
    this.discountedPrice,
    this.tags = const [],
    this.isFeatured = false,
    this.sortOrder = 0,
    this.staffNote,
    this.requiresDeposit = false,
    this.depositAmount,
    this.maxDailyBookings,
    this.createdAt,
    this.updatedAt,
  });

  // Computed properties
  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;
  double get effectivePrice => discountedPrice ?? price;
  double get discountPercentage =>
      hasDiscount ? ((price - discountedPrice!) / price * 100) : 0;
  String get formattedPrice => 'TZS ${price.toStringAsFixed(0)}';
  String get formattedDuration => '$durationMinutes min';
  bool get isPopular => bookingsCount >= 10;

  @override
  List<Object?> get props => [
        id,
        salonId,
        name,
        description,
        price,
        durationMinutes,
        category,
        isActive,
        imageUrl,
        bookingsCount,
        discountedPrice,
        tags,
        isFeatured,
        sortOrder,
        staffNote,
        requiresDeposit,
        depositAmount,
        maxDailyBookings,
      ];

  factory ServiceModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ServiceModel(
      id: doc.id,
      salonId: data['salonId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
      category: data['category'] as String? ?? 'Other',
      isActive: _firestoreBool(data['isActive'], fallback: true),
      imageUrl: data['imageUrl'] as String?,
      bookingsCount: (data['bookingsCount'] as num?)?.toInt() ?? 0,
      discountedPrice: (data['discountedPrice'] as num?)?.toDouble(),
      tags: List<String>.from(data['tags'] ?? []),
      isFeatured: data['isFeatured'] as bool? ?? false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      staffNote: data['staffNote'] as String?,
      requiresDeposit: data['requiresDeposit'] as bool? ?? false,
      depositAmount: (data['depositAmount'] as num?)?.toDouble(),
      maxDailyBookings: data['maxDailyBookings'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'salonId': salonId,
      'name': name,
      'description': description,
      'price': price,
      'durationMinutes': durationMinutes,
      'category': category,
      'isActive': isActive,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'bookingsCount': bookingsCount,
      if (discountedPrice != null) 'discountedPrice': discountedPrice,
      'tags': tags,
      'isFeatured': isFeatured,
      'sortOrder': sortOrder,
      if (staffNote != null) 'staffNote': staffNote,
      'requiresDeposit': requiresDeposit,
      if (depositAmount != null) 'depositAmount': depositAmount,
      if (maxDailyBookings != null) 'maxDailyBookings': maxDailyBookings,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ServiceModel copyWith({
    String? id,
    String? salonId,
    String? name,
    String? description,
    double? price,
    int? durationMinutes,
    String? category,
    bool? isActive,
    String? imageUrl,
    int? bookingsCount,
    double? discountedPrice,
    List<String>? tags,
    bool? isFeatured,
    int? sortOrder,
    String? staffNote,
    bool? requiresDeposit,
    double? depositAmount,
    int? maxDailyBookings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceModel(
      id: id ?? this.id,
      salonId: salonId ?? this.salonId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      imageUrl: imageUrl ?? this.imageUrl,
      bookingsCount: bookingsCount ?? this.bookingsCount,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      tags: tags ?? this.tags,
      isFeatured: isFeatured ?? this.isFeatured,
      sortOrder: sortOrder ?? this.sortOrder,
      staffNote: staffNote ?? this.staffNote,
      requiresDeposit: requiresDeposit ?? this.requiresDeposit,
      depositAmount: depositAmount ?? this.depositAmount,
      maxDailyBookings: maxDailyBookings ?? this.maxDailyBookings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

bool _firestoreBool(dynamic value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.toLowerCase().trim()) {
      case 'true':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case '0':
      case 'no':
        return false;
    }
  }
  return fallback;
}
