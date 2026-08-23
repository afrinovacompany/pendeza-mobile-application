import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import '../../features/0_auth/data/models/user_model.dart';
import '../../features/3_reviews/data/models/review_model.dart';
import '../../shared/models/promotion_model.dart';
import '../utils/logger.dart';
import '../../shared/models/salon_model.dart';
import '../../shared/models/service_model.dart';
// Add this import for the new FavoriteModel
import '../../shared/models/favorite_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<String?> getFcmToken() async {
    try {
      await _fcm.requestPermission();
      final token = await _fcm.getToken();
      log.i('FCM Token retrieved: $token');
      return token;
    } catch (e, s) {
      log.e('Could not get FCM token', error: e, stackTrace: s);
      return null;
    }
  }

  //============================================================================
  // USER MANAGEMENT
  //============================================================================
  Future<void> createUser({
    required String uid,
    required String email,
    required String fullName,
    String? phoneNumber,
    String? profilePictureUrl,
  }) async {
    try {
      final token = await getFcmToken();
      final user = UserModel(
        uid: uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        profilePictureUrl: profilePictureUrl,
        fcmTokens: token != null ? [token] : [],
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(uid).set(user.toFirestore());
      log.i('User document created successfully for UID: $uid');
    } catch (e, s) {
      log.e('Error creating user document.', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<UserModel?> getUserProfile({required String uid}) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e, s) {
      log.e('Error fetching user profile.', error: e, stackTrace: s);
      return null;
    }
  }

  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    try {
      await _db.collection('users').doc(uid).update({
        'role': role,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log.i('User role updated to "$role" for UID: $uid');
    } catch (e, s) {
      log.e('Error updating user role.', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? newName,
    String? profilePictureUrl,
    String? phoneNumber,
    Gender? gender,
  }) async {
    if (newName == null && profilePictureUrl == null && phoneNumber == null && gender == null) {
      log.w('updateUserProfile called with no data to update for UID: $uid');
      return;
    }

    try {
      final dataToUpdate = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (newName != null) {
        dataToUpdate['fullName'] = newName;
      }
      if (profilePictureUrl != null) {
        dataToUpdate['profilePictureUrl'] = profilePictureUrl.isNotEmpty
            ? profilePictureUrl
            : FieldValue.delete();
      }
      if (phoneNumber != null) {
        dataToUpdate['phoneNumber'] = phoneNumber;
      }
      if (gender != null) {
        dataToUpdate['gender'] = gender.value;
      }

      await _db.collection('users').doc(uid).update(dataToUpdate);
      log.i('User profile updated for UID: $uid');
    } catch (e, s) {
      log.e('Error updating user profile.', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Update user profile with all mandatory fields (for client onboarding)
  Future<void> completeClientProfile({
    required String uid,
    required String fullName,
    required String phoneNumber,
    required Gender gender,
    String? profilePictureUrl,
  }) async {
    try {
      final dataToUpdate = <String, dynamic>{
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'gender': gender.value,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (profilePictureUrl != null && profilePictureUrl.isNotEmpty) {
        dataToUpdate['profilePictureUrl'] = profilePictureUrl;
      }

      await _db.collection('users').doc(uid).update(dataToUpdate);
      log.i('Client profile completed for UID: $uid');
    } catch (e, s) {
      log.e('Error completing client profile', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> updateUserFcmToken({required String uid}) async {
    try {
      final newToken = await getFcmToken();
      if (newToken != null) {
        await _db.collection('users').doc(uid).update({
          'fcmTokens': FieldValue.arrayUnion([newToken]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        log.i('Updated FCM token for user $uid');
      }
    } catch (e, s) {
      log.e('Error updating FCM token.', error: e, stackTrace: s);
    }
  }

  Future<UserModel> getUserDetails(String uid) async {
    try {
      log.d('FirestoreService: Fetching user details for UID: $uid');

      final doc = await _db.collection('users').doc(uid).get();

      if (!doc.exists) {
        throw Exception('User not found with UID: $uid');
      }

      final user = UserModel.fromFirestore(doc);
      log.d('FirestoreService: User details fetched successfully for ${user.fullName}');

      return user;
    } catch (e, s) {
      log.e('FirestoreService: Error fetching user details for UID: $uid',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // SALON MANAGEMENT
  //============================================================================
  Future<SalonModel> createSalon({
    required String ownerId,
    required String salonName,
    required String address,
    required List<String> serviceCategories,
    String openingTime = '08:00',
    String closingTime = '20:00',
    // NEW: Optional fields for Phase 2
    List<String>? businessTypeIds,
    List<String>? businessTypeNames,
    String? region,
    String? district,
  }) async {
    try {
      final newSalonRef = _db.collection('salons').doc();
      final newSalon = SalonModel(
        id: newSalonRef.id,
        ownerId: ownerId,
        salonName: salonName,
        address: address,
        serviceCategories: serviceCategories,
        createdAt: DateTime.now(),
        openingTime: openingTime,
        closingTime: closingTime,
        // NEW: Pass Phase 2 fields
        businessTypeIds: businessTypeIds ?? [],
        businessTypeNames: businessTypeNames ?? [],
        region: region,
        district: district,
        // Default verification status
        verificationStatus: 'pending',
        submittedAt: DateTime.now(),
      );

      await newSalonRef.set(newSalon.toFirestore());
      log.i('Salon document created with ID: ${newSalon.id}');
      return newSalon;
    } catch (e, s) {
      log.e('Error creating salon document.', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<SalonModel?> getSalonForOwner({required String ownerId}) async {
    try {
      final querySnapshot = await _db
          .collection('salons')
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        log.i('Found salon for owner: $ownerId');
        return SalonModel.fromFirestore(querySnapshot.docs.first);
      }

      log.i('No salon found for owner: $ownerId');
      return null;
    } catch (e, s) {
      log.e('Error fetching salon for owner.', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 🔥 NEW: Get just the salon ID for an owner (optimized helper)
  /// This is more efficient than fetching the entire salon object when you only need the ID
  Future<String> getSalonIdForOwner({required String ownerId}) async {
    try {
      log.d('FirestoreService: Fetching salon ID for owner: $ownerId');

      final querySnapshot = await _db
          .collection('salons')
          .where('ownerId', isEqualTo: ownerId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        log.w('No salon found for owner: $ownerId');
        throw Exception(
            'No salon found for this owner. Please create a salon first.');
      }

      final salonId = querySnapshot.docs.first.id;
      log.i('Found salon ID: $salonId for owner: $ownerId');

      return salonId;
    } catch (e, s) {
      log.e('Error fetching salon ID for owner', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get salon by ID (for owner verification in reviews)
  Future<SalonModel?> getSalonById(String salonId) async {
    try {
      final doc = await _db.collection('salons').doc(salonId).get();
      if (!doc.exists) return null;
      return SalonModel.fromFirestore(doc);
    } catch (e, s) {
      log.e('Error fetching salon by ID', error: e, stackTrace: s);
      return null;
    }
  }

  Future<List<SalonModel>> getSalons() async {
    try {
      final snapshot = await _db
          .collection('salons')
          .where('verificationStatus', isEqualTo: 'approved')
          .get();
      return snapshot.docs
          .map((doc) => SalonModel.fromFirestore(doc))
          .toList();
    } catch (e, s) {
      log.e('Error fetching salons', error: e, stackTrace: s);
      return [];
    }
  }

  Future<SalonModel> getSalonDetails(String salonId) async {
    try {
      final doc = await _db.collection('salons').doc(salonId).get();
      if (!doc.exists) throw Exception('Salon not found');
      return SalonModel.fromFirestore(doc);
    } catch (e, s) {
      log.e('Error fetching salon details', error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // SERVICE MANAGEMENT
  //============================================================================
  Future<List<ServiceModel>> getServicesForSalon(String salonId) async {
    try {
      final snapshot = await _db
          .collection('services')
          .where('salonId', isEqualTo: salonId)
          .get();
      final services = <ServiceModel>[];
      for (final doc in snapshot.docs) {
        try {
          services.add(ServiceModel.fromFirestore(doc));
        } catch (e) {
          log.w('Skipping unreadable service ${doc.id}: $e');
        }
      }
      return services;
    } catch (e, s) {
      log.e('Error fetching services for salon', error: e, stackTrace: s);
      return [];
    }
  }

  Future<ServiceModel> getServiceDetails(String serviceId) async {
    try {
      final doc = await _db.collection('services').doc(serviceId).get();
      if (!doc.exists) throw Exception('Service not found');
      return ServiceModel.fromFirestore(doc);
    } catch (e, s) {
      log.e('Error fetching service details', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> addService(ServiceModel service) async {
    try {
      final docRef = _db.collection('services').doc();
      final serviceWithId = service.copyWith(id: docRef.id);
      await docRef.set(serviceWithId.toFirestore());
      log.i('Service added successfully: ${docRef.id}');
    } catch (e, s) {
      log.e('Error adding service', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> updateService(ServiceModel service) async {
    try {
      await _db.collection('services').doc(service.id).update({
        'name': service.name,
        'description': service.description,
        'price': service.price,
        'durationMinutes': service.durationMinutes,
        'category': service.category,
        'isActive': service.isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log.i('Service updated successfully: ${service.id}');
    } catch (e, s) {
      log.e('Error updating service', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> deleteService(String serviceId) async {
    try {
      await _db.collection('services').doc(serviceId).delete();
      log.i('Service deleted successfully: $serviceId');
    } catch (e, s) {
      log.e('Error deleting service', error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // APPOINTMENT & BOOKING DATA
  //============================================================================

  // CHANGE: Return Future<String> instead of Future<void>
  Future<String> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = _db.collection('appointments').doc();
      final appointmentWithId = appointment.copyWith(id: docRef.id);
      await docRef.set(appointmentWithId.toFirestore());
      log.i('Appointment created successfully: ${docRef.id}');
      return docRef.id; // RETURN THE ID
    } catch (e, s) {
      log.e('Error creating appointment', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      log.i('FirestoreService: Updating appointment $appointmentId status to $newStatus');

      await _db.collection('appointments').doc(appointmentId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      log.i('FirestoreService: Appointment status updated successfully');
    } catch (e, s) {
      log.e('FirestoreService: Error updating appointment status',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<List<AppointmentModel>> getAppointmentsForClient(
      String clientId) async {
    try {
      final snapshot = await _db
          .collection('appointments')
          .where('clientId', isEqualTo: clientId)
          .orderBy('startTime', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, s) {
      log.e('Error fetching appointments for client', error: e, stackTrace: s);
      return [];
    }
  }

  Future<List<AppointmentModel>> getAppointmentsForSalonOnDate(
      String salonId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

      final snapshot = await _db
          .collection('appointments')
          .where('salonId', isEqualTo: salonId)
          .where('startTime',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('startTime',
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', isNotEqualTo: 'Cancelled')
          .get();

      return snapshot.docs
          .map((doc) => AppointmentModel.fromFirestore(doc))
          .toList();
    } catch (e, s) {
      log.e('Error fetching salon appointments for date',
          error: e, stackTrace: s);
      return [];
    }
  }

  //============================================================================
  // REVIEWS MANAGEMENT (Enhanced)
  //============================================================================

  /// Create a new review in the salon's sub-collection
  Future<ReviewModel> createReview(ReviewModel review) async {
    try {
      // Use sub-collection: salons/{salonId}/reviews
      final docRef = await _db
          .collection('salons')
          .doc(review.salonId)
          .collection('reviews')
          .add(review.toFirestore());

      final doc = await docRef.get();
      return ReviewModel.fromFirestore(doc);
    } catch (e, s) {
      log.e('Error creating review', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Update an existing review
  Future<void> updateReview({
    required String reviewId,
    required String userId,
    required double rating,
    required String comment,
  }) async {
    try {
      // Since reviews are in sub-collections, we use collectionGroup to find it first
      // This ensures we find it regardless of which salon it belongs to
      final reviewRef = await _db
          .collectionGroup('reviews')
          .where(FieldPath.documentId, isEqualTo: reviewId)
          .get();

      if (reviewRef.docs.isEmpty) {
        throw Exception('Review not found');
      }

      final reviewDoc = reviewRef.docs.first;
      final reviewData = reviewDoc.data();

      // Security check: ensure user owns this review
      if (reviewData['userId'] != userId) {
        throw Exception('You can only update your own reviews');
      }

      await reviewDoc.reference.update({
        'rating': rating,
        'comment': comment,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      log.e('Error updating review', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Delete a review
  Future<void> deleteReview({
    required String reviewId,
    required String userId,
  }) async {
    try {
      final reviewRef = await _db
          .collectionGroup('reviews')
          .where(FieldPath.documentId, isEqualTo: reviewId)
          .get();

      if (reviewRef.docs.isEmpty) {
        throw Exception('Review not found');
      }

      final reviewDoc = reviewRef.docs.first;
      final reviewData = reviewDoc.data();

      if (reviewData['userId'] != userId) {
        throw Exception('You can only delete your own reviews');
      }

      await reviewDoc.reference.delete();
    } catch (e, s) {
      log.e('Error deleting review', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Get reviews for a salon with sorting and limits
  Future<List<ReviewModel>> getReviewsForSalon({
    required String salonId,
    String sortBy = 'recent',
    int? limit,
  }) async {
    try {
      Query query = _db
          .collection('salons')
          .doc(salonId)
          .collection('reviews');

      // Apply sorting
      switch (sortBy) {
        case 'recent':
          query = query.orderBy('createdAt', descending: true);
          break;
        case 'highest':
          query = query.orderBy('rating', descending: true);
          break;
        case 'lowest':
          query = query.orderBy('rating', descending: false);
          break;
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e, s) {
      log.e('Error fetching reviews for salon', error: e, stackTrace: s);
      return [];
    }
  }

  /// Get a user's specific review for a salon (to check for duplicates)
  Future<ReviewModel?> getUserReviewForSalon({
    required String salonId,
    required String userId,
  }) async {
    try {
      final snapshot = await _db
          .collection('salons')
          .doc(salonId)
          .collection('reviews')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return ReviewModel.fromFirestore(snapshot.docs.first);
    } catch (e, s) {
      log.e('Error fetching user review', error: e, stackTrace: s);
      return null;
    }
  }

  /// Check if user has completed booking at salon (Verification Logic)
  Future<String?> getCompletedAppointmentIdForReview({
    required String salonId,
    required String userId,
  }) async {
    try {
      final snapshot = await _db
          .collection('appointments')
      // FIXED: Changed clientId to userId to match the method parameter
          .where('clientId', isEqualTo: userId)
          .where('salonId', isEqualTo: salonId)
          .where('status', isEqualTo: 'Completed')
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      return snapshot.docs.first.id;
    } catch (e, s) {
      log.e('Error checking completed appointments', error: e, stackTrace: s);
      return null;
    }
  }

  /// Add owner reply to review
  Future<void> addOwnerReplyToReview({
    required String reviewId,
    required String ownerId,
    required String replyText,
  }) async {
    try {
      final reviewRef = await _db
          .collectionGroup('reviews')
          .where(FieldPath.documentId, isEqualTo: reviewId)
          .get();

      if (reviewRef.docs.isEmpty) {
        throw Exception('Review not found');
      }

      await reviewRef.docs.first.reference.update({
        'ownerReply': replyText,
        'ownerRepliedAt': FieldValue.serverTimestamp(),
        'ownerUserId': ownerId,
      });
    } catch (e, s) {
      log.e('Error adding owner reply', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Delete owner reply
  Future<void> deleteOwnerReply({
    required String reviewId,
    required String ownerId,
  }) async {
    try {
      final reviewRef = await _db
          .collectionGroup('reviews')
          .where(FieldPath.documentId, isEqualTo: reviewId)
          .get();

      if (reviewRef.docs.isEmpty) {
        throw Exception('Review not found');
      }

      final reviewDoc = reviewRef.docs.first;
      final reviewData = reviewDoc.data();

      if (reviewData['ownerUserId'] != ownerId) {
        throw Exception('You can only delete your own replies');
      }

      await reviewDoc.reference.update({
        'ownerReply': FieldValue.delete(),
        'ownerRepliedAt': FieldValue.delete(),
        'ownerUserId': FieldValue.delete(),
      });
    } catch (e, s) {
      log.e('Error deleting owner reply', error: e, stackTrace: s);
      rethrow;
    }
  }

  /// Increment helpful count
  Future<void> incrementReviewHelpfulCount({required String reviewId}) async {
    try {
      final reviewRef = await _db
          .collectionGroup('reviews')
          .where(FieldPath.documentId, isEqualTo: reviewId)
          .get();

      if (reviewRef.docs.isNotEmpty) {
        await reviewRef.docs.first.reference.update({
          'helpfulCount': FieldValue.increment(1),
        });
      }
    } catch (e, s) {
      log.e('Error incrementing helpful count', error: e, stackTrace: s);
    }
  }

  /// Watch reviews (real-time)
  Stream<List<ReviewModel>> watchReviewsForSalon({
    required String salonId,
    String sortBy = 'recent',
  }) {
    Query query = _db
        .collection('salons')
        .doc(salonId)
        .collection('reviews');

    switch (sortBy) {
      case 'recent':
        query = query.orderBy('createdAt', descending: true);
        break;
      case 'highest':
        query = query.orderBy('rating', descending: true);
        break;
      case 'lowest':
        query = query.orderBy('rating', descending: false);
        break;
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ReviewModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    });
  }

  /// Calculate average rating (Helper for aggregations)
  Future<double> getAverageRatingForSalon(String salonId) async {
    try {
      // Re-using the new getReviewsForSalon
      final reviews = await getReviewsForSalon(salonId: salonId);
      if (reviews.isEmpty) return 0.0;

      final totalRating = reviews.fold<double>(
        0.0,
            (sum, review) => sum + review.rating,
      );
      return totalRating / reviews.length;
    } catch (e, s) {
      log.e('Error calculating average rating', error: e, stackTrace: s);
      return 0.0;
    }
  }

  /// Basic add review (Legacy compatibility - redirects to new logic if used)
  Future<void> addReview(ReviewModel review) async {
    await createReview(review);
  }

  //============================================================================
  // PROMOTIONS MANAGEMENT
  //============================================================================
  Future<List<PromotionModel>> getActivePromotions() async {
    try {
      final snapshot = await _db
          .collection('promotions')
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      return snapshot.docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .where((promo) => promo.isValid)
          .toList();
    } catch (e, s) {
      log.e('Error fetching active promotions', error: e, stackTrace: s);
      return [];
    }
  }

  Future<void> addPromotion(PromotionModel promotion) async {
    try {
      final docRef = _db.collection('promotions').doc();
      final promotionWithId = promotion.copyWith(id: docRef.id);
      await docRef.set(promotionWithId.toFirestore());
      log.i('Promotion added successfully: ${docRef.id}');
    } catch (e, s) {
      log.e('Error adding promotion', error: e, stackTrace: s);
      rethrow;
    }
  }

  //============================================================================
  // FAVORITES MANAGEMENT (Phase 1)
  //============================================================================

  // Add favorite
  Future<void> addFavoriteSalon({
    required String userId,
    required String salonId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(salonId)
        .set({
      'salonId': salonId,
      'userId': userId,
      'favoritedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove favorite
  Future<void> removeFavoriteSalon({
    required String userId,
    required String salonId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(salonId)
        .delete();
  }

  // Check if favorited
  Future<bool> isSalonFavorited({
    required String userId,
    required String salonId,
  }) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc(salonId)
        .get();
    return doc.exists;
  }

  // Get favorite IDs
  Future<List<String>> getFavoriteSalonIds({
    required String userId,
  }) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();
    return snapshot.docs.map((doc) => doc.id).toList();
  }

  // Get salons by IDs (only returns approved salons)
  Future<List<SalonModel>> getSalonsByIds(List<String> salonIds) async {
    if (salonIds.isEmpty) return [];

    final salons = <SalonModel>[];
    for (final id in salonIds) {
      final doc = await _db.collection('salons').doc(id).get();
      if (doc.exists) {
        final salon = SalonModel.fromFirestore(doc);
        if (salon.isApproved) {
          salons.add(salon);
        }
      }
    }
    return salons;
  }

  // Watch favorites (real-time)
  Stream<List<String>> watchFavoriteSalonIds({
    required String userId,
  }) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Get favorite models with metadata
  Future<List<FavoriteModel>> getFavoriteModels({
    required String userId,
  }) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .orderBy('favoritedAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FavoriteModel.fromFirestore(doc))
        .toList();
  }

  // Clear all favorites
  Future<void> clearAllFavorites({required String userId}) async {
    final batch = _db.batch();
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}