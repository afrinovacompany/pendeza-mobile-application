// /// Temporary dummy data for testing the UI before connecting to Firebase.
// ///
// /// This file contains hardcoded promotions, categories, and sample data
// /// to help us build and test the client dashboard quickly.
//
// import '../models/promotion_model.dart';
//
// /// A list of hardcoded promotions for the carousel slider.
// ///
// /// In production, these will come from Firestore via getActivePromotions().
// /// For now, we use these to test the carousel UI.
// class DummyData {
//
//   /// Sample promotions for the carousel
//   static List<PromotionModel> get samplePromotions => [
//     PromotionModel(
//       id: 'promo1',
//       imageUrl: 'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800&q=80',
//       title: '50% Off First Booking',
//       description: 'New customers get 50% off their first service. Use code: FIRST50',
//       promoCode: 'FIRST50',
//       targetRoute: null, // Navigate to discovery when tapped
//       isActive: true,
//       startDate: DateTime.now().subtract(const Duration(days: 7)),
//       endDate: DateTime.now().add(const Duration(days: 30)),
//       displayOrder: 1,
//     ),
//     PromotionModel(
//       id: 'promo2',
//       imageUrl: 'https://images.unsplash.com/photo-1582095133179-bfd08e2fc6b3?w=800&q=80',
//       title: 'Summer Glow Package',
//       description: 'Facial + Manicure + Pedicure for only 45,000 TZS',
//       targetRoute: '/discover?category=spa',
//       isActive: true,
//       startDate: DateTime.now().subtract(const Duration(days: 3)),
//       endDate: DateTime.now().add(const Duration(days: 60)),
//       displayOrder: 2,
//     ),
//     PromotionModel(
//       id: 'promo3',
//       imageUrl: 'https://images.unsplash.com/photo-1633681926022-84c23e8cb2d6?w=800&q=80',
//       title: 'Gentleman\'s Fresh Cut',
//       description: 'Premium haircut + beard grooming - Book your slot today!',
//       targetRoute: '/discover?category=barbershop',
//       isActive: true,
//       startDate: DateTime.now().subtract(const Duration(days: 1)),
//       endDate: DateTime.now().add(const Duration(days: 45)),
//       displayOrder: 3,
//     ),
//     PromotionModel(
//       id: 'promo4',
//       imageUrl: 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=800&q=80',
//       title: 'Weekend Special',
//       description: 'Get 20% off on all services every Saturday & Sunday',
//       promoCode: 'WEEKEND20',
//       isActive: true,
//       startDate: DateTime.now().subtract(const Duration(days: 14)),
//       endDate: DateTime.now().add(const Duration(days: 90)),
//       displayOrder: 4,
//     ),
//   ];
//
//   /// Service categories for the Browse section
//   ///
//   /// These match the serviceCategories field in SalonModel.
//   /// Each category has a display name, icon, and identifier.
//   static List<ServiceCategory> get categories => [
//     ServiceCategory(
//       id: 'hair',
//       name: 'Hair Salon',
//       emoji: '💇',
//       color: 0xFF6C5CE7, // Primary purple
//     ),
//     ServiceCategory(
//       id: 'nails',
//       name: 'Nails',
//       emoji: '💅',
//       color: 0xFFFAB1A0, // Accent coral
//     ),
//     ServiceCategory(
//       id: 'spa',
//       name: 'Spa & Massage',
//       emoji: '💆',
//       color: 0xFF74B9FF, // Accent blue
//     ),
//     ServiceCategory(
//       id: 'barbershop',
//       name: 'Barbershop',
//       emoji: '✂️',
//       color: 0xFF00B894, // Success green
//     ),
//     ServiceCategory(
//       id: 'makeup',
//       name: 'Makeup',
//       emoji: '💄',
//       color: 0xFFFF6B6B, // Error red (soft)
//     ),
//     ServiceCategory(
//       id: 'facial',
//       name: 'Facial',
//       emoji: '🧖',
//       color: 0xFFFDCB6E, // Warning yellow
//     ),
//     ServiceCategory(
//       id: 'waxing',
//       name: 'Waxing',
//       emoji: '✨',
//       color: 0xFFA29BFE, // Primary light
//     ),
//     ServiceCategory(
//       id: 'other',
//       name: 'Other',
//       emoji: '🌟',
//       color: 0xFF636E72, // Text secondary
//     ),
//   ];
//
//   /// Get a category by its ID
//   static ServiceCategory? getCategoryById(String id) {
//     try {
//       return categories.firstWhere((cat) => cat.id == id);
//     } catch (e) {
//       return null;
//     }
//   }
//
//   /// Get a category emoji by ID (fallback to default)
//   static String getCategoryEmoji(String categoryId) {
//     final category = getCategoryById(categoryId);
//     return category?.emoji ?? '🌟';
//   }
//
//   /// Get a category color by ID (fallback to primary color)
//   static int getCategoryColor(String categoryId) {
//     final category = getCategoryById(categoryId);
//     return category?.color ?? 0xFF6C5CE7;
//   }
// }
//
// /// A simple category model for the Browse section
// class ServiceCategory {
//   final String id;
//   final String name;
//   final String emoji;
//   final int color; // Color as hex int
//
//   ServiceCategory({
//     required this.id,
//     required this.name,
//     required this.emoji,
//     required this.color,
//   });
// }