import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a confirmed or requested appointment booking.
class AppointmentModel extends Equatable {
  final String id;
  final String clientId;
  final String salonId;
  final String staffId;
  final List<String> serviceIds;
  final DateTime startTime;
  final int durationMinutes;
  final double totalPrice;
  final String status; // 'Pending', 'Confirmed', 'Completed', 'Cancelled'
  final DateTime createdAt;

  const AppointmentModel({
    required this.id,
    required this.clientId,
    required this.salonId,
    required this.staffId,
    required this.serviceIds,
    required this.startTime,
    required this.durationMinutes,
    required this.totalPrice,
    this.status = 'Pending',
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    clientId,
    salonId,
    staffId,
    serviceIds,
    startTime,
    durationMinutes,
    totalPrice,
    status,
    createdAt,
  ];

  factory AppointmentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppointmentModel(
      id: doc.id,
      clientId: data['clientId'] as String? ?? '',
      salonId: data['salonId'] as String? ?? '',
      staffId: data['staffId'] as String? ?? '',
      serviceIds: List<String>.from(data['serviceIds'] ?? []),
      startTime: (data['startTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'Pending',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'salonId': salonId,
      'staffId': staffId,
      'serviceIds': serviceIds,
      'startTime': Timestamp.fromDate(startTime),
      'durationMinutes': durationMinutes,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Creates a copy of the current AppointmentModel instance with updated fields.
  AppointmentModel copyWith({
    String? id,
    String? clientId,
    String? salonId,
    String? staffId,
    List<String>? serviceIds,
    DateTime? startTime,
    int? durationMinutes,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      salonId: salonId ?? this.salonId,
      staffId: staffId ?? this.staffId,
      serviceIds: serviceIds ?? this.serviceIds,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
