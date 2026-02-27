import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:pendeza/features/video_shorts/presentation/screens/video_viewer_screen.dart';

class SalonGalleryScreen extends StatefulWidget {
  final SalonModel salon;

  const SalonGalleryScreen({super.key, required this.salon});

  @override
  State<SalonGalleryScreen> createState() => _SalonGalleryScreenState();
}

class _SalonGalleryScreenState extends State<SalonGalleryScreen> {
  List<SalonVideoModel>? _videos;
  bool _isLoadingVideos = true;
  String? _videoError;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('salon_videos')
          .where('salonId', isEqualTo: widget.salon.id)
          .orderBy('createdAt', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _videos = querySnapshot.docs
              .map((doc) => SalonVideoModel.fromFirestore(doc))
              .toList();
          _isLoadingVideos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _videoError = e.toString();
          _isLoadingVideos = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final images = widget.salon.allImages;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.salon.salonName),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            labelStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.photo, size: 18),
                    const SizedBox(width: 6),
                    Text('Photos${images.isNotEmpty ? ' (${images.length})' : ''}'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.play_rectangle, size: 18),
                    const SizedBox(width: 6),
                    Text('Videos${_videos != null && _videos!.isNotEmpty ? ' (${_videos!.length})' : ''}'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildPhotoGrid(context, images),
            _buildVideoGrid(context),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHOTOS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildPhotoGrid(BuildContext context, List<String> images) {
    if (images.isEmpty) {
      return const EmptyStateWidget.notFound(
        message: 'No photos available for this salon.',
        iconData: CupertinoIcons.photo,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.padS),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: 1.0,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => _openPhotoViewer(context, index, images),
          child: Hero(
            tag: 'gallery_full_$index',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radiusValXS),
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

  // ═══════════════════════════════════════════════════════════════════════════
  // VIDEOS TAB
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVideoGrid(BuildContext context) {
    if (_isLoadingVideos) {
      return _buildVideoLoadingShimmer(context);
    }

    if (_videoError != null) {
      return EmptyStateWidget.error(
        message: 'Could not load videos. Please try again.',
        onActionPressed: () {
          setState(() {
            _isLoadingVideos = true;
            _videoError = null;
          });
          _fetchVideos();
        },
      );
    }

    final videos = _videos ?? [];

    if (videos.isEmpty) {
      return const EmptyStateWidget.notFound(
        message: 'No videos available for this salon yet.',
        iconData: CupertinoIcons.video_camera,
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.padS),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: 9 / 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return _VideoGridTile(
          video: videos[index],
          onTap: () => _openVideoViewer(context, index, videos),
        );
      },
    );
  }

  Widget _buildVideoLoadingShimmer(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppConstants.padS),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
        childAspectRatio: 9 / 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusValS),
          child: const ShimmerPlaceholder.rectangular(height: double.infinity),
        );
      },
    );
  }

  void _openVideoViewer(
      BuildContext context, int index, List<SalonVideoModel> videos) {
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return VideoViewerScreen(
            videos: videos,
            initialIndex: index,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// VIDEO GRID TILE - TikTok-style thumbnail card
// ═════════════════════════════════════════════════════════════════════════════

class _VideoGridTile extends StatelessWidget {
  final SalonVideoModel video;
  final VoidCallback onTap;

  const _VideoGridTile({
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusValS),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail
            CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  CupertinoIcons.video_camera,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                  size: 28,
                ),
              ),
            ),

            // Bottom gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Play icon center
            Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.play_fill,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),

            // Duration badge bottom-right
            Positioned(
              bottom: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  video.formattedDuration,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Caption at bottom-left (if exists)
            if (video.caption != null && video.caption!.isNotEmpty)
              Positioned(
                bottom: 6,
                left: 6,
                right: 40,
                child: Text(
                  video.caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FULL SCREEN IMAGE VIEWER
// ═════════════════════════════════════════════════════════════════════════════

class _FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        builder: (BuildContext context, int index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(widget.images[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 2.5,
            heroAttributes:
                PhotoViewHeroAttributes(tag: 'gallery_full_$index'),
          );
        },
        itemCount: widget.images.length,
        loadingBuilder: (context, event) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        backgroundDecoration: const BoxDecoration(color: Colors.black),
        pageController: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
