// lib/features/3_owner_inspiration/data/repositories/inspiration_repository_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pendeza/app/utils/logger.dart';

import '../../data/model/inspiration_article_model.dart';
import '../../data/model/lookbook_image_model.dart';
// Note: This path is based on the file's location. Adjust if necessary.
import '../../domain/repository/inspiration_repository.dart';

class InspirationRepositoryImpl implements InspirationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- READ METHODS ---

  @override
  Future<List<InspirationArticleModel>> getArticles() async {
    final snapshot = await _db
        .collection('inspiration_articles')
        .orderBy('publishedAt', descending: true)
        .limit(20)
        .get();
    return snapshot.docs.map(InspirationArticleModel.fromFirestore).toList();
  }

  @override
  Future<List<LookbookImageModel>> getLookbook() async {
    final snapshot = await _db
        .collection('lookbook_images')
    // FIX: The model factory uses 'uploadedAt', so we order by that.
        .orderBy('uploadedAt', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map(LookbookImageModel.fromFirestore).toList();
  }

  // --- WRITE METHODS (For Admin) ---

  @override
  Future<void> addArticle(Map<String, dynamic> data) async {
    try {
      await _db.collection('inspiration_articles').add(data);
    } catch (e, s) {
      log.e('Failed to add article', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> addLookbookItem(Map<String, dynamic> data) async {
    try {
      await _db.collection('lookbook_images').add(data);
    } catch (e, s) {
      log.e('Failed to add lookbook item', error: e, stackTrace: s);
      rethrow;
    }
  }

  // --- DELETE METHODS (For Admin) ---

  /// Helper to delete image from Firebase Storage
  Future<void> _deleteImageFromUrl(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return;
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      log.i('Successfully deleted image from Storage: $imageUrl');
    } catch (e, s) {
      // Log as warning, not error. Deleting the DB entry is more important.
      log.w('Failed to delete image from Storage. It might already be deleted.',
          error: e, stackTrace: s);
    }
  }

  @override
  Future<void> deleteArticle(String articleId, String? imageUrl) async {
    try {
      // Delete the image from Storage first
      await _deleteImageFromUrl(imageUrl);
      // Then delete the document from Firestore
      await _db.collection('inspiration_articles').doc(articleId).delete();
    } catch (e, s) {
      log.e('Failed to delete article document', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Future<void> deleteLookbookItem(String itemId, String imageUrl) async {
    try {
      // Delete the image from Storage first
      await _deleteImageFromUrl(imageUrl);
      // Then delete the document from Firestore
      await _db.collection('lookbook_images').doc(itemId).delete();
    } catch (e, s) {
      log.e('Failed to delete lookbook item document', error: e, stackTrace: s);
      rethrow;
    }
  }
}