import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

const double _kStoryCircleSize = 68;
const double _kStoryItemGap = 8;

/// Instagram-style story widget showing video shorts from salons
///
/// Displays circular thumbnails with gradient rings, tapping opens
/// full-screen video viewer with swipe navigation
class VideoStoryWidget extends StatelessWidget {
  final double height;

  const VideoStoryWidget({super.key, this.height = 105});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VideoShortsBloc, VideoShortsState>(
      builder: (context, state) {
        log.d('📺 [VideoStoryWidget] Current Bloc State: ${state.runtimeType}');

        if (state is VideoShortsInitial) {
          log.i(
            '📺 [VideoStoryWidget] Initial state detected. Triggering LoadVideoShorts event...',
          );
          // Manually triggering the event if the Bloc hasn't started
          context.read<VideoShortsBloc>().add(LoadVideoShorts());
          return _buildLoadingState();
        }

        if (state is VideoShortsLoading) {
          return _buildLoadingState();
        }

        if (state is VideoShortsError) {
          log.e('📺 [VideoStoryWidget] Bloc Error: ${state.message}');
          return _buildSoftState(
            context,
            message: 'client.dashboard.stories_error'.tr(),
            onRetry:
                () => context.read<VideoShortsBloc>().add(
                  const LoadVideoShorts(),
                ),
          );
        }

        if (state is VideoShortsLoaded) {
          log.i('📺 [VideoStoryWidget] Videos loaded: ${state.videos.length}');
          if (!state.hasVideos) {
            log.w(
              '📺 [VideoStoryWidget] State says Loaded, but video list is empty.',
            );
            return _buildSoftState(
              context,
              message: 'client.dashboard.no_stories'.tr(),
            );
          }

          return _buildStoriesRow(context, state.salonStories);
        }

        return _buildSoftState(
          context,
          message: 'client.dashboard.no_stories'.tr(),
        );
      },
    );
  }

  Widget _buildSoftState(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    final theme = Theme.of(context);
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: Text('common.retry'.tr())),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
        itemCount: 5,
        separatorBuilder: (_, _) => const SizedBox(width: _kStoryItemGap),
        itemBuilder: (context, index) {
          return const Center(
            child: ShimmerPlaceholder(
              width: _kStoryCircleSize,
              height: _kStoryCircleSize,
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoriesRow(BuildContext context, List<SalonStory> stories) {
    return _AutoScrollingStoriesRow(
      height: height,
      stories: stories,
      onStoryTap: (index) => _openVideoViewer(context, stories, index),
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
          return VideoViewerScreen(videos: allVideos, initialIndex: videoIndex);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up from bottom for TikTok-style entrance
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          );
        },
      ),
    );
  }
}

/// Horizontal stories list that gently auto-advances, pausing on touch/drag.
class _AutoScrollingStoriesRow extends StatefulWidget {
  final double height;
  final List<SalonStory> stories;
  final ValueChanged<int> onStoryTap;

  const _AutoScrollingStoriesRow({
    required this.height,
    required this.stories,
    required this.onStoryTap,
  });

  @override
  State<_AutoScrollingStoriesRow> createState() =>
      _AutoScrollingStoriesRowState();
}

class _AutoScrollingStoriesRowState extends State<_AutoScrollingStoriesRow> {
  static const _itemStride = _kStoryCircleSize + _kStoryItemGap;
  static const _autoScrollInterval = Duration(milliseconds: 3200);
  static const _resumeDelay = Duration(milliseconds: 2500);
  static const _advanceDuration = Duration(milliseconds: 750);
  static const _loopBackDuration = Duration(milliseconds: 900);

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _resumeTimer;
  bool _paused = false;
  int _activePointers = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
  }

  @override
  void didUpdateWidget(covariant _AutoScrollingStoriesRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stories.length != widget.stories.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoScroll());
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _resumeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!mounted || _paused || !_canAutoScroll) return;
    _autoScrollTimer = Timer.periodic(_autoScrollInterval, (_) => _scrollNext());
  }

  bool get _canAutoScroll {
    if (widget.stories.length < 2) return false;
    if (!_scrollController.hasClients) return false;
    return _scrollController.position.maxScrollExtent > 0;
  }

  void _scrollNext() {
    if (!mounted || _paused || !_canAutoScroll) return;

    final maxExtent = _scrollController.position.maxScrollExtent;
    final nextOffset = _scrollController.offset + _itemStride;
    final loopingBack = nextOffset >= maxExtent - 4;

    _scrollController.animateTo(
      loopingBack ? 0 : nextOffset.clamp(0.0, maxExtent),
      duration: loopingBack ? _loopBackDuration : _advanceDuration,
      curve: Curves.easeInOutCubic,
    );
  }

  void _pauseForUser() {
    _paused = true;
    _resumeTimer?.cancel();
    _autoScrollTimer?.cancel();
  }

  void _onPointerDown() {
    _activePointers++;
    _pauseForUser();
  }

  void _onPointerReleased() {
    if (_activePointers > 0) _activePointers--;
    if (_activePointers == 0) _scheduleResume();
  }

  void _scheduleResume() {
    if (_activePointers > 0) return;
    _resumeTimer?.cancel();
    _resumeTimer = Timer(_resumeDelay, () {
      if (!mounted || _activePointers > 0) return;
      _paused = false;
      _startAutoScroll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: Listener(
        onPointerDown: (_) => _onPointerDown(),
        onPointerUp: (_) => _onPointerReleased(),
        onPointerCancel: (_) => _onPointerReleased(),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.depth != 0) return false;
            // Pause only for real user input (drag / trackpad), not
            // the row's own auto-scroll animations.
            if (notification is ScrollStartNotification &&
                notification.dragDetails != null) {
              _pauseForUser();
            } else if (notification is UserScrollNotification &&
                notification.direction != ScrollDirection.idle) {
              _pauseForUser();
            } else if (notification is ScrollEndNotification && _paused) {
              _scheduleResume();
            }
            return false;
          },
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
            itemCount: widget.stories.length,
            separatorBuilder: (_, _) => const SizedBox(width: _kStoryItemGap),
            itemBuilder: (context, index) {
              final story = widget.stories[index];
              return _StoryCircle(
                story: story,
                onTap: () => widget.onStoryTap(index),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Individual story circle with gradient ring
class _StoryCircle extends StatelessWidget {
  final SalonStory story;
  final VoidCallback onTap;

  const _StoryCircle({required this.story, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _kStoryCircleSize,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: _kStoryCircleSize,
                height: _kStoryCircleSize,
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.secondary,
                      theme.colorScheme.tertiary,
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
                      placeholder:
                          (context, url) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                      errorWidget:
                          (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.play_circle_fill_rounded,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.5,
                              ),
                              size: 24,
                            ),
                          ),
                    ),
                  ),
                ),
              ),
              if (story.videos.length > 1)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
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
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondary,
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
                  placeholder:
                      (context, url) => Container(color: theme.dividerColor),
                  errorWidget:
                      (context, url, error) => Container(
                        color: theme.dividerColor,
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
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
