  import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import 'package:pendeza/app/helpers/video_compressor_helper.dart';
import '../bloc/salon_profile_bloc.dart';
import '../bloc/salon_profile_event.dart';

/// Maximum videos allowed per salon
const int kMaxVideosPerSalon = 3;

/// Maximum video duration in seconds
const int kMaxVideoDuration = 60;

class SalonVideosSection extends StatelessWidget {
  final List<SalonVideoModel> videos;

  const SalonVideosSection({
    super.key,
    required this.videos,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canAddMore = videos.length < kMaxVideosPerSalon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Video Shorts',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                    '${videos.length}/$kMaxVideosPerSalon',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (canAddMore)
              ElevatedButton.icon(
                onPressed: () => _showAddVideoSheet(context),
                icon: const Icon(Icons.videocam_rounded, size: 18),
                label: const Text('Add Video'),
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

        // Info card
        _buildInfoCard(context),
        const SizedBox(height: AppConstants.padM),

        // Videos grid or empty state
        if (videos.isEmpty)
          _buildEmptyState(context, canAddMore)
        else
          _buildVideosGrid(context),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(AppConstants.radiusValM),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppConstants.padS),
          Expanded(
            child: Text(
              'Short videos (max 60 sec) showcase your work. Videos need admin approval before going live.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool canAddMore) {
    final theme = Theme.of(context);

    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.padXL),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.padL),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_circle_outline_rounded,
                size: 48,
                color: theme.colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppConstants.padM),
            Text(
              'No videos yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.padXS),
            Text(
              'Add short videos to showcase your best work\nand attract more clients!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.padL),
            if (canAddMore)
              ElevatedButton.icon(
                onPressed: () => _showAddVideoSheet(context),
                icon: const Icon(Icons.videocam_rounded),
                label: const Text('Add Your First Video'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosGrid(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppConstants.padS,
        mainAxisSpacing: AppConstants.padS,
        childAspectRatio: 9 / 16,
      ),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        return _VideoThumbnailCard(
          video: videos[index],
          onTap: () => _showVideoOptionsSheet(context, videos[index]),
        );
      },
    );
  }

  void _showAddVideoSheet(BuildContext context) {
    final bloc = context.read<SalonProfileBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppConstants.radiusValL),
        ),
      ),
      builder: (sheetContext) => _AddVideoSheet(
        onVideoSelected: (videoPath, caption) {
          Navigator.pop(sheetContext);
          bloc.add(UploadSalonVideo(videoPath: videoPath, caption: caption));
        },
      ),
    );
  }

  void _showVideoOptionsSheet(BuildContext context, SalonVideoModel video) {
    final bloc = context.read<SalonProfileBloc>();
    final theme = Theme.of(context);

    showModalBottomSheet(
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

            // Video preview
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(video.thumbnailUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.padM),

            // Status badge
            _buildStatusBadge(video, theme),
            const SizedBox(height: AppConstants.padM),

            if (video.caption != null && video.caption!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                child: Text(
                  video.caption!,
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: AppConstants.padL),

            Text(
              'Duration: ${video.formattedDuration}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: AppConstants.padL),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showEditCaptionDialog(context, video, bloc);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit Caption'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.padM),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _confirmDeleteVideo(context, video, bloc);
                      },
                      icon: const Icon(Icons.delete_rounded, size: 18),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.padL),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SalonVideoModel video, ThemeData theme) {
    Color color;
    IconData icon;
    String text;

    switch (video.status) {
      case VideoApprovalStatus.pending:
        color = Colors.orange;
        icon = Icons.hourglass_empty_rounded;
        text = 'Pending Review';
        break;
      case VideoApprovalStatus.approved:
        color = Colors.green;
        icon = Icons.check_circle_rounded;
        text = 'Live';
        break;
      case VideoApprovalStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel_rounded;
        text = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.padM,
        vertical: AppConstants.padXS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radiusValL),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditCaptionDialog(
    BuildContext context,
    SalonVideoModel video,
    SalonProfileBloc bloc,
  ) {
    final controller = TextEditingController(text: video.caption ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Caption'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 150,
          decoration: const InputDecoration(
            hintText: 'Add a caption (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(UpdateVideoCaption(
                videoId: video.id,
                caption: controller.text.trim(),
              ));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteVideo(
    BuildContext context,
    SalonVideoModel video,
    SalonProfileBloc bloc,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Video?'),
        content: const Text(
          'This will permanently delete this video. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(DeleteSalonVideo(video.id));
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Video thumbnail card widget
class _VideoThumbnailCard extends StatelessWidget {
  final SalonVideoModel video;
  final VoidCallback onTap;

  const _VideoThumbnailCard({
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppConstants.radiusValM),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.radiusValM),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
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
                    Icons.videocam_off_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.5, 1.0],
                  ),
                ),
              ),

              Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),

              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    video.formattedDuration,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _getStatusColor(video.status),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(VideoApprovalStatus status) {
    switch (status) {
      case VideoApprovalStatus.pending:
        return Colors.orange;
      case VideoApprovalStatus.approved:
        return Colors.green;
      case VideoApprovalStatus.rejected:
        return Colors.red;
    }
  }
}

/// Bottom sheet for adding a new video
class _AddVideoSheet extends StatefulWidget {
  final Function(String videoPath, String? caption) onVideoSelected;

  const _AddVideoSheet({required this.onVideoSelected});

  @override
  State<_AddVideoSheet> createState() => _AddVideoSheetState();
}

class _AddVideoSheetState extends State<_AddVideoSheet> {
  final _captionController = TextEditingController();
  File? _selectedVideo;
  File? _thumbnail;
  int? _duration;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.padL),

              Text(
                'Add Video Short',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppConstants.padXS),
              Text(
                'Max 60 seconds • Will be reviewed before going live',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: AppConstants.padL),

              if (_selectedVideo == null)
                _buildVideoPickerArea(context)
              else
                _buildVideoPreview(context),

              if (_errorMessage != null) ...[
                const SizedBox(height: AppConstants.padM),
                Container(
                  padding: const EdgeInsets.all(AppConstants.padM),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: AppConstants.padS),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (_selectedVideo != null && _thumbnail != null) ...[
                const SizedBox(height: AppConstants.padL),
                Text('Caption (optional)', style: theme.textTheme.labelLarge),
                const SizedBox(height: AppConstants.padXS),
                TextField(
                  controller: _captionController,
                  maxLines: 2,
                  maxLength: 150,
                  decoration: InputDecoration(
                    hintText: 'Add a short description...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.padL),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _handleUpload,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.cloud_upload_rounded),
                    label: Text(_isProcessing ? 'Processing...' : 'Upload Video'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(AppConstants.padM),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: AppConstants.padM),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPickerArea(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildOptionTile(
          context,
          icon: Icons.videocam_rounded,
          title: 'Record Video',
          subtitle: 'Use your camera',
          color: theme.colorScheme.primary,
          onTap: () => _pickVideo(ImageSource.camera),
        ),
        const SizedBox(height: AppConstants.padM),
        _buildOptionTile(
          context,
          icon: Icons.video_library_rounded,
          title: 'Choose from Gallery',
          subtitle: 'Select existing video',
          color: theme.colorScheme.secondary,
          onTap: () => _pickVideo(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(AppConstants.radiusValM),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.padM),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(AppConstants.radiusValM),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.padM),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppConstants.radiusValS),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: AppConstants.padM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.radiusValM),
            color: theme.dividerColor,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusValM),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_thumbnail != null)
                  Image.file(_thumbnail!, fit: BoxFit.cover)
                else if (_isProcessing)
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: AppConstants.padM),
                        Text('Generating preview...'),
                      ],
                    ),
                  ),

                if (_thumbnail != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                if (_duration != null)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${_duration! ~/ 60}:${(_duration! % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedVideo = null;
                          _thumbnail = null;
                          _duration = null;
                          _errorMessage = null;
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppConstants.padM),
        Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
            const SizedBox(width: AppConstants.padXS),
            Text(
              'Video ready to upload',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickVideo(ImageSource source) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(seconds: kMaxVideoDuration),
      );

      if (video == null) {
        setState(() => _isProcessing = false);
        return;
      }

      final videoFile = File(video.path);
      final duration = await VideoCompressionHelper.getVideoDuration(videoFile);

      if (duration == null) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Could not read video duration';
        });
        return;
      }

      if (duration > kMaxVideoDuration) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Video must be $kMaxVideoDuration seconds or less. Your video is $duration seconds.';
        });
        return;
      }

      final thumbnail = await VideoCompressionHelper.generateThumbnail(videoFile);

      setState(() {
        _selectedVideo = videoFile;
        _thumbnail = thumbnail;
        _duration = duration;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Error selecting video: ${e.toString()}';
      });
    }
  }

  void _handleUpload() {
    if (_selectedVideo == null) return;

    final caption = _captionController.text.trim();
    widget.onVideoSelected(
      _selectedVideo!.path,
      caption.isEmpty ? null : caption,
    );
  }
}
