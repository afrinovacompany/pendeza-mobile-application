// lib/shared/models/lookbook_image_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class LookbookImageModel {
  final String id;
  final String imageUrl;
  final String title;
  final String? description;
  final List<String> tags;

  LookbookImageModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    this.description,
    required this.tags,
  });

  factory LookbookImageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LookbookImageModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? 'Untitled',
      description: data['description'],
      tags: List<String>.from(data['tags'] ?? []),
    );
  }
}