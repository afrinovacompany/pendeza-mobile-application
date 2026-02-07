import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:pendeza/app/utils/logger.dart';

class SalonSeeder {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> importAllDataToFirestore() async {
    log.i('🚀 Starting ALL data import to Firestore...');

    final user = _auth.currentUser;
    if (user == null) {
      log.e('❌ ERROR: You must be logged in to import data.');
      return;
    }
    // This ID will own ALL data (Salons and Reviews) to pass security rules
    final String currentUserId = user.uid;
    log.i('💡 Importing data as Owner/User ID: $currentUserId');

    int salonSuccessCount = 0;
    int reviewSuccessCount = 0;
    int serviceSuccessCount = 0;
    List<String> importedSalonIds = [];

    // =========================================================================
    // 1. IMPORT SALONS
    // =========================================================================
    try {
      final salonJsonString = await rootBundle.loadString('assets/data/salons_mega.json');
      final List<dynamic> salonsData = json.decode(salonJsonString);

      for (var salonJson in salonsData) {
        try {
          final salonId = salonJson['id'] as String;
          final data = Map<String, dynamic>.from(salonJson);
          data.remove('id');

          // --- 🔐 SECURITY FIX: Claim ownership ---
          data['ownerId'] = currentUserId;

          // --- 📅 DATA FIX: Dates ---
          if (data['createdAt'] is String) {
            data['createdAt'] = Timestamp.fromDate(DateTime.parse(data['createdAt']));
          } else {
            data['createdAt'] = Timestamp.now();
          }

          // --- 🖼️ DATA FIX: Images ---
          if (data.containsKey('coverImage')) {
            data['primaryImage'] = data['coverImage'];
            data.remove('coverImage');
          }
          // Ensure gallery is a list of strings
          if (data['gallery'] != null) {
            final List<dynamic> oldGallery = data['gallery'];
            data['imageGallery'] = oldGallery.map((item) {
              if (item is Map) return item['url'] as String;
              return item.toString();
            }).toList();
            data.remove('gallery');
          }

          // Clean up unused fields
          data.remove('videos');
          data['verificationStatus'] = 'approved'; // Auto-approve for dev

          await _firestore.collection('salons').doc(salonId).set(data, SetOptions(merge: true));
          salonSuccessCount++;
          importedSalonIds.add(salonId);
        } catch (e) {
          log.e('❌ Error importing salon: $e');
        }
      }
    } catch (e) {
      log.e('❌ Fatal error loading salons: $e');
    }

    // =========================================================================
    // 2. IMPORT SERVICES
    // =========================================================================
    try {
      final serviceJsonString = await rootBundle.loadString('assets/data/services_mega.json');
      final List<dynamic> servicesData = json.decode(serviceJsonString);

      for (var serviceJson in servicesData) {
        try {
          final data = Map<String, dynamic>.from(serviceJson);
          final serviceId = data['serviceId'] as String?;

          data['createdAt'] = FieldValue.serverTimestamp();
          data.remove('serviceId');

          if (serviceId != null) {
            await _firestore.collection('services').doc(serviceId).set(data);
            serviceSuccessCount++;
          }
        } catch (e) {
          log.e('❌ Error importing service: $e');
        }
      }
    } catch (e) {
      log.e('❌ Fatal error loading services: $e');
    }

    // =========================================================================
    // 3. IMPORT REVIEWS - 🔥 FIXED: Write to salon sub-collections! 🔥
    // =========================================================================
    try {
      final reviewJsonString = await rootBundle.loadString('assets/data/reviews_mega.json');
      final List<dynamic> reviewsData = json.decode(reviewJsonString);

      for (var reviewJson in reviewsData) {
        try {
          final data = Map<String, dynamic>.from(reviewJson);
          final reviewId = data['reviewId'] as String?;
          final salonId = data['salonId'] as String?;

          // ⚠️ CRITICAL: Skip reviews for salons that don't exist
          if (salonId == null || !importedSalonIds.contains(salonId)) {
            // log.w('⚠️ Skipping review - salon $salonId not found');
            continue;
          }

          // --- 🔐 SECURITY FIX: Claim ownership ---
          data['userId'] = currentUserId;

          // --- 📝 DATA FIX: Map Fields to ReviewModel ---

          // 1. Map 'reviewText' -> 'comment'
          if (data.containsKey('reviewText')) {
            data['comment'] = data['reviewText'];
            data.remove('reviewText');
          }

          // 2. Map 'response' -> 'ownerReply'
          if (data['response'] != null) {
            data['ownerReply'] = data['response'];
            data['ownerUserId'] = currentUserId;
          }
          data.remove('response');

          // 3. Map 'responseDate' -> 'ownerRepliedAt'
          if (data['responseDate'] != null) {
            data['ownerRepliedAt'] = Timestamp.fromDate(DateTime.parse(data['responseDate']));
            data.remove('responseDate');
          }

          // 4. Map 'helpful' -> 'helpfulCount'
          if (data['helpful'] != null) {
            data['helpfulCount'] = data['helpful'];
            data.remove('helpful');
          }

          // 5. Dates & Sorting
          if (data['reviewDate'] is String) {
            final date = DateTime.parse(data['reviewDate']);
            data['createdAt'] = Timestamp.fromDate(date);
            data.remove('reviewDate');
          } else {
            data['createdAt'] = Timestamp.now();
          }

          // Defaults
          data['isVerifiedBooking'] = false;
          data.remove('reviewId');

          // 🔥🔥🔥 THE FIX: Write to salon sub-collection! 🔥🔥🔥
          // Path: salons/{salonId}/reviews/{reviewId}
          final reviewRef = _firestore
              .collection('salons')
              .doc(salonId)
              .collection('reviews');

          if (reviewId != null) {
            await reviewRef.doc(reviewId).set(data);
          } else {
            await reviewRef.add(data);
          }

          reviewSuccessCount++;
          // log.i('✅ Imported Review: ${data['userName']} → Salon: $salonId');
        } catch (e) {
          log.e('❌ Error importing review: $e');
        }
      }
    } catch (e) {
      log.e('❌ Fatal error loading reviews: $e');
    }

    print('\n🎉 SUCCESS! Deployed: $salonSuccessCount salons, $serviceSuccessCount services, $reviewSuccessCount reviews');
    print('📊 Reviews imported to salon sub-collections (salons/{salonId}/reviews)');
  }
}