import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a user's wallet in the Pendeza system.
///
/// The wallet stores the user's balance and tracks all financial activity.
/// Each user (client or owner) can have one wallet.
///
/// **IMPORTANT BUSINESS RULES:**
/// - Clients use wallets to pay for bookings
/// - Owners accumulate earnings in their wallets
/// - Minimum balance: 0 TZS (no negative balances allowed)
/// - All amounts are in Tanzanian Shillings (TZS)
class WalletModel extends Equatable {
  /// Unique identifier (same as userId for simplicity)
  final String id;

  /// User ID this wallet belongs to
  final String userId;

  /// Current available balance (in TZS)
  final double balance;

  /// Total amount ever deposited to this wallet
  final double totalDeposited;

  /// Total amount ever spent from this wallet
  final double totalSpent;

  /// Total amount ever withdrawn (for owners)
  final double totalWithdrawn;

  /// Wallet status: 'active', 'frozen', 'suspended'
  /// - active: Normal operations allowed
  /// - frozen: Temporarily disabled (e.g., pending investigation)
  /// - suspended: Permanently disabled
  final String status;

  /// When this wallet was created
  final DateTime createdAt;

  /// Last time balance was updated
  final DateTime lastUpdated;

  /// Optional: User's preferred withdrawal method (for owners)
  /// e.g., 'mpesa', 'tigopesa', 'airtel_money'
  final String? preferredWithdrawalMethod;

  /// Optional: Phone number for withdrawals
  final String? withdrawalPhoneNumber;

  const WalletModel({
    required this.id,
    required this.userId,
    this.balance = 0.0,
    this.totalDeposited = 0.0,
    this.totalSpent = 0.0,
    this.totalWithdrawn = 0.0,
    this.status = 'active',
    required this.createdAt,
    required this.lastUpdated,
    this.preferredWithdrawalMethod,
    this.withdrawalPhoneNumber,
  });

  //============================================================================
  // COMPUTED PROPERTIES (Business Logic Helpers)
  //============================================================================

  /// Check if wallet is active and can be used
  bool get isActive => status == 'active';

  /// Check if wallet is frozen
  bool get isFrozen => status == 'frozen';

  /// Check if wallet is suspended
  bool get isSuspended => status == 'suspended';

  /// Check if user can afford a specific amount
  bool canAfford(double amount) => balance >= amount && isActive;

  /// Check if wallet has any balance
  bool get hasBalance => balance > 0;

  /// Check if wallet has ever been used
  bool get hasActivity => totalDeposited > 0 || totalSpent > 0;

  /// Get net flow (deposits - spent - withdrawn)
  double get netFlow => totalDeposited - totalSpent - totalWithdrawn;

  /// Format balance as currency string
  String get formattedBalance => 'TZS ${balance.toStringAsFixed(0)}';

  //============================================================================
  // FIRESTORE SERIALIZATION
  //============================================================================

  /// Create WalletModel from Firestore document
  factory WalletModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return WalletModel(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      balance: (data['balance'] as num?)?.toDouble() ?? 0.0,
      totalDeposited: (data['totalDeposited'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalWithdrawn: (data['totalWithdrawn'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'active',
      createdAt: _parseTimestamp(data['createdAt']),
      lastUpdated: _parseTimestamp(data['lastUpdated']),
      preferredWithdrawalMethod: data['preferredWithdrawalMethod'] as String?,
      withdrawalPhoneNumber: data['withdrawalPhoneNumber'] as String?,
    );
  }

  /// Convert to Firestore-compatible map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'balance': balance,
      'totalDeposited': totalDeposited,
      'totalSpent': totalSpent,
      'totalWithdrawn': totalWithdrawn,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      if (preferredWithdrawalMethod != null)
        'preferredWithdrawalMethod': preferredWithdrawalMethod,
      if (withdrawalPhoneNumber != null)
        'withdrawalPhoneNumber': withdrawalPhoneNumber,
    };
  }

  /// Parse Timestamp safely
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  //============================================================================
  // FACTORY CONSTRUCTORS
  //============================================================================

  /// Create a new empty wallet for a user
  factory WalletModel.createNew({required String userId}) {
    return WalletModel(
      id: userId, // Wallet ID = User ID for simplicity
      userId: userId,
      balance: 0.0,
      totalDeposited: 0.0,
      totalSpent: 0.0,
      totalWithdrawn: 0.0,
      status: 'active',
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );
  }

  //============================================================================
  // COPY WITH (Immutable Updates)
  //============================================================================

  WalletModel copyWith({
    String? id,
    String? userId,
    double? balance,
    double? totalDeposited,
    double? totalSpent,
    double? totalWithdrawn,
    String? status,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? preferredWithdrawalMethod,
    String? withdrawalPhoneNumber,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      totalDeposited: totalDeposited ?? this.totalDeposited,
      totalSpent: totalSpent ?? this.totalSpent,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      preferredWithdrawalMethod:
      preferredWithdrawalMethod ?? this.preferredWithdrawalMethod,
      withdrawalPhoneNumber:
      withdrawalPhoneNumber ?? this.withdrawalPhoneNumber,
    );
  }

  //============================================================================
  // EQUATABLE
  //============================================================================

  @override
  List<Object?> get props => [
    id,
    userId,
    balance,
    totalDeposited,
    totalSpent,
    totalWithdrawn,
    status,
    createdAt,
    lastUpdated,
    preferredWithdrawalMethod,
    withdrawalPhoneNumber,
  ];

  @override
  String toString() {
    return 'WalletModel(id: $id, userId: $userId, balance: $balance, '
        'status: $status, lastUpdated: $lastUpdated)';
  }
}