import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_bloc.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_event.dart';
import 'package:pendeza/features/2_client_booking/presentation/bloc/booking_state.dart';

/// Full-screen video viewer with TikTok-style vertical swiping
class VideoViewerScreen extends StatefulWidget {
  final List<SalonVideoModel> videos;
  final int initialIndex;

  const VideoViewerScreen({
    super.key,
    required this.videos,
    this.initialIndex = 0,
  });

  @override
  State<VideoViewerScreen> createState() => _VideoViewerScreenState();
}

class _VideoViewerScreenState extends State<VideoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;
  final Map<int, VideoPlayerController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _initializeVideo(_currentIndex);

    if (_currentIndex > 0) _initializeVideo(_currentIndex - 1);
    if (_currentIndex < widget.videos.length - 1) _initializeVideo(_currentIndex + 1);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(int index) async {
    if (_controllers.containsKey(index)) return;
    if (index < 0 || index >= widget.videos.length) return;

    final video = widget.videos[index];
    final controller = VideoPlayerController.networkUrl(Uri.parse(video.videoUrl));
    _controllers[index] = controller;

    await controller.initialize();
    controller.setLooping(true);

    if (index == _currentIndex && mounted) {
      controller.play();
      setState(() {});
    }
  }

  void _onPageChanged(int index) {
    _controllers[_currentIndex]?.pause();
    _currentIndex = index;
    _controllers[_currentIndex]?.play();

    if (index > 0) _initializeVideo(index - 1);
    if (index < widget.videos.length - 1) _initializeVideo(index + 1);

    _cleanupDistantControllers(index);
    setState(() {});
  }

  void _cleanupDistantControllers(int currentIndex) {
    final keysToRemove = <int>[];
    for (final key in _controllers.keys) {
      if ((key - currentIndex).abs() > 2) {
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _controllers[key]?.dispose();
      _controllers.remove(key);
    }
  }

  void _togglePlayPause() {
    final controller = _controllers[_currentIndex];
    if (controller == null) return;
    controller.value.isPlaying ? controller.pause() : controller.play();
    setState(() {});
  }

  // ✅ FIXED: Wait for salon data to load before navigating
  Future<void> _navigateToBooking(SalonVideoModel video) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      // 1. Trigger the BLoC and wait for response
      final bloc = context.read<BookingBloc>();
      bloc.add(StartBookingWithId(video.salonId));

      // 2. Wait for the salon to load (listen to state changes)
      await for (final state in bloc.stream) {
        if (state is BookingInProgress &&
            state.status == BookingStatus.selectingServices) {
          // Success! Close loading dialog
          if (mounted) Navigator.of(context).pop();

          // 3. Navigate to Service Selection
          if (mounted) {
            context.push(
              AppRoutes.serviceSelection.replaceFirst(':salonId', video.salonId),
              extra: {'salonName': video.salonName},
            );
          }
          break;
        } else if (state is BookingFailure) {
          // Error! Close loading dialog and show error
          if (mounted) Navigator.of(context).pop();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not load salon: ${state.error}'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          break;
        }
      }
    } catch (e) {
      // Error handling
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading salon: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: widget.videos.length,
            itemBuilder: (context, index) {
              return _VideoPage(
                video: widget.videos[index],
                controller: _controllers[index],
                onTap: _togglePlayPause,
                onBookNow: () => _navigateToBooking(widget.videos[index]),
              );
            },
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 24),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.videos.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPage extends StatelessWidget {
  final SalonVideoModel video;
  final VideoPlayerController? controller;
  final VoidCallback onTap;
  final VoidCallback onBookNow;

  const _VideoPage({
    required this.video,
    required this.controller,
    required this.onTap,
    required this.onBookNow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              ),
            )
          else
            CachedNetworkImage(
              imageUrl: video.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
              errorWidget: (context, url, error) => Container(color: Colors.grey[900], child: const Icon(Icons.video_library_rounded, color: Colors.white54, size: 64)),
            ),
          if (controller != null && controller!.value.isBuffering)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (controller != null && !controller!.value.isPlaying)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 50),
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: ClipOval(
                        child: video.salonImage != null
                            ? CachedNetworkImage(
                          imageUrl: video.salonImage!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Container(color: Colors.grey, child: const Icon(Icons.store, color: Colors.white)),
                        )
                            : Container(color: Colors.grey, child: const Icon(Icons.store, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(video.salonName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          if (video.salonAddress != null)
                            Text(video.salonAddress!, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (video.caption != null && video.caption!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(video.caption!, style: const TextStyle(color: Colors.white, fontSize: 14), maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onBookNow,
                    icon: const Icon(Icons.calendar_today_rounded),
                    label: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 200,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(16)),
                  child: Text(video.formattedDuration, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          if (controller != null && controller!.value.isInitialized)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                controller!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).colorScheme.primary,
                  bufferedColor: Colors.white.withValues(alpha: 0.3),
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                ),
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}