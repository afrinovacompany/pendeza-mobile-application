import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:flutter/cupertino.dart';

class SalonGalleryScreen extends StatefulWidget {
  final SalonModel salon;

  const SalonGalleryScreen({super.key, required this.salon});

  @override
  State<SalonGalleryScreen> createState() => _SalonGalleryScreenState();
}

class _SalonGalleryScreenState extends State<SalonGalleryScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = widget.salon.allImages;
    // Placeholder for videos until supported by backend
    final List<String> videos = [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.salon.salonName),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Photos'),
              Tab(text: 'Videos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // PHOTOS TAB
            _buildPhotoGrid(context, images),

            // VIDEOS TAB
            _buildVideoGrid(context, videos),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGrid(BuildContext context, List<String> images) {
    if (images.isEmpty) {
      return const EmptyStateWidget.notFound(
        message: 'No photos available for this salon.',
        iconData: CupertinoIcons.photo,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.padM),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppConstants.padS,
        mainAxisSpacing: AppConstants.padS,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openPhotoViewer(context, index, images),
          child: Hero(
            tag: 'gallery_full_$index',
            child: ClipRRect(
              borderRadius: AppConstants.radiusM,
              child: CachedNetworkImage(
                imageUrl: images[index],
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                const ShimmerPlaceholder.rectangular(height: double.infinity),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVideoGrid(BuildContext context, List<String> videos) {
    if (videos.isEmpty) {
      return const EmptyStateWidget.notFound(
        message: 'No videos available yet.',
        iconData: CupertinoIcons.video_camera,
      );
    }
    // Implement video grid here when backend supports it
    return const Center(child: Text("Videos coming soon"));
  }

  void _openPhotoViewer(BuildContext context, int index, List<String> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          images: images,
          initialIndex: index,
        ),
      ),
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(images[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2.5,
            heroAttributes: PhotoViewHeroAttributes(tag: 'gallery_full_$index'),
          );
        },
        itemCount: images.length,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: PageController(initialPage: initialIndex),
      ),
    );
  }
}