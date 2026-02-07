// lib/features/3_owner_inspiration/data/model/inspiration_article_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class InspirationArticleModel {
  final String id;
  final String title;
  final String summary; // Plain text summary for list view
  final String contentJson; // Rich text JSON for detail view
  final String? imageUrl; // Cover image
  final DateTime publishedAt;

  InspirationArticleModel({
    required this.id,
    required this.title,
    required this.summary,
    required this.contentJson,
    this.imageUrl,
    required this.publishedAt,
  });

  factory InspirationArticleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InspirationArticleModel(
      id: doc.id,
      title: data['title'] ?? '',
      // Fallback to 'body' for old articles if 'summary' missing
      summary: data['summary'] ?? data['body'] ?? '',
      // Fallback to empty array if missing
      contentJson: data['contentJson'] ?? '[{"insert":"\\n"}]',
      imageUrl: data['imageUrl'],
      publishedAt: (data['publishedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'summary': summary,
      'contentJson': contentJson,
      'imageUrl': imageUrl,
      'publishedAt': Timestamp.fromDate(publishedAt),
    };
  }
}