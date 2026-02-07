import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/logger.dart'; // Using your logger
import 'package:pendeza/shared/models/salon_video_model.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import '../bloc/video_shorts_bloc.dart';
import '../bloc/video_shorts_event.dart'; // Ensure this is imported
import '../bloc/video_shorts_state.dart';
import '../screens/video_viewer_screen.dart';

/// Instagram-style story widget showing video shorts from salons
///
/// Displays circular thumbnails with gradient rings, tapping opens
/// full-screen video viewer with swipe navigation
class VideoStoryWidget extends StatelessWidget {
  final double height;

  const VideoStoryWidget({
    super.key,
    this.height = 105,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoShortsBloc, VideoShortsState>(
      builder: (context, state) {
        log.d('📺 [VideoStoryWidget] Current Bloc State: ${state.runtimeType}');

        if (state is VideoShortsInitial) {
          log.i('📺 [VideoStoryWidget] Initial state detected. Triggering LoadVideoShorts event...');
          // Manually triggering the event if the Bloc hasn't started
          context.read<VideoShortsBloc>().add(LoadVideoShorts());
          return _buildLoadingState();
        }

        if (state is VideoShortsLoading) {
          return _buildLoadingState();
        }

        if (state is VideoShortsError) {
          log.e('📺 [VideoStoryWidget] Bloc Error: ${state.message}');
          return const SizedBox.shrink(); // Hide on error
        }

        if (state is VideoShortsLoaded) {
          log.i('📺 [VideoStoryWidget] Videos loaded: ${state.videos.length}');
          if (!state.hasVideos) {
            log.w('📺 [VideoStoryWidget] State says Loaded, but video list is empty.');
            return const SizedBox.shrink(); // Hide if no videos
          }

          return _buildStoriesRow(context, state.salonStories);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(width: AppConstants.padM),
        itemBuilder: (context, index) {
          return Column(
            children: [
              const ShimmerPlaceholder(
                width: 68,
                height: 68,
                shape: BoxShape.circle,
              ),
              const SizedBox(height: 6),
              ShimmerPlaceholder.rectangular(
                width: 60,
                height: 14,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStoriesRow(BuildContext context, List<SalonStory> stories) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
        itemCount: stories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppConstants.padM),
        itemBuilder: (context, index) {
          final story = stories[index];
          return _StoryCircle(
            story: story,
            onTap: () => _openVideoViewer(context, stories, index),
          );
        },
      ),
    );
  }

  void _openVideoViewer(
      BuildContext context,
      List<SalonStory> stories,
      int initialIndex,
      ) {
    // Flatten all videos from all salons for continuous viewing
    final allVideos = stories.expand((s) => s.videos).toList();

    // Find the index of the first video from the tapped salon
    int videoIndex = 0;
    for (int i = 0; i < initialIndex; i++) {
      videoIndex += stories[i].videos.length;
    }

    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: true, // Fully hide underlying content for immersive experience
        pageBuilder: (context, animation, secondaryAnimation) {
          return VideoViewerScreen(
            videos: allVideos,
            initialIndex: videoIndex,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up from bottom for TikTok-style entrance
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

/// Individual story circle with gradient ring
class _StoryCircle extends StatelessWidget {
  final SalonStory story;
  final VoidCallback onTap;

  const _StoryCircle({
    required this.story,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Story circle with gradient ring + video count badge overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                        Colors.pink,
                        Colors.orange,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.scaffoldBackgroundColor,
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: story.thumbnailUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Video count badge as overlay (prevents height overflow)
                if (story.videos.length > 1)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${story.videos.length}',
                        style: const TextStyle(
                          fontSize: 9,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            // Salon name - constrained height
            SizedBox(
              height: 28,
              child: Text(
                story.salonName,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone widget for use outside BlocBuilder
class VideoStoryItem extends StatelessWidget {
  final SalonVideoModel video;
  final VoidCallback onTap;
  final double size;

  const VideoStoryItem({
    super.key,
    required this.video,
    required this.onTap,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  Colors.pink,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.scaffoldBackgroundColor,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: theme.dividerColor,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: theme.dividerColor,
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: theme.colorScheme.primary.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: size,
            child: Text(
              video.salonName,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}