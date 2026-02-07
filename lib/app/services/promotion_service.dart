import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pendeza/app/utils/logger.dart';
import '../../shared/models/promotion_model.dart';

/// Service to handle fetching and managing the 3-Tier Promotions.
///
/// Tiers:
/// 1. Platform-wide promotions (Admin controlled)
/// 2. Salon-specific promotions (Owner controlled)
/// 3. Featured/Paid promotions (Priority display)
class PromotionsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fetch all active Platform Promotions.
  /// These are global promos created by Pendeza admins (e.g., "Black Friday").
  Future<List<PromotionModel>> getPlatformPromotions() async {
    try {
      final now = Timestamp.now();

      final snapshot = await _db.collection('promotions')
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: now)
          .orderBy('endDate') // Required for inequality filter
          .get();

      final promotions = snapshot.docs
          .map((doc) => PromotionModel.fromFirestore(doc))
          .toList();

      // Sort by priority (High to Low)
      promotions.sort((a, b) => b.priority.compareTo(a.priority));

      return promotions;
    } catch (e, s) {
      log.e('Error fetching platform promotions', error: e, stackTrace: s);
      return [];
    }
  }

  /// Fetch active promotions for a specific salon.
  /// Used on the Salon Detail page.
  Future<List<PromotionModel>> getSalonPromotions(String salonId) async {
    try {
      final now = Timestamp.now();

      final snapshot = await _db
          .collection('salons')
          .doc(salonId)
          .collection('promotions')
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: now)
          .get();

      return snapshot.docs
          .map((doc) => PromotionModel.fromFirestore(doc, salonId: salonId))
          .toList();
    } catch (e, s) {
      log.e('Error fetching salon promotions for $salonId', error: e, stackTrace: s);
      return [];
    }
  }

  /// Fetch ALL active promotions for the Main Dashboard Carousel.
  ///
  /// Strategy:
  /// 1. Fetch Platform promos (Always show)
  /// 2. Fetch "Featured" salon promos (Paid tier only) using collectionGroup
  /// 3. Combine and sort
  Future<List<PromotionModel>> getDashboardPromotions() async {
    try {
      // 1. Get Platform Promos
      final platformPromos = await getPlatformPromotions();

      // 2. Get Featured Salon Promos (Collection Group Query)
      // This searches ALL 'promotions' subcollections across ALL salons
      final now = Timestamp.now();

      final featuredSnapshot = await _db.collectionGroup('promotions')
          .where('isFeatured', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .where('endDate', isGreaterThan: now)
          .limit(10) // Limit to keep dashboard performance high
          .get();

      final featuredSalonPromos = featuredSnapshot.docs.map((doc) {
        // Try to get salonId from parent path
        final parentPath = doc.reference.parent.parent?.id;
        return PromotionModel.fromFirestore(doc, salonId: parentPath);
      }).toList();

      // 3. Combine lists
      final allPromos = [...platformPromos, ...featuredSalonPromos];

      // 4. Sort Logic:
      // - Platform High Priority (>0)
      // - Featured Salon Promos
      // - Platform Standard Priority (0)
      allPromos.sort((a, b) {
        if (a.isPlatformPromo && a.priority > 0 && !b.isPlatformPromo) return -1;
        if (b.isPlatformPromo && b.priority > 0 && !a.isPlatformPromo) return 1;

        // Default sort by priority field
        return b.priority.compareTo(a.priority);
      });

      return allPromos;
    } catch (e, s) {
      log.e('Error fetching dashboard promotions', error: e, stackTrace: s);
      // Fallback: return empty list so UI doesn't crash
      return [];
    }
  }
}