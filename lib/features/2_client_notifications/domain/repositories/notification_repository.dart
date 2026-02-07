import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/shared/models/notification_model.dart';
import 'package:pendeza/app/utils/logger.dart';

/// Repository for managing user notifications
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection reference for notifications
  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Get notifications for a user
  Future<List<NotificationModel>> getNotifications(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
    } catch (e, stackTrace) {
      log.e('Error fetching notifications', error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Stream notifications for real-time updates
  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  /// Get unread notification count
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e, stackTrace) {
      log.e('Error getting unread count', error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Stream unread notification count for real-time badge updates
  Stream<int> streamUnreadCount(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      log.e('Error marking notification as read',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      log.i('Marked ${snapshot.docs.length} notifications as read');
    } catch (e, stackTrace) {
      log.e('Error marking all notifications as read',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e, stackTrace) {
      log.e('Error deleting notification', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete all notifications for a user
  Future<void> deleteAllNotifications(String userId) async {
    try {
      final batch = _firestore.batch();

      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      log.i('Deleted ${snapshot.docs.length} notifications');
    } catch (e, stackTrace) {
      log.e('Error deleting all notifications',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Create a local notification (for testing or local use)
  Future<NotificationModel> createNotification({
    required String userId,
    required String title,
    required String body,
    NotificationType type = NotificationType.general,
    String? imageUrl,
    String? actionRoute,
    Map<String, dynamic>? data,
  }) async {
    try {
      final docRef = await _notificationsCollection.add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (actionRoute != null) 'actionRoute': actionRoute,
        if (data != null) 'data': data,
      });

      final doc = await docRef.get();
      return NotificationModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      log.e('Error creating notification', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }
}
