// admin_state.dart - FULL UPDATED FILE
import 'package:equatable/equatable.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/promotion_model.dart';
import 'package:pendeza/shared/models/transaction_model.dart';

import '../../../3_owner_inspiration/data/model/inspiration_article_model.dart';
import '../../../3_owner_inspiration/data/model/lookbook_image_model.dart';

abstract class AdminState extends Equatable {
  const AdminState();
  @override
  List<Object> get props => [];
}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<UserModel> users;
  final List<SalonModel> salons;
  final List<InspirationArticleModel> articles;
  final List<LookbookImageModel> lookbook;
  final List<PromotionModel> promotions;
  final List<Map<String, dynamic>> notifications;
  final List<TransactionModel> transactions; // unused while payments are off
  final List<AppointmentModel> appointments;
  final Map<String, String> serviceNames;
  final int totalAppointments;

  const AdminLoaded({
    required this.users,
    required this.salons,
    this.articles = const [],
    this.lookbook = const [],
    this.promotions = const [],
    this.notifications = const [],
    this.transactions = const [],
    this.appointments = const [],
    this.serviceNames = const {},
    this.totalAppointments = 0,
  });

  // Added copyWith for partial state updates
  AdminLoaded copyWith({
    List<UserModel>? users,
    List<SalonModel>? salons,
    List<InspirationArticleModel>? articles,
    List<LookbookImageModel>? lookbook,
    List<PromotionModel>? promotions,
    List<Map<String, dynamic>>? notifications,
    List<TransactionModel>? transactions,
    List<AppointmentModel>? appointments,
    Map<String, String>? serviceNames,
    int? totalAppointments,
  }) {
    return AdminLoaded(
      users: users ?? this.users,
      salons: salons ?? this.salons,
      articles: articles ?? this.articles,
      lookbook: lookbook ?? this.lookbook,
      promotions: promotions ?? this.promotions,
      notifications: notifications ?? this.notifications,
      transactions: transactions ?? this.transactions,
      appointments: appointments ?? this.appointments,
      serviceNames: serviceNames ?? this.serviceNames,
      totalAppointments: totalAppointments ?? this.totalAppointments,
    );
  }

  @override
  List<Object> get props => [
    users,
    salons,
    totalAppointments,
    articles,
    lookbook,
    promotions,
    notifications,
    transactions,
    appointments,
    serviceNames,
  ];
}

class AdminError extends AdminState {
  final String message;
  const AdminError(this.message);
  @override
  List<Object> get props => [message];
}