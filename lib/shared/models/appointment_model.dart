import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Appointment Status Constants
/// These define the lifecycle of a booking in the system.
abstract class AppointmentStatus {
  /// Initial state when appointment is created but payment not yet completed
  static const String pendingPayment = 'Pending Payment';

  /// Payment completed, appointment is confirmed
  static const String confirmed = 'Confirmed';

  /// Appointment time has passed and service was provided
  static const String completed = 'Completed';

  /// Appointment was cancelled by client or salon
  static const String cancelled = 'Cancelled';

  /// Client didn't show up for the appointment
  static const String noShow = 'No Show';

  /// Payment failed or expired (after timeout)
  static const String paymentFailed = 'Payment Failed';

  /// List of all valid statuses
  static const List<String> all = [
    pendingPayment,
    confirmed,
    completed,
    cancelled,
    noShow,
    paymentFailed,
  ];

  /// Statuses that count as "active" bookings (shown in upcoming)
  static const List<String> active = [
    pendingPayment,
    confirmed,
  ];

  /// Statuses that are considered "final" (no more changes expected)
  static const List<String> terminal = [
    completed,
    cancelled,
    noShow,
    paymentFailed,
  ];
}

/// Represents a confirmed or requested appointment booking.
class AppointmentModel extends Equatable {
  final String id;
  final String clientId;
  final String salonId;
  final String? staffId;
  final List<String> serviceIds;
  final DateTime startTime;
  final int durationMinutes;
  final double totalPrice;
  final String status;
  final DateTime createdAt;

  /// Payment-related fields (NEW)
  final String? paymentMethod;
  final String? paymentTransactionId;
  final DateTime? paidAt;

  const AppointmentModel({
    required this.id,
    required this.clientId,
    required this.salonId,
    this.staffId,
    required this.serviceIds,
    required this.startTime,
    required this.durationMinutes,
    required this.totalPrice,
    // CHANGED: Default to 'Pending Payment' instead of 'Confirmed'
    this.status = AppointmentStatus.pendingPayment,
    required this.createdAt,
    // NEW payment fields
    this.paymentMethod,
    this.paymentTransactionId,
    this.paidAt,
  });

  //============================================================================
  // COMPUTED PROPERTIES (Helpers for UI)
  //============================================================================

  /// Check if this appointment is awaiting payment
  bool get isPendingPayment => status == AppointmentStatus.pendingPayment;

  /// Check if this appointment is confirmed (paid)
  bool get isConfirmed => status == AppointmentStatus.confirmed;

  /// Check if this appointment is completed
  bool get isCompleted => status == AppointmentStatus.completed;

  /// Check if this appointment is cancelled
  bool get isCancelled => status == AppointmentStatus.cancelled;

  /// Check if this appointment is in an active state (not terminal)
  bool get isActive => AppointmentStatus.active.contains(status);

  /// Check if this appointment is in a terminal state
  bool get isTerminal => AppointmentStatus.terminal.contains(status);

  /// Check if this appointment is upcoming (future date + active status)
  bool get isUpcoming => startTime.isAfter(DateTime.now()) && isActive;

  /// Check if this appointment is in the past
  bool get isPast => startTime.isBefore(DateTime.now());

  /// Check if payment can still be completed (within reasonable time)
  bool get canCompletePayment {
    if (!isPendingPayment) return false;
    // Allow payment completion within 15 minutes of creation
    final cutoff = createdAt.add(const Duration(minutes: 15));
    return DateTime.now().isBefore(cutoff);
  }

  /// Get end time of appointment
  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

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
    paymentMethod,
    paymentTransactionId,
    paidAt,
  ];

  factory AppointmentModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppointmentModel(
      id: doc.id,
      clientId: data['clientId'] as String? ?? '',
      salonId: data['salonId'] as String? ?? '',
      staffId: data['staffId'] as String?,
      serviceIds: List<String>.from(data['serviceIds'] ?? []),
      startTime: (data['startTime'] as Timestamp).toDate(),
      durationMinutes: data['durationMinutes'] as int? ?? 0,
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      // CHANGED: Default to 'Pending Payment' if missing
      status: data['status'] as String? ?? AppointmentStatus.pendingPayment,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      // NEW: Payment fields
      paymentMethod: data['paymentMethod'] as String?,
      paymentTransactionId: data['paymentTransactionId'] as String?,
      paidAt: data['paidAt'] != null
          ? (data['paidAt'] as Timestamp).toDate()
          : null,
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
      // NEW: Payment fields (only write if not null)
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (paymentTransactionId != null) 'paymentTransactionId': paymentTransactionId,
      if (paidAt != null) 'paidAt': Timestamp.fromDate(paidAt!),
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? clientId,
    String? salonId,
    String? staffId,
    bool clearStaffId = false,
    List<String>? serviceIds,
    DateTime? startTime,
    int? durationMinutes,
    double? totalPrice,
    String? status,
    DateTime? createdAt,
    String? paymentMethod,
    String? paymentTransactionId,
    DateTime? paidAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      salonId: salonId ?? this.salonId,
      staffId: clearStaffId ? null : (staffId ?? this.staffId),
      serviceIds: serviceIds ?? this.serviceIds,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  @override
  String toString() {
    return 'AppointmentModel($id, $clientId, $salonId, $staffId, $serviceIds, '
        '$startTime, $durationMinutes, $totalPrice, $status, $createdAt)';
  }
}