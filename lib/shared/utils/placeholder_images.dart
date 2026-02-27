/// Free placeholder images for when salon/category images are unavailable.
///
/// Uses Unsplash CDN (free, no auth required, no attribution needed in apps).
/// Each URL is a curated beauty/salon themed photo.
class PlaceholderImages {
  PlaceholderImages._();

  // =========================================================================
  // SALON PLACEHOLDER IMAGES
  // =========================================================================
  // Curated set of beauty/salon images from Unsplash for salons without photos.
  // Rotated by salon ID hash for variety.

  static const List<String> _salonImages = [
    // Salon interior
    'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=400&h=300&fit=crop',
    // Barber tools
    'https://images.unsplash.com/photo-1585747860019-8a54e6c0acc5?w=400&h=300&fit=crop',
    // Hair styling
    'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=400&h=300&fit=crop',
    // Salon chairs
    'https://images.unsplash.com/photo-1633681926022-84c23e8cb2d6?w=400&h=300&fit=crop',
    // Beauty products
    'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=400&h=300&fit=crop',
    // Nail art
    'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=400&h=300&fit=crop',
    // Makeup brushes
    'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=400&h=300&fit=crop',
    // Spa setting
    'https://images.unsplash.com/photo-1540555700478-4be289fbec6a?w=400&h=300&fit=crop',
  ];

  /// Get a deterministic salon placeholder URL based on salon ID.
  /// Same salon always gets the same image for consistency.
  static String forSalon(String salonId) {
    final hash = salonId.hashCode.abs();
    return _salonImages[hash % _salonImages.length];
  }

  // =========================================================================
  // CATEGORY FALLBACK IMAGES
  // =========================================================================
  // Used when local category asset is missing or fails to load.

  static const Map<String, String> _categoryImages = {
    'hair': 'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=300&h=400&fit=crop',
    'nails': 'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=300&h=400&fit=crop',
    'massage': 'https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=300&h=400&fit=crop',
    'barbershop': 'https://images.unsplash.com/photo-1585747860019-8a54e6c0acc5?w=300&h=400&fit=crop',
    'spa': 'https://images.unsplash.com/photo-1540555700478-4be289fbec6a?w=300&h=400&fit=crop',
    'makeup': 'https://images.unsplash.com/photo-1596462502278-27bfdc403348?w=300&h=400&fit=crop',
    'facials': 'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=300&h=400&fit=crop',
    'lashes': 'https://images.unsplash.com/photo-1583001931096-959e9a1a6223?w=300&h=400&fit=crop',
    'waxing': 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=300&h=400&fit=crop',
    'body': 'https://images.unsplash.com/photo-1515377905703-c4788e51af15?w=300&h=400&fit=crop',
    'henna': 'https://images.unsplash.com/photo-1599707367812-042af423e0e7?w=300&h=400&fit=crop',
    'braids': 'https://images.unsplash.com/photo-1580618672591-eb180b1a973f?w=300&h=400&fit=crop',
    'men': 'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=300&h=400&fit=crop',
  };

  /// Get a fallback network image URL for a category.
  static String? forCategory(String categoryId) {
    return _categoryImages[categoryId];
  }
}
