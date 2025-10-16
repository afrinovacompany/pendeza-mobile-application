import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a staff member (stylist, barber, therapist) working at a salon.
class StaffModel extends Equatable {
  final String id;
  final String salonId;
  final String name;
  final String role; // e.g., 'Senior Stylist', 'Barber'
  final String? profilePictureUrl;
  final double rating;
  final List<String>
  serviceIds; // The specific services this staff member can perform

  const StaffModel({
    required this.id,
    required this.salonId,
    required this.name,
    required this.role,
    this.profilePictureUrl,
    this.rating = 0.0,
    required this.serviceIds,
  });

  @override
  List<Object?> get props => [
    id,
    salonId,
    name,
    role,
    profilePictureUrl,
    rating,
    serviceIds,
  ];

  factory StaffModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return StaffModel(
      id: doc.id,
      salonId: data['salonId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      role: data['role'] as String? ?? 'Staff',
      profilePictureUrl: data['profilePictureUrl'] as String?,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      serviceIds: List<String>.from(data['serviceIds'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'salonId': salonId,
      'name': name,
      'role': role,
      'profilePictureUrl': profilePictureUrl,
      'rating': rating,
      'serviceIds': serviceIds,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StaffModel copyWith({
    String? id,
    String? salonId,
    String? name,
    String? role,
    String? profilePictureUrl,
    double? rating,
    List<String>? serviceIds,
  }) {
    return StaffModel(
      id: id ?? this.id,
      salonId: salonId ?? this.salonId,
      name: name ?? this.name,
      role: role ?? this.role,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      rating: rating ?? this.rating,
      serviceIds: serviceIds ?? this.serviceIds,
    );
  }
}
