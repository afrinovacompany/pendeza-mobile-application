import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/services/firestore_service.dart';
import 'package:pendeza/features/0_auth/data/models/user_model.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/promotion_model.dart'; // Import
import 'admin_repository.dart';

class AdminRepositoryImpl implements AdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService;

  AdminRepositoryImpl(this._firestoreService);

  @override
  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();
    return snapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<List<SalonModel>> getAllSalons() async {
    final snapshot = await _db.collection('salons').get();
    return snapshot.docs
        .map((doc) => SalonModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> updateUserRole(String uid, String newRole) {
    return _firestoreService.updateUserRole(uid: uid, role: newRole);
  }

  // --- NEW METHODS ---

  @override
  Future<List<PromotionModel>> getPlatformPromotions() async {
    final snapshot = await _db
        .collection('promotions')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => PromotionModel.fromFirestore(doc))
        .toList();
  }

  @override
  Future<void> addPromotion(PromotionModel promotion) async {
    // We remove ID because Firestore generates it, or we use set if ID is provided
    // Ideally, let Firestore generate ID if it's new
    final docRef = _db.collection('promotions').doc();
    // Create a copy with the new ID
    final newPromo = promotion.copyWith(id: docRef.id);
    await docRef.set(newPromo.toFirestore());
  }

  @override
  Future<void> deletePromotion(String promotionId) async {
    await _db.collection('promotions').doc(promotionId).delete();
  }

  @override
  Future<void> approveSalon(String salonId) async {
    await _db.collection('salons').doc(salonId).update({
      'verificationStatus': 'approved',
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': FieldValue.delete(),
    });
  }

  @override
  Future<void> rejectSalon(String salonId, String reason) async {
    await _db.collection('salons').doc(salonId).update({
      'verificationStatus': 'rejected',
      'reviewedAt': FieldValue.serverTimestamp(),
      'rejectionReason': reason,
    });
  }
}