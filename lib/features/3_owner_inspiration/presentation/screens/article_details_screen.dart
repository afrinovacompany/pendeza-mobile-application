import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import '../../../3_owner_inspiration/data/model/inspiration_article_model.dart';

class ArticleDetailScreen extends StatefulWidget {
  final InspirationArticleModel article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late quill.QuillController _controller;

  @override
  void initState() {
    super.initState();
    try {
      // Parse the JSON content
      final doc = quill.Document.fromJson(jsonDecode(widget.article.contentJson));
      _controller = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true, // IMPORTANT: View mode only
      );
    } catch (e) {
      // Fallback for legacy plain text body
      _controller = quill.QuillController(
        document: quill.Document()..insert(0, widget.article.summary), // use summary as body
        selection: const TextSelection.collapsed(offset: 0),
        readOnly: true,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image Header
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: widget.article.imageUrl != null
                  ? CachedNetworkImage(
                imageUrl: widget.article.imageUrl!,
                fit: BoxFit.cover,
              )
                  : Container(color: AppColors.primary),
            ),
          ),

          // Article Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.article.title,
                    style: AppTextStyles.headline2.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppConstants.padS),

                  // Meta info
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, size: 16, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      // Key: "owner.inspiration.author" -> "Pendeza Team"
                      Text(
                        'owner.inspiration.author'.tr(),
                        style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 8),
                      Text("•", style: AppTextStyles.bodySmall),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat.yMMMd().format(widget.article.publishedAt),
                        style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const Divider(height: 40),

                  // Rich Text Content - FIXED API
                  quill.QuillEditor.basic(
                    controller: _controller,
                    config: const quill.QuillEditorConfig(
                      // Remove sharedConfigurations - not needed in basic constructor
                      placeholder: '',
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}