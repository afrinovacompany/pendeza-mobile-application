// admin_bloc.dart - COMPLETE FIXED FILE
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/features/5_admin_panel/data/repositories/admin_repository.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/promotion_model.dart';
import 'package:pendeza/shared/models/transaction_model.dart';
import 'package:pendeza/app/services/service_locator.dart';

import '../../../3_owner_inspiration/data/model/inspiration_article_model.dart';
import '../../../3_owner_inspiration/data/model/lookbook_image_model.dart';
import '../../../3_owner_inspiration/domain/repository/inspiration_repository.dart';
import 'admin_event.dart';
import 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final AdminRepository _adminRepository;
  final InspirationRepository _inspirationRepository;

  AdminBloc({
    required AdminRepository adminRepository,
    InspirationRepository? inspirationRepository,
  })  : _adminRepository = adminRepository,
        _inspirationRepository =
            inspirationRepository ?? sl<InspirationRepository>(),
        super(AdminInitial()) {
    on<LoadAdminData>(_onLoadAdminData);
    on<UpdateUserRole>(_onUpdateUserRole);
    on<AddArticle>(_onAddArticle);
    on<AddLookbookItem>(_onAddLookbookItem);
    on<DeleteArticle>(_onDeleteArticle);
    on<DeleteLookbookItem>(_onDeleteLookbookItem);
    on<AddPlatformPromotion>(_onAddPlatformPromotion);
    on<DeletePlatformPromotion>(_onDeletePlatformPromotion);

    // NEW HANDLERS
    on<LoadNotificationHistory>(_onLoadNotificationHistory);
    on<SendNotification>(_onSendNotification);
    on<LoadAllTransactions>(_onLoadAllTransactions);
  }

  Future<void> _onLoadAdminData(LoadAdminData event, Emitter<AdminState> emit) async {
    AdminLoaded? currentState;
    if (state is AdminLoaded) {
      currentState = state as AdminLoaded;
    }

    emit(AdminLoading());
    try {
      final results = await Future.wait([
        _adminRepository.getAllUsers(),
        _adminRepository.getAllSalons(),
        _inspirationRepository.getArticles(),
        _inspirationRepository.getLookbook(),
        _adminRepository.getPlatformPromotions(),
      ]);

      final users = results[0] as List<UserModel>;
      final salons = results[1] as List<SalonModel>;
      final articles = results[2] as List<InspirationArticleModel>;
      final lookbook = results[3] as List<LookbookImageModel>;
      final promotions = results[4] as List<PromotionModel>;

      emit(AdminLoaded(
        users: users,
        salons: salons,
        articles: articles,
        lookbook: lookbook,
        promotions: promotions,
        notifications: currentState?.notifications ?? [],
      ));
    } catch (e, s) {
      log.e('Failed to load admin data', error: e, stackTrace: s);
      emit(AdminError(e.toString()));
      if (currentState != null) emit(currentState);
    }
  }

  Future<void> _onUpdateUserRole(UpdateUserRole event, Emitter<AdminState> emit) async {
    final currentState = state;
    try {
      await _adminRepository.updateUserRole(event.userId, event.newRole);
      add(LoadAdminData());
    } catch (e, s) {
      log.e('Failed to update user role', error: e, stackTrace: s);
      if (currentState is AdminLoaded) emit(currentState);
      emit(AdminError(e.toString()));
    }
  }

  Future<String> _uploadImage(String filePath, String folder) async {
    final file = File(filePath);
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = FirebaseStorage.instance
        .ref('inspiration_images')
        .child(folder)
        .child(fileName);
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _onAddArticle(AddArticle event, Emitter<AdminState> emit) async {
    final currentState = state;
    try {
      String? imageUrl;
      if (event.imagePath != null) {
        imageUrl = await _uploadImage(event.imagePath!, 'articles');
      }

      await _inspirationRepository.addArticle({
        'title': event.title,
        'summary': event.summary,
        'contentJson': event.contentJson,
        'imageUrl': imageUrl,
        'category': 'trends',
        'publishedAt': Timestamp.now(),
        'views': 0,
      });
      add(LoadAdminData());
    } catch (e, s) {
      log.e('Failed to add article', error: e, stackTrace: s);
      if (currentState is AdminLoaded) emit(currentState);
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onAddLookbookItem(AddLookbookItem event, Emitter<AdminState> emit) async {
    final currentState = state;
    try {
      final imageUrl = await _uploadImage(event.imagePath, 'lookbook');
      await _inspirationRepository.addLookbookItem({
        'title': event.title,
        'imageUrl': imageUrl,
        'tags': event.tags,
        'description': '',
        'uploadedAt': Timestamp.now(),
      });
      add(LoadAdminData());
    } catch (e, s) {
      log.e('Failed to add lookbook item', error: e, stackTrace: s);
      if (currentState is AdminLoaded) emit(currentState);
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteArticle(DeleteArticle event, Emitter<AdminState> emit) async {
    final currentState = state;
    try {
      await _inspirationRepository.deleteArticle(event.articleId, event.imageUrl);
      add(LoadAdminData());
    } catch (e, s) {
      log.e('Failed to delete article', error: e, stackTrace: s);
      if (currentState is AdminLoaded) emit(currentState);
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeleteLookbookItem(DeleteLookbookItem event, Emitter<AdminState> emit) async {
    final currentState = state;
    try {
      await _inspirationRepository.deleteLookbookItem(event.itemId, event.imageUrl);
      add(LoadAdminData());
    } catch (e, s) {
      log.e('Failed to delete lookbook item', error: e, stackTrace: s);
      if (currentState is AdminLoaded) emit(currentState);
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onAddPlatformPromotion(AddPlatformPromotion event, Emitter<AdminState> emit) async {
    final currentState = state;
    try {
      String imageUrl = event.promotion.imageUrl;

      if (event.imagePath != null) {
        final file = File(event.imagePath!);
        final fileName = 'promo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance.ref('promotions').child(fileName);
        await ref.putFile(file);
        imageUrl = await ref.getDownloadURL();
      }

      final newPromo = event.promotion.copyWith(imageUrl: imageUrl);
      await _adminRepository.addPromotion(newPromo);
      add(LoadAdminData());
    } catch (e, s) {
      log.e('Failed to add promotion', error: e, stackTrace: s);
      if (currentState is AdminLoaded) emit(currentState);
      emit(AdminError(e.toString()));
    }
  }

  Future<void> _onDeletePlatformPromotion(DeletePlatformPromotion event, Emitter<AdminState> emit) async {
    final currentState = state;
    try {
      await _adminRepository.deletePromotion(event.promotionId);
      add(LoadAdminData());
    } catch (e, s) {
      log.e('Failed to delete promotion', error: e, stackTrace: s);
      if (currentState is AdminLoaded) emit(currentState);
      emit(AdminError(e.toString()));
    }
  }

  // NEW: Load notification history
  Future<void> _onLoadNotificationHistory(LoadNotificationHistory event, Emitter<AdminState> emit) async {
    final currentState = state;
    emit(AdminLoading());

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notification_inbox')
          .orderBy('sentAt', descending: true)
          .limit(100)
          .get();

      final notifications = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      if (currentState is AdminLoaded) {
        emit(currentState.copyWith(notifications: notifications));
      } else {
        emit(AdminLoaded(
          users: [],
          salons: [],
          notifications: notifications,
        ));
      }
    } catch (e, s) {
      log.e('Failed to load notification history', error: e, stackTrace: s);
      emit(AdminError('Failed to load notifications: $e'));
      if (currentState is AdminLoaded) emit(currentState);
    }
  }

  // NEW: Send notification via Cloud Function
  Future<void> _onSendNotification(SendNotification event, Emitter<AdminState> emit) async {
    final currentState = state;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('send_admin_notification');
      final result = await callable.call(event.notificationData);

      log.i('Notification sent successfully: ${result.data}');

      // Reload history to show the new notification
      add(LoadNotificationHistory());
    } catch (e, s) {
      log.e('Failed to send notification', error: e, stackTrace: s);
      emit(AdminError('Failed to send notification: $e'));
      if (currentState is AdminLoaded) emit(currentState);
    }
  }

  // NEW: Load all transactions for admin view
  Future<void> _onLoadAllTransactions(LoadAllTransactions event, Emitter<AdminState> emit) async {
    final currentState = state;
    emit(AdminLoading());

    try {
      Query<Map<String, dynamic>> query = FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('createdAt', descending: true);

      // Apply type filter if specified
      if (event.filterType != null && event.filterType!.isNotEmpty) {
        query = query.where('type', isEqualTo: event.filterType);
      }

      // Apply status filter if specified
      if (event.filterStatus != null && event.filterStatus!.isNotEmpty) {
        query = query.where('status', isEqualTo: event.filterStatus);
      }

      final snapshot = await query.limit(event.limit).get();

      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      log.i('Loaded ${transactions.length} transactions for admin');

      if (currentState is AdminLoaded) {
        emit(currentState.copyWith(transactions: transactions));
      } else {
        emit(AdminLoaded(
          users: [],
          salons: [],
          transactions: transactions,
        ));
      }
    } catch (e, s) {
      log.e('Failed to load transactions', error: e, stackTrace: s);
      emit(AdminError('Failed to load transactions: $e'));
      if (currentState is AdminLoaded) emit(currentState);
    }
  }
}