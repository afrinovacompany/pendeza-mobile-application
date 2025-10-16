import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:pendeza/shared/models/appointment_model.dart';
import '../../features/0_auth/data/models/user_model.dart';
import '../utils/logger.dart';
import '../../shared/models/salon_model.dart';
import '../../shared/models/service_model.dart';
import '../../shared/models/staff_model.dart';



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
  }) async {
    try {
      final token = await getFcmToken();
      final user = UserModel(
        uid: uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
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

  Future<void> updateUserName(
      {required String uid, required String newName}) async {
    try {
      await _db.collection('users').doc(uid).update({
        'fullName': newName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log.i('User name updated for UID: $uid');
    } catch (e, s) {
      log.e('Error updating user name.', error: e, stackTrace: s);
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

  //============================================================================
  // SALON MANAGEMENT
  //============================================================================

  Future<SalonModel> createSalon({
    required String ownerId,
    required String salonName,
    required String address,
    required List<String> serviceCategories,
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

  Future<List<SalonModel>> getSalons() async {
    try {
      final snapshot = await _db.collection('salons').get();
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
      return snapshot.docs
          .map((doc) => ServiceModel.fromFirestore(doc))
          .toList();
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
  // STAFF MANAGEMENT (FIXED)
  //============================================================================

  Future<List<StaffModel>> getStaffForSalon(String salonId) async {
    try {
      final snapshot = await _db
          .collection('staff')
          .where('salonId', isEqualTo: salonId)
          .get();
      return snapshot.docs.map((doc) => StaffModel.fromFirestore(doc)).toList();
    } catch (e, s) {
      log.e('Error fetching staff for salon', error: e, stackTrace: s);
      return [];
    }
  }

  Future<void> addStaff(StaffModel staff) async {
    try {
      final docRef = _db.collection('staff').doc();
      final staffWithId = staff.copyWith(id: docRef.id);
      await docRef.set(staffWithId.toFirestore());
      log.i('Staff added successfully: ${docRef.id}');
    } catch (e, s) {
      log.e('Error adding staff', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> updateStaff(StaffModel staff) async {
    try {
      await _db.collection('staff').doc(staff.id).update({
        'name': staff.name,
        'role': staff.role,
        'serviceIds': staff.serviceIds,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log.i('Staff updated successfully: ${staff.id}');
    } catch (e, s) {
      log.e('Error updating staff', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> deleteStaff(String staffId) async {
    try {
      await _db.collection('staff').doc(staffId).delete();
      log.i('Staff deleted successfully: $staffId');
    } catch (e, s) {
      log.e('Error deleting staff', error: e, stackTrace: s);
      rethrow;
    }
  }


  //============================================================================
  // APPOINTMENT & BOOKING DATA
  //============================================================================

  Future<void> createAppointment(AppointmentModel appointment) async {
    try {
      final docRef = _db.collection('appointments').doc();
      final appointmentWithId = appointment.copyWith(id: docRef.id);
      await docRef.set(appointmentWithId.toFirestore());
      log.i('Appointment created successfully: ${docRef.id}');
    } catch (e, s) {
      log.e('Error creating appointment', error: e, stackTrace: s);
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
}


