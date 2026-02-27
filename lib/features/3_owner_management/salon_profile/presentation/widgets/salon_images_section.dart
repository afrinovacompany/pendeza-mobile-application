import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import '../bloc/salon_profile_bloc.dart';
import '../bloc/salon_profile_event.dart';

class SalonImagesSection extends StatelessWidget {
  final SalonModel salon;

  const SalonImagesSection({
    super.key,
    required this.salon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasGallery = salon.imageGallery?.isNotEmpty ?? false;
    final galleryCount = salon.imageGallery?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Photos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (hasGallery) ...[
                  const SizedBox(width: AppConstants.padS),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.padS,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppConstants.radiusValL),
                    ),
                    child: Text(
                      '${galleryCount + (salon.primaryImage != null ? 1 : 0)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddPhotoOptions(context),
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.padM,
                  vertical: AppConstants.padS,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.padM),

        // Tips card (show if no images)
        if (salon.primaryImage == null && !hasGallery)
          _buildTipsCard(context),

        // Primary Image
        if (salon.primaryImage != null) ...[
          _buildPrimaryImageCard(context, salon.primaryImage!),
          const SizedBox(height: AppConstants.padM),
        ] else ...[
          _buildAddPrimaryButton(context),
          const SizedBox(height: AppConstants.padM),
        ],

        // Gallery section label
        if (hasGallery || salon.primaryImage != null)
          Padding(
            padding: const EdgeInsets.only(
              top: AppConstants.padM,
              bottom: AppConstants.padS,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.photo_library_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: AppConstants.padXS),
                Text(
                  'Gallery',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),

        // Gallery Grid
        if (hasGallery)
          _buildGalleryGrid(context, salon.imageGallery!)
        else if (salon.primaryImage != null)
          _buildEmptyGalleryPrompt(context),
      ],
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.padM),
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer.withOpacity(0.3),
            theme.colorScheme.secondaryContainer.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusValM),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tips_and_updates_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: AppConstants.padM),
              Text(
                'Photo Tips',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padM),
          _buildTipItem(context, '📸 Use good lighting'),
          _buildTipItem(context, '✨ Show your best work'),
          _buildTipItem(context, '🏪 Include salon interior'),
          _buildTipItem(context, '👥 Feature happy clients (with permission)'),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildPrimaryImageCard(BuildContext context, String imageUrl) {
    final theme = Theme.of(context);

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppConstants.radiusValM),
                ),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 220,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      gradient: LinearGradient(
                        colors: [
                          theme.dividerColor,
                          theme.dividerColor.withOpacity(0.5),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      _buildImagePlaceholder(context),
                ),
              ),

              // Gradient overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Primary badge
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppConstants.radiusValS),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Primary Photo',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.all(AppConstants.padS),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewFullImage(context, imageUrl),
                  icon: const Icon(Icons.zoom_in_rounded, size: 16),
                  label: const Text('View'),
                ),
                TextButton.icon(
                  onPressed: () => _showImagePicker(context, isPrimary: true),
                  icon: const Icon(Icons.edit_rounded, size: 16),
                  label: const Text('Change'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDeletePrimary(context),
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPrimaryButton(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _showImagePicker(context, isPrimary: true),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.4),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusValM),
          color: theme.colorScheme.primary.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_rounded,
              size: 48,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: AppConstants.padM),
            Text(
              'Add Primary Photo',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.padXS),
            Text(
              'This is the first photo clients see',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(BuildContext context, List<String> images) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return _buildGalleryItem(context, images[index], index);
      },
    );
  }

  Widget _buildGalleryItem(BuildContext context, String imageUrl, int index) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _viewFullImage(context, imageUrl),
      onLongPress: () => _confirmDeleteGallery(context, index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusValS),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.dividerColor,
                child: const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.dividerColor,
                child: Icon(Icons.broken_image_rounded,
                    color: theme.colorScheme.error),
              ),
            ),
            // Delete icon overlay
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _confirmDeleteGallery(context, index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGalleryPrompt(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(AppConstants.radiusValM),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 36,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.padS),
          Text(
            'Add more photos to your gallery',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: AppConstants.padS),
          TextButton.icon(
            onPressed: () => _showImagePicker(context, isPrimary: false),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Photos'),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 220,
      color: theme.dividerColor,
      child: Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          size: 48,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
        ),
      ),
    );
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  void _showAddPhotoOptions(BuildContext context) {
    _showImagePicker(context, isPrimary: false);
  }

  /// ✅ FIX: Capture bloc reference BEFORE showing bottom sheet
  void _showImagePicker(BuildContext context, {required bool isPrimary}) {
    final bloc = context.read<SalonProfileBloc>();
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: AppConstants.padM),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(sheetContext).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppConstants.padL),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
              child: Text(
                isPrimary ? 'Add Primary Photo' : 'Add Photo to Gallery',
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: AppConstants.padL),

            // Camera option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppConstants.padS),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusValS),
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: Theme.of(sheetContext).colorScheme.primary,
                ),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use your camera'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 80, // Let image_picker handle quality
                );
                if (photo != null) {
                  // ✅ FIX: Upload directly — no compression, no dialog, no navigation issues
                  bloc.add(UploadSalonImage(photo.path, isPrimary: isPrimary));
                }
              },
            ),

            // Gallery option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppConstants.padS),
                decoration: BoxDecoration(
                  color: Theme.of(sheetContext).colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusValS),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: Theme.of(sheetContext).colorScheme.secondary,
                ),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photo'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80, // Let image_picker handle quality
                );
                if (photo != null) {
                  // ✅ FIX: Upload directly — no compression, no dialog, no navigation issues
                  bloc.add(UploadSalonImage(photo.path, isPrimary: isPrimary));
                }
              },
            ),
            const SizedBox(height: AppConstants.padM),
          ],
        ),
      ),
    );
  }

  void _viewFullImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeletePrimary(BuildContext context) {
    final bloc = context.read<SalonProfileBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Primary Photo?'),
        content: const Text(
          'This will remove your main salon photo. You can add a new one anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(const DeletePrimaryImage());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteGallery(BuildContext context, int index) {
    final bloc = context.read<SalonProfileBloc>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('This will permanently remove this photo from your gallery.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(DeleteGalleryImage(index));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}