import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents the data model for a single salon or barbershop.
///
/// This class is used to structure salon data retrieved from and sent to
/// Firestore, ensuring type safety and consistent data handling.
class SalonModel extends Equatable {
  /// The unique document ID of the salon in Firestore.
  final String id;

  /// The UID of the user who owns this salon.
  final String ownerId;

  /// The official name of the salon.
  final String salonName;

  /// The full physical address of the salon.
  final String address;

  /// A list of service categories offered (e.g., "Hair", "Nails", "Massage").
  final List<String> serviceCategories;

  /// A URL to the salon's primary profile image.
  final String? profileImageUrl;

  /// The timestamp when the salon document was created.
  final DateTime createdAt;

  const SalonModel({
    required this.id,
    required this.ownerId,
    required this.salonName,
    required this.address,
    required this.serviceCategories,
    this.profileImageUrl,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    ownerId,
    salonName,
    address,
    serviceCategories,
    profileImageUrl,
    createdAt,
  ];

  /// Factory constructor to create a SalonModel from a Firestore document.
  factory SalonModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SalonModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      salonName: data['salonName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      serviceCategories: List<String>.from(data['serviceCategories'] ?? []),
      profileImageUrl: data['profileImageUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  /// Converts the SalonModel instance into a Map for writing to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'ownerId': ownerId,
      'salonName': salonName,
      'address': address,
      'serviceCategories': serviceCategories,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
