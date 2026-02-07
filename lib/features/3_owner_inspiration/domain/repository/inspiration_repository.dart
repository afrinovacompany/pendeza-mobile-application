// lib/features/3_owner_inspiration/domain/repositories/inspiration_repository.dart

import '../../data/model/inspiration_article_model.dart';
import '../../data/model/lookbook_image_model.dart';

abstract class InspirationRepository {
  // --- READ ---
  Future<List<InspirationArticleModel>> getArticles();
  Future<List<LookbookImageModel>> getLookbook();

  // --- WRITE (For Admin) ---
  Future<void> addArticle(Map<String, dynamic> data);
  Future<void> addLookbookItem(Map<String, dynamic> data);

  // --- DELETE (For Admin) ---
  Future<void> deleteArticle(String articleId, String? imageUrl);
  Future<void> deleteLookbookItem(String itemId, String imageUrl);
}