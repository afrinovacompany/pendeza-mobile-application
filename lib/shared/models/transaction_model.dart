import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Transaction Types in the Pendeza system
enum TransactionType {
  /// Client deposits money to wallet via PalmPesa
  deposit,

  /// Client pays for appointment from wallet
  payment,

  /// Owner withdraws earnings to M-Pesa
  payout,

  /// Owner pays for promotion/advertising
  promotion,

  /// Refund to client wallet (cancelled booking)
  refund,

  /// Platform commission (2% from bookings)
  commission,

  /// Manual adjustment by admin (rare)
  adjustment,
}

/// Transaction Status
enum TransactionStatus {
  /// Payment initiated but not confirmed yet
  pending,

  /// Payment completed successfully
  completed,

  /// Payment processing (webhook received, updating records)
  processing,

  /// Payment failed or was cancelled
  failed,

  /// Transaction reversed (refunded)
  reversed,
}

/// Represents any financial transaction in the Pendeza system.
///
/// This model tracks ALL money movements:
/// - Client deposits
/// - Booking payments
/// - Owner withdrawals
/// - Platform commissions
/// - Refunds
///
/// **KEY FIELDS:**
/// - userId: Primary user involved (payer or receiver)
/// - relatedUserId: Secondary user (e.g., salon owner receiving payment)
/// - referenceId: Links to related entity (appointmentId, withdrawalId, etc.)
/// - gatewayOrderId: PalmPesa transaction ID for tracking
class TransactionModel extends Equatable {
  /// Unique transaction ID
  final String id;

  /// Primary user ID (payer for deposits/payments, receiver for payouts)
  final String userId;

  /// Secondary user ID (e.g., salon owner for booking payments)
  final String? relatedUserId;

  /// Related entity ID (appointmentId, withdrawalId, promotionId, etc.)
  final String? referenceId;

  /// PalmPesa gateway order ID (for tracking with external API)
  final String gatewayOrderId;

  /// Transaction amount (in TZS)
  final double amount;

  /// Transaction fee (if applicable, e.g., PalmPesa charges)
  final double? fee;

  /// Net amount after fees (what actually moves)
  final double? netAmount;

  /// Transaction type
  final TransactionType type;

  /// Transaction status
  final TransactionStatus status;

  /// Payment provider/gateway
  final String provider;

  /// When transaction was created
  final DateTime createdAt;

  /// When transaction was completed (if status = completed)
  final DateTime? completedAt;

  /// Optional description/notes
  final String? description;

  /// Optional metadata (flexible JSON for future use)
  final Map<String, dynamic>? metadata;

  const TransactionModel({
    required this.id,
    required this.userId,
    this.relatedUserId,
    this.referenceId,
    required this.gatewayOrderId,
    required this.amount,
    this.fee,
    this.netAmount,
    required this.type,
    required this.status,
    this.provider = 'PalmPesa',
    required this.createdAt,
    this.completedAt,
    this.description,
    this.metadata,
  });

  //============================================================================
  // COMPUTED PROPERTIES
  //============================================================================

  /// Check if transaction is pending
  bool get isPending => status == TransactionStatus.pending;

  /// Check if transaction is completed
  bool get isCompleted => status == TransactionStatus.completed;

  /// Check if transaction failed
  bool get isFailed => status == TransactionStatus.failed;

  /// Check if transaction is processing
  bool get isProcessing => status == TransactionStatus.processing;

  /// Check if this is a deposit
  bool get isDeposit => type == TransactionType.deposit;

  /// Check if this is a payment
  bool get isPayment => type == TransactionType.payment;

  /// Check if this is a payout
  bool get isPayout => type == TransactionType.payout;

  /// Check if this is a refund
  bool get isRefund => type == TransactionType.refund;

  /// Format amount as currency
  String get formattedAmount => 'TZS ${amount.toStringAsFixed(0)}';

  /// Get human-readable type
  String get typeLabel {
    switch (type) {
      case TransactionType.deposit:
        return 'Deposit';
      case TransactionType.payment:
        return 'Payment';
      case TransactionType.payout:
        return 'Withdrawal';
      case TransactionType.promotion:
        return 'Promotion';
      case TransactionType.refund:
        return 'Refund';
      case TransactionType.commission:
        return 'Commission';
      case TransactionType.adjustment:
        return 'Adjustment';
    }
  }

  /// Get human-readable status
  String get statusLabel {
    switch (status) {
      case TransactionStatus.pending:
        return 'Pending';
      case TransactionStatus.completed:
        return 'Completed';
      case TransactionStatus.processing:
        return 'Processing';
      case TransactionStatus.failed:
        return 'Failed';
      case TransactionStatus.reversed:
        return 'Reversed';
    }
  }

  //============================================================================
  // FIRESTORE SERIALIZATION
  //============================================================================

  factory TransactionModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return TransactionModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      relatedUserId: data['relatedUserId'] as String?,
      referenceId: data['referenceId'] as String?,
      gatewayOrderId: data['gatewayOrderId'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      fee: (data['fee'] as num?)?.toDouble(),
      netAmount: (data['netAmount'] as num?)?.toDouble(),
      type: _parseTransactionType(data['type']),
      status: _parseTransactionStatus(data['status']),
      provider: data['provider'] as String? ?? 'PalmPesa',
      createdAt: _parseTimestamp(data['createdAt']),
      completedAt: data['completedAt'] != null
          ? _parseTimestamp(data['completedAt'])
          : null,
      description: data['description'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (relatedUserId != null) 'relatedUserId': relatedUserId,
      if (referenceId != null) 'referenceId': referenceId,
      'gatewayOrderId': gatewayOrderId,
      'amount': amount,
      if (fee != null) 'fee': fee,
      if (netAmount != null) 'netAmount': netAmount,
      'type': type.name,
      'status': status.name,
      'provider': provider,
      'createdAt': Timestamp.fromDate(createdAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      if (description != null) 'description': description,
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Parse TransactionType from string
  static TransactionType _parseTransactionType(dynamic value) {
    if (value == null) return TransactionType.payment;
    final typeStr = value.toString().toLowerCase();
    return TransactionType.values.firstWhere(
          (e) => e.name.toLowerCase() == typeStr,
      orElse: () => TransactionType.payment,
    );
  }

  /// Parse TransactionStatus from string
  static TransactionStatus _parseTransactionStatus(dynamic value) {
    if (value == null) return TransactionStatus.pending;
    final statusStr = value.toString().toLowerCase();
    return TransactionStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == statusStr,
      orElse: () => TransactionStatus.pending,
    );
  }

  /// Parse Timestamp safely
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  //============================================================================
  // FACTORY CONSTRUCTORS (Convenience methods)
  //============================================================================

  /// Create a deposit transaction
  factory TransactionModel.deposit({
    required String userId,
    required double amount,
    required String gatewayOrderId,
    String? description,
  }) {
    return TransactionModel(
      id: '', // Will be set by Firestore
      userId: userId,
      amount: amount,
      gatewayOrderId: gatewayOrderId,
      type: TransactionType.deposit,
      status: TransactionStatus.pending,
      createdAt: DateTime.now(),
      description: description ?? 'Wallet deposit via M-Pesa',
    );
  }

  /// Create a payment transaction (booking)
  factory TransactionModel.payment({
    required String userId,
    required String salonOwnerId,
    required String appointmentId,
    required double amount,
    String? description,
  }) {
    return TransactionModel(
      id: '', // Will be set by Firestore
      userId: userId,
      relatedUserId: salonOwnerId,
      referenceId: appointmentId,
      gatewayOrderId: 'WALLET_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      type: TransactionType.payment,
      status: TransactionStatus.completed,
      provider: 'Wallet',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      description: description ?? 'Booking payment from wallet',
    );
  }

  /// Create a refund transaction
  factory TransactionModel.refund({
    required String userId,
    required String appointmentId,
    required double amount,
    String? description,
  }) {
    return TransactionModel(
      id: '', // Will be set by Firestore
      userId: userId,
      referenceId: appointmentId,
      gatewayOrderId: 'REFUND_${DateTime.now().millisecondsSinceEpoch}',
      amount: amount,
      type: TransactionType.refund,
      status: TransactionStatus.completed,
      provider: 'System',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      description: description ?? 'Booking cancellation refund',
    );
  }

  //============================================================================
  // COPY WITH
  //============================================================================

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? relatedUserId,
    String? referenceId,
    String? gatewayOrderId,
    double? amount,
    double? fee,
    double? netAmount,
    TransactionType? type,
    TransactionStatus? status,
    String? provider,
    DateTime? createdAt,
    DateTime? completedAt,
    String? description,
    Map<String, dynamic>? metadata,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      relatedUserId: relatedUserId ?? this.relatedUserId,
      referenceId: referenceId ?? this.referenceId,
      gatewayOrderId: gatewayOrderId ?? this.gatewayOrderId,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      netAmount: netAmount ?? this.netAmount,
      type: type ?? this.type,
      status: status ?? this.status,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
    );
  }

  //============================================================================
  // EQUATABLE
  //============================================================================

  @override
  List<Object?> get props => [
    id,
    userId,
    relatedUserId,
    referenceId,
    gatewayOrderId,
    amount,
    fee,
    netAmount,
    type,
    status,
    provider,
    createdAt,
    completedAt,
    description,
    metadata,
  ];

  @override
  String toString() {
    return 'TransactionModel(id: $id, type: ${type.name}, amount: $amount, '
        'status: ${status.name}, userId: $userId)';
  }
}