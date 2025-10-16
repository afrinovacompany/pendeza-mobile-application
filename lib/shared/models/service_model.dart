
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a specific, bookable service offered by a salon.
class ServiceModel extends Equatable {
  final String id;
  final String salonId;
  final String name;
  final String description;
  final double price; // TZS
  final int durationMinutes;
  final String category;
  final bool isActive;

  const ServiceModel({
    required this.id,
    required this.salonId,
    required this.name,
    this.description = '',
    required this.price,
    required this.durationMinutes,
    required this.category,
    this.isActive = true,
  });

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
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      category: data['category'] as String? ?? 'Other',
      isActive: data['isActive'] as bool? ?? true,
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
      'createdAt': FieldValue.serverTimestamp(),
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
    );
  }
}
