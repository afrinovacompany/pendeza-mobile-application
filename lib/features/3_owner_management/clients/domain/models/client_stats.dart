import 'package:equatable/equatable.dart';

/// Model representing client statistics and insights
class ClientStats extends Equatable {
  final String clientId;
  final String clientName;
  final String? phoneNumber;
  final String? email;
  final String? profilePictureUrl;
  final int totalAppointments;
  final int completedAppointments;
  final int cancelledAppointments;
  final double totalSpent;
  final DateTime firstVisit;
  final DateTime lastVisit;
  final List<String> favoriteServices;

  const ClientStats({
    required this.clientId,
    required this.clientName,
    this.phoneNumber,
    this.email,
    this.profilePictureUrl,
    required this.totalAppointments,
    required this.completedAppointments,
    required this.cancelledAppointments,
    required this.totalSpent,
    required this.firstVisit,
    required this.lastVisit,
    required this.favoriteServices,
  });

  @override
  List<Object?> get props => [
    clientId,
    clientName,
    phoneNumber,
    email,
    profilePictureUrl,
    totalAppointments,
    completedAppointments,
    cancelledAppointments,
    totalSpent,
    firstVisit,
    lastVisit,
    favoriteServices,
  ];

  /// Calculate completion rate percentage
  double get completionRate {
    if (totalAppointments == 0) return 0.0;
    return (completedAppointments / totalAppointments) * 100;
  }

  /// Check if client is a regular (3+ completed appointments)
  bool get isRegularClient => completedAppointments >= 3;

  /// Calculate average spending per visit
  double get averageSpending {
    if (completedAppointments == 0) return 0.0;
    return totalSpent / completedAppointments;
  }

  ClientStats copyWith({
    String? clientId,
    String? clientName,
    String? phoneNumber,
    String? email,
    String? profilePictureUrl,
    int? totalAppointments,
    int? completedAppointments,
    int? cancelledAppointments,
    double? totalSpent,
    DateTime? firstVisit,
    DateTime? lastVisit,
    List<String>? favoriteServices,
  }) {
    return ClientStats(
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      totalAppointments: totalAppointments ?? this.totalAppointments,
      completedAppointments:
      completedAppointments ?? this.completedAppointments,
      cancelledAppointments:
      cancelledAppointments ?? this.cancelledAppointments,
      totalSpent: totalSpent ?? this.totalSpent,
      firstVisit: firstVisit ?? this.firstVisit,
      lastVisit: lastVisit ?? this.lastVisit,
      favoriteServices: favoriteServices ?? this.favoriteServices,
    );
  }
}