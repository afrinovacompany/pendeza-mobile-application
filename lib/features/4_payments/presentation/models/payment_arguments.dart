// =============================================================================
// Payment Arguments Model
// =============================================================================
// Data class for passing payment information between screens.
// Used by GoRouter when navigating to the payment screen.
// =============================================================================

/// Arguments required for the payment screen
///
/// This class encapsulates all the data needed to process a payment.
/// It's passed via GoRouter's `extra` parameter.
///
/// Example usage:
/// ```dart
/// context.push('/payment', extra: PaymentArguments(
///   appointmentId: 'apt_123',
///   amount: 25000,
///   customerName: 'John Doe',
///   customerEmail: 'john@example.com',
///   salonOwnerId: 'owner_456',
/// ));
/// ```
class PaymentArguments {
  /// The unique identifier of the appointment being paid for
  final String appointmentId;

  /// The total amount to be paid in TZS
  final double amount;

  /// Customer's full name for payment records
  final String customerName;

  /// Customer's email for payment receipts
  final String customerEmail;

  /// Salon owner's ID for wallet payment routing
  /// Required for wallet-to-wallet transfers
  final String? salonOwnerId;

  const PaymentArguments({
    required this.appointmentId,
    required this.amount,
    required this.customerName,
    required this.customerEmail,
    this.salonOwnerId,
  });

  /// Creates a copy with optional field overrides
  PaymentArguments copyWith({
    String? appointmentId,
    double? amount,
    String? customerName,
    String? customerEmail,
    String? salonOwnerId,
  }) {
    return PaymentArguments(
      appointmentId: appointmentId ?? this.appointmentId,
      amount: amount ?? this.amount,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      salonOwnerId: salonOwnerId ?? this.salonOwnerId,
    );
  }

  /// Formatted amount string for display
  String get formattedAmount => 'TZS ${amount.toStringAsFixed(0)}';

  @override
  String toString() {
    return 'PaymentArguments(appointmentId: $appointmentId, amount: $amount, '
        'customerName: $customerName, salonOwnerId: $salonOwnerId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentArguments &&
        other.appointmentId == appointmentId &&
        other.amount == amount &&
        other.customerName == customerName &&
        other.customerEmail == customerEmail &&
        other.salonOwnerId == salonOwnerId;
  }

  @override
  int get hashCode {
    return Object.hash(
      appointmentId,
      amount,
      customerName,
      customerEmail,
      salonOwnerId,
    );
  }
}