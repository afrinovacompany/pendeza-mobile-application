import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import '../bloc/salon_profile_bloc.dart';
import '../bloc/salon_profile_event.dart';
import 'package:pendeza/app/helpers/image_compressor_helper.dart';

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
            // ✅ Improved add button
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

        // ✅ Tips card (show if no images)
        if (salon.primaryImage == null && !hasGallery)
          _buildTipsCard(context),

        // Primary Image with enhanced design
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

        // Gallery Grid with improved layout
        if (hasGallery)
          _buildGalleryGrid(context, salon.imageGallery!)
        else if (salon.primaryImage != null)
          _buildEmptyGalleryPrompt(context),
      ],
    );
  }

  // ✅ NEW: Tips card for first-time users
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

  // ✅ ENHANCED: Primary image card
  Widget _buildPrimaryImageCard(BuildContext context, String imageUrl) {
    final theme = Theme.of(context);

    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              // Image with hero animation potential
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

              // Gradient overlay at bottom for better badge visibility
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),

              // Primary badge
              Positioned(
                bottom: AppConstants.padM,
                left: AppConstants.padM,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.padM,
                    vertical: AppConstants.padXS,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(AppConstants.radiusValL),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
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
            padding: const EdgeInsets.all(AppConstants.padM),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddPhotoOptions(context, isPrimary: true),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Change'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.padS,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.padM),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewFullImage(context, imageUrl),
                    icon: const Icon(Icons.fullscreen_rounded, size: 18),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppConstants.padS,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppConstants.padS),
                IconButton(
                  onPressed: () => _confirmDeletePrimary(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: Colors.red,
                  tooltip: 'Delete primary photo',
                ),
              ],
            ),
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
          color: theme.colorScheme.onSurface.withOpacity(0.3),
          size: 48,
        ),
      ),
    );
  }

  Widget _buildAddPrimaryButton(BuildContext context) {
    final theme = Theme.of(context);

    return CustomCard(
      child: InkWell(
        onTap: () => _showAddPhotoOptions(context, isPrimary: true),
        borderRadius: BorderRadius.circular(AppConstants.radiusValM),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(
              color: theme.colorScheme.primary.withOpacity(0.3),
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(AppConstants.radiusValM),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.padL),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_a_photo_rounded,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppConstants.padM),
              Text(
                'Add Primary Photo',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppConstants.padXS),
              Text(
                'This will be the main image clients see',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
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
        crossAxisSpacing: AppConstants.padS,
        mainAxisSpacing: AppConstants.padS,
        childAspectRatio: 1,
      ),
      itemCount: images.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        if (index == images.length) {
          return _buildAddGalleryButton(context);
        }
        return _buildGalleryItem(context, images[index], index);
      },
    );
  }

  Widget _buildGalleryItem(BuildContext context, String imageUrl, int index) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _viewFullImage(context, imageUrl),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusValS),
            child: CachedNetworkImage(
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
                child: Icon(
                  Icons.broken_image_rounded,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
              ),
            ),
          ),
          // Delete button overlay
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _confirmDeleteGallery(context, index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddGalleryButton(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => _showAddPhotoOptions(context, isPrimary: false),
      borderRadius: BorderRadius.circular(AppConstants.radiusValS),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(AppConstants.radiusValS),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_rounded,
              color: theme.colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              'Add',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
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
        border: Border.all(
          color: theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusValM),
      ),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: AppConstants.padM),
          Text(
            'Add more photos to your gallery',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppConstants.padM),
          ElevatedButton.icon(
            onPressed: () => _showAddPhotoOptions(context, isPrimary: false),
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
            label: const Text('Add Gallery Photos'),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: Capture bloc reference BEFORE showing bottom sheet
  Future<void> _showAddPhotoOptions(BuildContext context, {bool isPrimary = false}) async {
    final theme = Theme.of(context);
    final ImagePicker picker = ImagePicker();

    // ✅ FIX: Capture the bloc reference BEFORE opening the bottom sheet
    final salonProfileBloc = context.read<SalonProfileBloc>();

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusValL),
        ),
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
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppConstants.padL),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
              child: Text(
                isPrimary ? 'Add Primary Photo' : 'Add Photo to Gallery',
                style: theme.textTheme.titleLarge?.copyWith(
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
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusValS),
                ),
                child: Icon(
                  Icons.photo_camera_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use your camera'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (photo != null && context.mounted) {
                  // ✅ FIX: Pass the bloc reference to the processing function
                  _processAndUploadImage(context, photo, isPrimary, salonProfileBloc);
                }
              },
            ),

            // Gallery option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppConstants.padS),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusValS),
                ),
                child: Icon(
                  Icons.photo_library_rounded,
                  color: theme.colorScheme.secondary,
                ),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photo'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (photo != null && context.mounted) {
                  // ✅ FIX: Pass the bloc reference to the processing function
                  _processAndUploadImage(context, photo, isPrimary, salonProfileBloc);
                }
              },
            ),
            const SizedBox(height: AppConstants.padM),
          ],
        ),
      ),
    );
  }

  // ✅ FIX: Image processing now receives the bloc directly
  Future<void> _processAndUploadImage(
      BuildContext context,
      XFile photo,
      bool isPrimary,
      SalonProfileBloc bloc, // ✅ FIX: Accept bloc as parameter
      ) async {

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppConstants.padL),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppConstants.padM),
                Text('Processing image...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final File originalFile = File(photo.path);
      final File? compressedFile = await ImageCompressionHelper.compressSalonPhoto(originalFile);

      if (context.mounted) {
        Navigator.pop(context); // Remove loading dialog

        if (compressedFile != null) {
          // ✅ FIX: Use the captured bloc reference directly
          bloc.add(
            UploadSalonImage(compressedFile.path, isPrimary: isPrimary),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to process image'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ NEW: Full image viewer
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

  // ✅ FIX: Capture bloc reference before showing dialog
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
              // ✅ FIX: Use captured bloc reference
              bloc.add(const DeletePrimaryImage());
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ✅ FIX: Capture bloc reference before showing dialog
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
              // ✅ FIX: Use captured bloc reference
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