import 'package:pendeza/shared/models/category_model.dart';

/// Static data for the Pendeza categories (Fresha Style).
///
/// IDs have been updated to match the data in salons_mega.json
/// where possible, or general keywords for smart matching.
class CategoriesData {
  static List<CategoryModel> get allCategories => [
    _create(
      id: 'hair', // Matches "hair" in salon_002, salon_003, salon_005
      name: 'Hair & styling',
      assetName: 'hair_styling.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'nails', // Matches "nails" in salon_001
      name: 'Nails',
      assetName: 'nails.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'massage', // Matches "Massage Therapy" via smart partial matching
      name: 'Massage',
      assetName: 'massage.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'barbershop', // Matches "barbershop" in salon_002, salon_004
      name: 'Barbering',
      assetName: 'barbering.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'spa', // Matches "spa" and "Spa"
      name: 'Spa',
      assetName: 'spa.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'makeup', // Matches "makeup" in salon_001, salon_003
      name: 'Makeup',
      assetName: 'makeup.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'facials', // Will match "facial" or "skincare"
      name: 'Facials & skincare',
      assetName: 'facials_skincare.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'lashes', // Will match "eyebrows" or "lashes"
      name: 'Eyebrows & eyelashes',
      assetName: 'eyebrows_lashes.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'waxing', // Will match "waxing" or "hair removal"
      name: 'Hair removal',
      assetName: 'hair_removal.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'body', // Will match "body" or "scrub" (salon_004 has "scrub")
      name: 'Body',
      assetName: 'body.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'henna',
      name: 'Henna & Mehndi',
      assetName: 'henna.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'braids',
      name: 'Braids & Locs',
      assetName: 'braids.png',
      color: 0xFFF5F5F5,
    ),
    _create(
      id: 'men', // Will match "men" or "grooming"
      name: 'Men\'s Grooming',
      assetName: 'men_grooming.png',
      color: 0xFFF5F5F5,
    ),
  ];

  static CategoryModel _create({
    required String id,
    required String name,
    required String assetName,
    required int color,
  }) {
    return CategoryModel(
      id: id,
      name: name,
      // Using local assets now
      iconUrl: 'assets/images/categories/$assetName',
      color: color,
      targetGender: 'all',
    );
  }
}