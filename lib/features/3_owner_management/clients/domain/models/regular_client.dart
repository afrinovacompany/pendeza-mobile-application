
/// Simplified client model for owner's client management
/// 
/// Only contains essential info:
/// - Who they are (name, photo, phone)
/// - When they last visited
/// - How many times they've visited (for sorting regulars)
class RegularClient {
  final String id;
  final String name;
  final String? phone;
  final String? photoUrl;
  final DateTime lastVisit;
  final int visitCount;

  const RegularClient({
    required this.id,
    required this.name,
    this.phone,
    this.photoUrl,
    required this.lastVisit,
    required this.visitCount,
  });

  /// Create from Firestore user doc + aggregated appointment data
  factory RegularClient.fromData({
    required String userId,
    required String userName,
    String? userPhone,
    String? userPhotoUrl,
    required DateTime lastVisitDate,
    required int totalVisits,
  }) {
    return RegularClient(
      id: userId,
      name: userName,
      phone: userPhone,
      photoUrl: userPhotoUrl,
      lastVisit: lastVisitDate,
      visitCount: totalVisits,
    );
  }

  /// Get formatted last visit text
  String get lastVisitFormatted {
    final now = DateTime.now();
    final diff = now.difference(lastVisit);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 60) return '1mo ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  /// Check if client is a regular (5+ visits)
  bool get isRegular => visitCount >= 5;
}
