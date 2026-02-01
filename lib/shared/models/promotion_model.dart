import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// The type of promotion - determines where it appears and who controls it
enum PromotionType {
  /// Platform-wide promotions controlled by Pendeza admin
  /// Appears prominently in the main carousel
  platform,

  /// Salon-specific promotions controlled by salon owners
  /// Appears in carousel and on salon detail page
  salon,

  /// System-generated personalized offers
  /// Based on user behavior (e.g., "Come back!" offers)
  personalized,
}

/// The type of discount offered
enum DiscountType {
  /// Percentage off (e.g., 20% off)
  percentage,

  /// Fixed amount off (e.g., 5000 TZS off)
  fixedAmount,

  /// Free add-on service (e.g., free nail art with manicure)
  freebie,

  /// No discount - just awareness/announcement
  none,
}

/// What action happens when user taps the promotion
enum PromotionAction {
  /// Open the discover/search screen
  openDiscover,

  /// Navigate to a specific salon
  openSalon,

  /// Filter by a specific category
  openCategory,

  /// Open external link (e.g., terms & conditions)
  openUrl,

  /// No action - just informational
  none,
}

/// Target audience for the promotion
enum PromotionAudience {
  /// Show to all users
  all,

  /// Show only to new users (no previous bookings)
  newUsers,

  /// Show only to returning users (has previous bookings)
  returning,

  /// Show only to users who haven't booked in X days
  inactive,
}

/// Represents a promotion in the Pendeza app.
///
/// Promotions can be:
/// 1. Platform-wide (controlled by Pendeza admin)
/// 2. Salon-specific (controlled by salon owners)
/// 3. Personalized (system-generated based on user behavior)
///
/// Firestore Structure:
/// - Platform promos: `promotions/{promoId}`
/// - Salon promos: `salons/{salonId}/promotions/{promoId}`
class PromotionModel extends Equatable {
  /// Unique identifier for the promotion
  final String id;

  /// Type of promotion (platform, salon, personalized)
  final PromotionType type;

  /// The salon ID if this is a salon-specific promotion
  /// Null for platform promotions
  final String? salonId;

  /// The salon name (denormalized for display)
  final String? salonName;

  // ============ DISPLAY CONTENT ============

  /// Main title of the promotion
  final String title;

  /// Description/subtitle
  final String description;

  /// URL to the banner image (Canva-designed)
  final String imageUrl;

  /// Optional promo code that users can apply
  final String? promoCode;

  // ============ DISCOUNT DETAILS ============

  /// Type of discount offered
  final DiscountType discountType;

  /// Value of the discount
  /// For percentage: 20 means 20%
  /// For fixedAmount: 5000 means 5000 TZS
  /// For freebie: not used
  final double? discountValue;

  /// Minimum booking amount to qualify for discount
  final double? minimumSpend;

  /// Maximum discount amount (for percentage discounts)
  final double? maximumDiscount;

  /// List of service IDs this promotion applies to
  /// Null or empty means applies to all services
  final List<String>? applicableServiceIds;

  /// List of category IDs this promotion applies to
  final List<String>? applicableCategoryIds;

  // ============ SCHEDULING ============

  /// When the promotion starts
  final DateTime startDate;

  /// When the promotion ends
  final DateTime endDate;

  /// Whether the promotion is currently active
  final bool isActive;

  // ============ TARGETING ============

  /// Target audience for this promotion
  final PromotionAudience audience;

  /// Priority for display order (higher = shown first)
  /// Platform promos typically have higher priority
  final int priority;

  // ============ LIMITS & TRACKING ============

  /// Maximum number of times this promo can be used (null = unlimited)
  final int? usageLimit;

  /// Current usage count
  final int usageCount;

  /// Maximum uses per user (null = unlimited)
  final int? usageLimitPerUser;

  // ============ FEATURED (PAID) ============

  /// Whether this is a featured (paid) promotion
  /// Featured promos appear first in carousel
  final bool isFeatured;

  /// When the featured status expires
  final DateTime? featuredUntil;

  // ============ ACTION ============

  /// What happens when user taps the promotion
  final PromotionAction action;

  /// Value for the action (salonId, categoryId, or URL)
  final String? actionValue;

  // ============ METADATA ============

  /// When the promotion was created
  final DateTime createdAt;

  /// When the promotion was last updated
  final DateTime? updatedAt;

  /// ID of the user who created this promotion
  final String? createdBy;

  const PromotionModel({
    required this.id,
    required this.type,
    this.salonId,
    this.salonName,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.promoCode,
    required this.discountType,
    this.discountValue,
    this.minimumSpend,
    this.maximumDiscount,
    this.applicableServiceIds,
    this.applicableCategoryIds,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.audience = PromotionAudience.all,
    this.priority = 0,
    this.usageLimit,
    this.usageCount = 0,
    this.usageLimitPerUser,
    this.isFeatured = false,
    this.featuredUntil,
    this.action = PromotionAction.none,
    this.actionValue,
    required this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  // ============ COMPUTED PROPERTIES ============

  /// Check if the promotion is currently valid (active and within date range)
  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        now.isAfter(startDate) &&
        now.isBefore(endDate) &&
        !isUsedUp;
  }

  /// Check if the promotion has been used up
  bool get isUsedUp {
    if (usageLimit == null) return false;
    return usageCount >= usageLimit!;
  }

  /// Get remaining uses (null if unlimited)
  int? get remainingUses {
    if (usageLimit == null) return null;
    return usageLimit! - usageCount;
  }

  /// Days until promotion expires
  int get daysUntilExpiry {
    return endDate.difference(DateTime.now()).inDays;
  }

  /// Hours until promotion expires (for same-day promos)
  int get hoursUntilExpiry {
    return endDate.difference(DateTime.now()).inHours;
  }

  /// Human-readable expiry text
  String get expiryText {
    final days = daysUntilExpiry;
    if (days < 0) return 'Expired';
    if (days == 0) {
      final hours = hoursUntilExpiry;
      if (hours <= 0) return 'Expires soon';
      return 'Expires in $hours hours';
    }
    if (days == 1) return 'Expires tomorrow';
    if (days <= 7) return 'Expires in $days days';
    return 'Expires ${_formatDate(endDate)}';
  }

  /// Check if promotion is expiring soon (within 3 days)
  bool get isExpiringSoon => daysUntilExpiry >= 0 && daysUntilExpiry <= 3;

  /// Human-readable discount text
  String get discountText {
    switch (discountType) {
      case DiscountType.percentage:
        return '${discountValue?.toInt()}% OFF';
      case DiscountType.fixedAmount:
        return '${_formatCurrency(discountValue ?? 0)} OFF';
      case DiscountType.freebie:
        return 'FREE GIFT';
      case DiscountType.none:
        return '';
    }
  }

  /// Check if this is a platform promotion
  bool get isPlatformPromo => type == PromotionType.platform;

  /// Check if this is a salon promotion
  bool get isSalonPromo => type == PromotionType.salon;

  // ============ FACTORY CONSTRUCTORS ============

  /// Create from Firestore document
  factory PromotionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc, {
        String? salonId,
      }) {
    final data = doc.data() ?? {};
    return PromotionModel(
      id: doc.id,
      type: _parsePromotionType(data['type'] as String?),
      salonId: salonId ?? data['salonId'] as String?,
      salonName: data['salonName'] as String?,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      promoCode: data['promoCode'] as String?,
      discountType: _parseDiscountType(data['discountType'] as String?),
      discountValue: (data['discountValue'] as num?)?.toDouble(),
      minimumSpend: (data['minimumSpend'] as num?)?.toDouble(),
      maximumDiscount: (data['maximumDiscount'] as num?)?.toDouble(),
      applicableServiceIds: _parseStringList(data['applicableServiceIds']),
      applicableCategoryIds: _parseStringList(data['applicableCategoryIds']),
      startDate: _parseTimestamp(data['startDate']),
      endDate: _parseTimestamp(data['endDate']),
      isActive: data['isActive'] as bool? ?? true,
      audience: _parseAudience(data['audience'] as String?),
      priority: data['priority'] as int? ?? 0,
      usageLimit: data['usageLimit'] as int?,
      usageCount: data['usageCount'] as int? ?? 0,
      usageLimitPerUser: data['usageLimitPerUser'] as int?,
      isFeatured: data['isFeatured'] as bool? ?? false,
      featuredUntil: _parseTimestampNullable(data['featuredUntil']),
      action: _parseAction(data['action'] as String?),
      actionValue: data['actionValue'] as String?,
      createdAt: _parseTimestamp(data['createdAt']),
      updatedAt: _parseTimestampNullable(data['updatedAt']),
      createdBy: data['createdBy'] as String?,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'salonId': salonId,
      'salonName': salonName,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'promoCode': promoCode,
      'discountType': discountType.name,
      'discountValue': discountValue,
      'minimumSpend': minimumSpend,
      'maximumDiscount': maximumDiscount,
      'applicableServiceIds': applicableServiceIds,
      'applicableCategoryIds': applicableCategoryIds,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'audience': audience.name,
      'priority': priority,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'usageLimitPerUser': usageLimitPerUser,
      'isFeatured': isFeatured,
      'featuredUntil': featuredUntil != null
          ? Timestamp.fromDate(featuredUntil!)
          : null,
      'action': action.name,
      'actionValue': actionValue,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'createdBy': createdBy,
    };
  }

  /// Create a copy with updated fields
  PromotionModel copyWith({
    String? id,
    PromotionType? type,
    String? salonId,
    String? salonName,
    String? title,
    String? description,
    String? imageUrl,
    String? promoCode,
    DiscountType? discountType,
    double? discountValue,
    double? minimumSpend,
    double? maximumDiscount,
    List<String>? applicableServiceIds,
    List<String>? applicableCategoryIds,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    PromotionAudience? audience,
    int? priority,
    int? usageLimit,
    int? usageCount,
    int? usageLimitPerUser,
    bool? isFeatured,
    DateTime? featuredUntil,
    PromotionAction? action,
    String? actionValue,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return PromotionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      salonId: salonId ?? this.salonId,
      salonName: salonName ?? this.salonName,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      promoCode: promoCode ?? this.promoCode,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minimumSpend: minimumSpend ?? this.minimumSpend,
      maximumDiscount: maximumDiscount ?? this.maximumDiscount,
      applicableServiceIds: applicableServiceIds ?? this.applicableServiceIds,
      applicableCategoryIds: applicableCategoryIds ?? this.applicableCategoryIds,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      audience: audience ?? this.audience,
      priority: priority ?? this.priority,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      usageLimitPerUser: usageLimitPerUser ?? this.usageLimitPerUser,
      isFeatured: isFeatured ?? this.isFeatured,
      featuredUntil: featuredUntil ?? this.featuredUntil,
      action: action ?? this.action,
      actionValue: actionValue ?? this.actionValue,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  // ============ HELPER METHODS ============

  static PromotionType _parsePromotionType(String? value) {
    switch (value) {
      case 'platform':
        return PromotionType.platform;
      case 'salon':
        return PromotionType.salon;
      case 'personalized':
        return PromotionType.personalized;
      default:
        return PromotionType.platform;
    }
  }

  static DiscountType _parseDiscountType(String? value) {
    switch (value) {
      case 'percentage':
        return DiscountType.percentage;
      case 'fixedAmount':
        return DiscountType.fixedAmount;
      case 'freebie':
        return DiscountType.freebie;
      case 'none':
        return DiscountType.none;
      default:
        return DiscountType.none;
    }
  }

  static PromotionAudience _parseAudience(String? value) {
    switch (value) {
      case 'all':
        return PromotionAudience.all;
      case 'newUsers':
        return PromotionAudience.newUsers;
      case 'returning':
        return PromotionAudience.returning;
      case 'inactive':
        return PromotionAudience.inactive;
      default:
        return PromotionAudience.all;
    }
  }

  static PromotionAction _parseAction(String? value) {
    switch (value) {
      case 'openDiscover':
        return PromotionAction.openDiscover;
      case 'openSalon':
        return PromotionAction.openSalon;
      case 'openCategory':
        return PromotionAction.openCategory;
      case 'openUrl':
        return PromotionAction.openUrl;
      case 'none':
        return PromotionAction.none;
      default:
        return PromotionAction.none;
    }
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static DateTime? _parseTimestampNullable(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value == null) return null;
    if (value is List) return List<String>.from(value);
    return null;
  }

  static String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  static String _formatCurrency(double amount) {
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K TZS';
    }
    return '${amount.toStringAsFixed(0)} TZS';
  }

  @override
  List<Object?> get props => [
    id,
    type,
    salonId,
    title,
    description,
    imageUrl,
    promoCode,
    discountType,
    discountValue,
    startDate,
    endDate,
    isActive,
    priority,
    isFeatured,
  ];

  @override
  String toString() =>
      'PromotionModel(id: $id, title: $title, type: ${type.name})';
}