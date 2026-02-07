import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pendeza/app/utils/logger.dart';
import 'package:pendeza/shared/models/promotion_model.dart';
import '../../domain/repositories/owner_promotions_repository.dart';

class OwnerPromotionsRepositoryImpl implements OwnerPromotionsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<PromotionModel>> getPromotionsStream(String salonId) {
    return _db
        .collection('salons')
        .doc(salonId)
        .collection('promotions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PromotionModel.fromFirestore(doc, salonId: salonId))
          .toList();
    });
  }

  @override
  Future<void> createPromotion({
    required String salonId,
    required PromotionModel promotion,
    required File imageFile,
  }) async {
    try {
      // 1. Upload Image
      final String fileName = 'promo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference storageRef = _storage
          .ref()
          .child('salons')
          .child(salonId)
          .child('promotions')
          .child(fileName);

      final UploadTask uploadTask = storageRef.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Prepare Data
      // Allow Firestore to generate the ID automatically
      final docRef = _db
          .collection('salons')
          .doc(salonId)
          .collection('promotions')
          .doc();

      final newPromotion = promotion.copyWith(
        id: docRef.id,
        imageUrl: downloadUrl,
        salonId: salonId,
        // Ensure critical fields are set correctly for safety
        type: PromotionType.salon,
        createdAt: DateTime.now(),
      );

      // 3. Save to Firestore Subcollection
      await docRef.set(newPromotion.toFirestore());

      log.i('Promotion created successfully: ${docRef.id}');
    } catch (e, s) {
      log.e('Error creating promotion', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deletePromotion({
    required String salonId,
    required String promotionId,
    required String imageUrl,
  }) async {
    try {
      // 1. Delete from Firestore
      await _db
          .collection('salons')
          .doc(salonId)
          .collection('promotions')
          .doc(promotionId)
          .delete();

      // 2. Delete Image from Storage (Cleanup)
      if (imageUrl.isNotEmpty) {
        try {
          final ref = _storage.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          log.w('Could not delete image from storage: $imageUrl');
        }
      }
      log.i('Promotion deleted: $promotionId');
    } catch (e, s) {
      log.e('Error deleting promotion', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> togglePromotionStatus({
    required String salonId,
    required String promotionId,
    required bool isActive,
  }) async {
    try {
      await _db
          .collection('salons')
          .doc(salonId)
          .collection('promotions')
          .doc(promotionId)
          .update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      log.e('Error toggling promotion status', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> boostPromotion({
    required String salonId,
    required String promotionId,
  }) async {
    try {
      final expiryDate = DateTime.now().add(const Duration(days: 7));

      await _db
          .collection('salons')
          .doc(salonId)
          .collection('promotions')
          .doc(promotionId)
          .update({
        'isFeatured': true,
        'featuredUntil': Timestamp.fromDate(expiryDate),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log.i('Promotion boosted: $promotionId until $expiryDate');
    } catch (e, s) {
      log.e('Error boosting promotion', error: e, stackTrace: s);
      rethrow;
    }
  }
}