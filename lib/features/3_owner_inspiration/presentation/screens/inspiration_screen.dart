import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/app/services/service_locator.dart';

import '../../data/model/inspiration_article_model.dart';
import '../../data/model/lookbook_image_model.dart';
import '../../domain/repository/inspiration_repository.dart';
import '../bloc/inspiration_bloc.dart';
import '../bloc/inspiration_event.dart';
import '../bloc/inspiration_state.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import 'article_details_screen.dart'; // IMPORT THE NEW SCREEN

class InspirationScreen extends StatelessWidget {
  const InspirationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InspirationBloc(sl<InspirationRepository>())..add(const LoadInspiration()),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Inspiration Hub'), // Could be localized: "Inspiration Hub"
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => context.read<InspirationBloc>().add(const RefreshInspiration()),
              ),
            ],
            bottom: TabBar(
              onTap: (index) {
                final tab = index == 0 ? InspirationTab.trends : InspirationTab.lookbook;
                context.read<InspirationBloc>().add(SwitchTab(tab));
              },
              tabs: const [
                Tab(icon: Icon(CupertinoIcons.chart_bar_alt_fill), text: 'Market Trends'),
                Tab(icon: Icon(CupertinoIcons.photo_on_rectangle), text: 'Lookbook'),
              ],
            ),
          ),
          body: BlocBuilder<InspirationBloc, InspirationState>(
            builder: (context, state) {
              if (state is InspirationLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is InspirationError) {
                return Center(child: Text(state.message));
              }
              if (state is InspirationLoaded) {
                return TabBarView(
                  children: [
                    _TrendsTab(articles: state.articles),
                    _LookbookTab(images: state.lookbook),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _TrendsTab extends StatelessWidget {
  final List<InspirationArticleModel> articles;
  const _TrendsTab({required this.articles});

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) {
      return const Center(child: Text('No trends yet. Check back soon!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      itemCount: articles.length,
      itemBuilder: (context, i) {
        final article = articles[i];
        return CustomCard(
          onTap: () {
            // Navigate to full article view
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => ArticleDetailScreen(article: article)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (article.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const ColoredBox(color: Colors.grey),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(AppConstants.padM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.title,
                      style: AppTextStyles.headline3.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppConstants.padS),
                    Text(
                      article.summary, // Using summary instead of body
                      style: AppTextStyles.bodyMedium,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.padS),
                    Text(
                      DateFormat('MMM d, yyyy').format(article.publishedAt),
                      style: AppTextStyles.caption.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LookbookTab extends StatelessWidget {
  final List<LookbookImageModel> images;
  const _LookbookTab({required this.images});

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Center(child: Text('Lookbook coming soon!'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.padL),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppConstants.padM,
        mainAxisSpacing: AppConstants.padM,
        childAspectRatio: 0.75,
      ),
      itemCount: images.length,
      itemBuilder: (context, i) {
        final img = images[i];
        return CustomCard(
          onTap: () => _showImageDialog(context, img),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: CachedNetworkImage(
                    imageUrl: img.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppConstants.padS),
                child: Text(
                  img.title,
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImageDialog(BuildContext context, LookbookImageModel img) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedNetworkImage(imageUrl: img.imageUrl),
            Padding(
              padding: const EdgeInsets.all(AppConstants.padM),
              child: Text(img.title, style: AppTextStyles.headline3),
            ),
            if (img.description != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.padM),
                child: Text(img.description!, style: AppTextStyles.bodyMedium),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('common.close'.tr()), // "Close"
            ),
          ],
        ),
      ),
    );
  }
}