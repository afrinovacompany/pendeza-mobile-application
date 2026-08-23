import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pendeza/app/config/app_router.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';

/// A compact horizontal preview of the gallery.
/// Displays up to 4 thumbnails. If more exist, the last one shows "+X".
/// Tapping anywhere navigates to the full SalonGalleryScreen.
class SalonGalleryPreview extends StatelessWidget {
  final SalonModel salon;

  const SalonGalleryPreview({super.key, required this.salon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use allImages. If empty, hide widget.
    final images = salon.allImages;
    if (images.isEmpty) return const SizedBox.shrink();

    // We display max 4 items in the preview
    final displayCount = images.length > 4 ? 4 : images.length;
    final remainingCount = images.length - 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Gallery',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => _navigateToGallery(context),
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.padS),
        SizedBox(
          height: 100, // Fixed height for thumbnails
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
            scrollDirection: Axis.horizontal,
            itemCount: displayCount,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final isLastItem = index == displayCount - 1;
              final showOverlay = isLastItem && remainingCount > 0;

              return GestureDetector(
                onTap: () => _navigateToGallery(context),
                child: Container(
                  width: 100, // Square thumbnails
                  margin: const EdgeInsets.only(right: AppConstants.padS),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      ClipRRect(
                        borderRadius: AppConstants.radiusM,
                        child: CachedNetworkImage(
                          imageUrl: images[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                          const ShimmerPlaceholder.rectangular(height: 100),
                          errorWidget: (context, url, error) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.broken_image, size: 20),
                          ),
                        ),
                      ),

                      // "+X" Overlay for the last item
                      if (showOverlay)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: AppConstants.radiusM,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                          child: Center(
                            child: Text(
                              '+$remainingCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToGallery(BuildContext context) {
    context.push(
      AppRoutes.salonGallery.replaceFirst(':salonId', salon.id),
    );
  }
}