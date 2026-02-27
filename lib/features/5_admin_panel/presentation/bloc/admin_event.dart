// admin_event.dart - FULL UPDATED FILE
import 'package:equatable/equatable.dart';
import 'package:pendeza/shared/models/promotion_model.dart';

abstract class AdminEvent extends Equatable {
  const AdminEvent();
  @override
  List<Object> get props => [];
}

class LoadAdminData extends AdminEvent {}

class UpdateUserRole extends AdminEvent {
  final String userId;
  final String newRole;

  const UpdateUserRole({required this.userId, required this.newRole});

  @override
  List<Object> get props => [userId, newRole];
}

class AddArticle extends AdminEvent {
  final String title;
  final String summary;
  final String contentJson;
  final String? imagePath;

  const AddArticle({
    required this.title,
    required this.summary,
    required this.contentJson,
    this.imagePath,
  });
}

class AddLookbookItem extends AdminEvent {
  final String title;
  final List<String> tags;
  final String imagePath;
  const AddLookbookItem({required this.title, required this.tags, required this.imagePath});
}

class DeleteArticle extends AdminEvent {
  final String articleId;
  final String? imageUrl;
  const DeleteArticle(this.articleId, this.imageUrl);
}

class DeleteLookbookItem extends AdminEvent {
  final String itemId;
  final String imageUrl;
  const DeleteLookbookItem(this.itemId, this.imageUrl);
}

// --- NEW PROMOTION EVENTS ---
class AddPlatformPromotion extends AdminEvent {
  final PromotionModel promotion;
  final String? imagePath; // Path to local file if uploading new image

  const AddPlatformPromotion({required this.promotion, this.imagePath});
}

class DeletePlatformPromotion extends AdminEvent {
  final String promotionId;
  const DeletePlatformPromotion(this.promotionId);
}

// --- NEW NOTIFICATION EVENTS ---
class LoadNotificationHistory extends AdminEvent {}

class SendNotification extends AdminEvent {
  final Map<String, dynamic> notificationData;
  const SendNotification(this.notificationData);
}

// --- SALON APPROVAL EVENTS ---
class ApproveSalon extends AdminEvent {
  final String salonId;
  const ApproveSalon(this.salonId);

  @override
  List<Object> get props => [salonId];
}

class RejectSalon extends AdminEvent {
  final String salonId;
  final String reason;
  const RejectSalon({required this.salonId, required this.reason});

  @override
  List<Object> get props => [salonId, reason];
}

// --- TRANSACTION EVENTS ---
class LoadAllTransactions extends AdminEvent {
  final String? filterType; // deposit, payment, payout, etc.
  final String? filterStatus; // pending, completed, failed
  final int limit;

  const LoadAllTransactions({
    this.filterType,
    this.filterStatus,
    this.limit = 200,
  });

  @override
  List<Object> get props => [filterType ?? '', filterStatus ?? '', limit];
}