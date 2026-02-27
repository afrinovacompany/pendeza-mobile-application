import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/shared/models/notification_model.dart';
import 'package:pendeza/app/utils/logger.dart';

/// Repository for managing user notifications
///
/// Merges two sources:
/// - `notifications` collection: personal notifications (bookings, payments, etc.)
/// - `notification_inbox` collection: admin broadcast notifications (promotions, announcements)
///
/// Broadcast read-tracking uses a subcollection:
///   notification_inbox/{docId}/readBy/{userId} → { readAt: timestamp }
class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Personal notifications collection
  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection('notifications');

  /// Broadcast notifications collection
  CollectionReference<Map<String, dynamic>> get _inboxCollection =>
      _firestore.collection('notification_inbox');

  // =========================================================================
  // GET NOTIFICATIONS (merged)
  // =========================================================================

  /// Get all notifications for a user (personal + broadcasts merged)
  Future<List<NotificationModel>> getNotifications(
      String userId, {
        String? userRole,
      }) async {
    try {
      // 1. Fetch personal notifications
      final personalFuture = _notificationsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      // 2. Fetch broadcast notifications (last 30 days to keep it manageable)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final broadcastFuture = _inboxCollection
          .where('sentAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('sentAt', descending: true)
          .limit(30)
          .get();

      // Run both queries in parallel
      final results = await Future.wait([personalFuture, broadcastFuture]);
      final personalSnap = results[0];
      final broadcastSnap = results[1];

      // 3. Get read status for broadcast notifications
      final readBroadcastIds = await _getReadBroadcastIds(userId);

      // 4. Build personal notifications
      final personalNotifications = personalSnap.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();

      // 5. Build broadcast notifications with read status
      final broadcastNotifications = broadcastSnap.docs
          .where((doc) {
        // Filter by audience: show if target is 'all' or matches user role
        final target = doc.data()['targetAudience'] as String? ?? 'all';
        if (target == 'all') return true;
        if (userRole == null) return true; // Show all if role unknown
        if (target == 'clients' && userRole == 'client') return true;
        if (target == 'owners' && userRole == 'owner') return true;
        return false;
      })
          .map((doc) => NotificationModel.fromBroadcast(
        doc,
        currentUserId: userId,
        isRead: readBroadcastIds.contains(doc.id),
      ))
          .toList();

      // 6. Merge and sort by date (newest first)
      final allNotifications = [
        ...personalNotifications,
        ...broadcastNotifications,
      ];
      allNotifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Limit to 80 total
      if (allNotifications.length > 80) {
        return allNotifications.sublist(0, 80);
      }

      return allNotifications;
    } catch (e, stackTrace) {
      log.e('Error fetching merged notifications',
          error: e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Stream notifications for real-time updates (personal only for simplicity)
  /// Broadcasts are fetched on load/refresh since they change rarely
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

  // =========================================================================
  // UNREAD COUNT (merged)
  // =========================================================================

  /// Get unread notification count (personal + unread broadcasts)
  Future<int> getUnreadCount(String userId, {String? userRole}) async {
    try {
      // Personal unread count
      final personalSnap = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
      final personalCount = personalSnap.count ?? 0;

      // Broadcast unread count
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final broadcastSnap = await _inboxCollection
          .where('sentAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .orderBy('sentAt', descending: true)
          .limit(30)
          .get();

      final readBroadcastIds = await _getReadBroadcastIds(userId);

      int broadcastUnread = 0;
      for (final doc in broadcastSnap.docs) {
        final target = doc.data()['targetAudience'] as String? ?? 'all';
        final isRelevant = target == 'all' ||
            (userRole == 'client' && target == 'clients') ||
            (userRole == 'owner' && target == 'owners') ||
            userRole == null;

        if (isRelevant && !readBroadcastIds.contains(doc.id)) {
          broadcastUnread++;
        }
      }

      return personalCount + broadcastUnread;
    } catch (e, stackTrace) {
      log.e('Error getting merged unread count',
          error: e, stackTrace: stackTrace);
      return 0;
    }
  }

  /// Stream unread notification count for real-time badge (personal only)
  Stream<int> streamUnreadCount(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // =========================================================================
  // MARK AS READ
  // =========================================================================

  /// Mark a notification as read (handles both personal and broadcast)
  Future<void> markAsRead(String notificationId) async {
    try {
      if (notificationId.startsWith('broadcast_')) {
        // This is a broadcast notification — handled separately
        // The caller should use markBroadcastAsRead instead
        return;
      }

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

  /// Mark a broadcast notification as read for a specific user
  Future<void> markBroadcastAsRead(String broadcastDocId, String userId) async {
    try {
      await _inboxCollection
          .doc(broadcastDocId)
          .collection('readBy')
          .doc(userId)
          .set({
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      log.e('Error marking broadcast as read',
          error: e, stackTrace: stackTrace);
      // Don't rethrow — failing to track read status shouldn't break the app
    }
  }

  /// Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    try {
      // 1. Mark all personal notifications as read
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
      log.i('Marked ${snapshot.docs.length} personal notifications as read');

      // 2. Mark all recent broadcasts as read
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      final broadcastSnap = await _inboxCollection
          .where('sentAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      final readBatch = _firestore.batch();
      for (final doc in broadcastSnap.docs) {
        readBatch.set(
          doc.reference.collection('readBy').doc(userId),
          {'readAt': FieldValue.serverTimestamp()},
        );
      }
      await readBatch.commit();
      log.i('Marked ${broadcastSnap.docs.length} broadcasts as read');
    } catch (e, stackTrace) {
      log.e('Error marking all notifications as read',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // =========================================================================
  // DELETE
  // =========================================================================

  /// Delete a notification (personal only — broadcasts can't be deleted)
  Future<void> deleteNotification(String notificationId) async {
    try {
      if (notificationId.startsWith('broadcast_')) {
        // Can't delete shared broadcast — just mark as read/dismissed
        return;
      }
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e, stackTrace) {
      log.e('Error deleting notification', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete all personal notifications for a user
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
      log.i('Deleted ${snapshot.docs.length} personal notifications');
    } catch (e, stackTrace) {
      log.e('Error deleting all notifications',
          error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

  // =========================================================================
  // CREATE (personal)
  // =========================================================================

  /// Create a personal notification
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

  // =========================================================================
  // HELPERS (private)
  // =========================================================================

  /// Get IDs of broadcast notifications the user has already read
  Future<Set<String>> _getReadBroadcastIds(String userId) async {
    try {
      // Query all readBy subcollections for this user using collectionGroup
      final readSnap = await _firestore
          .collectionGroup('readBy')
          .where(FieldPath.documentId, isEqualTo: userId)
          .get();

      // Extract parent document IDs
      final readIds = <String>{};
      for (final doc in readSnap.docs) {
        // Path: notification_inbox/{broadcastId}/readBy/{userId}
        final parentRef = doc.reference.parent.parent;
        if (parentRef != null) {
          readIds.add(parentRef.id);
        }
      }

      return readIds;
    } catch (e) {
      log.e('Error getting read broadcast IDs: $e');
      return {};
    }
  }
}