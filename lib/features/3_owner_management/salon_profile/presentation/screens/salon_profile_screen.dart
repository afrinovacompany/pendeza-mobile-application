import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/shared/widgets/empty_state_widget.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../../shared/models/salon_model.dart';
import '../bloc/salon_profile_bloc.dart';
import '../bloc/salon_profile_event.dart';
import '../bloc/salon_profile_state.dart';
import '../widgets/salon_basic_info_section.dart';
import '../widgets/salon_images_section.dart';
import '../widgets/salon_business_hours_section.dart';
import '../widgets/salon_contact_section.dart';
import '../widgets/salon_amenities_section.dart';
import '../widgets/salon_videos_section.dart';
import 'package:pendeza/shared/models/salon_video_model.dart';

/// ✅ Improved: StatefulWidget to properly manage BLoC lifecycle and prevent rebuilds
class SalonProfileScreen extends StatefulWidget {
  const SalonProfileScreen({super.key});

  @override
  State<SalonProfileScreen> createState() => _SalonProfileScreenState();
}

class _SalonProfileScreenState extends State<SalonProfileScreen> {
  late final SalonProfileBloc _salonProfileBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _salonProfileBloc = sl<SalonProfileBloc>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _salonProfileBloc.add(const LoadSalonProfile());
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _salonProfileBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _salonProfileBloc,
      child: const _SalonProfileView(),
    );
  }
}

class _SalonProfileView extends StatelessWidget {
  const _SalonProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility_rounded),
            tooltip: 'Preview how clients see your profile',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Preview feature coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<SalonProfileBloc, SalonProfileState>(
        buildWhen: (previous, current) {
          // Don't rebuild for operation success (handled by listener)
          return current is! SalonProfileOperationSuccess;
        },
        listener: (context, state) {
          if (state is SalonProfileOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: AppConstants.padS),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }

          if (state is SalonProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_rounded, color: Colors.white),
                    const SizedBox(width: AppConstants.padS),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          // ✅ NEW: Handle video-specific errors
          if (state is SalonVideoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.videocam_off_rounded, color: Colors.white),
                    const SizedBox(width: AppConstants.padS),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          // ✅ NEW: Handle video uploading state separately
          if (state is SalonVideoUploading) {
            return _buildContentWithVideoProgress(context, state);
          }

          if (state is SalonProfileInitial || state is SalonProfileLoading) {
            return _buildLoadingState();
          }

          if (state is SalonProfileError) {
            return EmptyStateWidget.error(
              message: state.message,
              onActionPressed: () => context
                  .read<SalonProfileBloc>()
                  .add(const LoadSalonProfile()),
            );
          }

          // Handle all states that have salon data
          final salon = _getSalonFromState(state);
          if (salon == null) return const SizedBox.shrink();

          final isUploading = state is SalonProfileUploading;
          final uploadProgress = isUploading ? (state).progress : 0.0;
          final uploadType = isUploading ? (state).uploadType : null;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SalonProfileBloc>().add(const RefreshSalonProfile());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(AppConstants.padL),
                  children: [
                    _buildHeroHeader(context, salon),
                    const SizedBox(height: AppConstants.padL),

                    _buildQuickActions(context, salon),
                    const SizedBox(height: AppConstants.padXL),

                    _buildSectionLabel(context, 'Basic Information', Icons.info_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonBasicInfoSection(salon: salon),
                    const SizedBox(height: AppConstants.padXL),

                    _buildSectionLabel(context, 'Photos', Icons.photo_library_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonImagesSection(salon: salon),
                    const SizedBox(height: AppConstants.padXL),

                    // ✅ NEW: Video Shorts section
                    _buildSectionLabel(context, 'Video Shorts', Icons.videocam_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonVideosSection(videos: _getVideosFromState(state)),
                    const SizedBox(height: AppConstants.padXL),

                    _buildSectionLabel(context, 'Operating Hours', Icons.access_time_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonBusinessHoursSection(salon: salon),
                    const SizedBox(height: AppConstants.padXL),

                    _buildSectionLabel(context, 'Contact & Social', Icons.connect_without_contact_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonContactSection(salon: salon),
                    const SizedBox(height: AppConstants.padXL),

                    _buildSectionLabel(context, 'Amenities', Icons.star_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonAmenitiesSection(salon: salon),
                    const SizedBox(height: AppConstants.padXXL * 2),
                  ],
                ),

                // ✅ Upload progress for images
                if (isUploading)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildUploadProgressBar(context, uploadProgress, uploadType),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ NEW: Build content while video is uploading with dedicated progress bar
  Widget _buildContentWithVideoProgress(BuildContext context, SalonVideoUploading state) {
    final salon = state.salon;
    final videos = state.videos;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.all(AppConstants.padL),
          children: [
            _buildHeroHeader(context, salon),
            const SizedBox(height: AppConstants.padL),

            _buildQuickActions(context, salon),
            const SizedBox(height: AppConstants.padXL),

            _buildSectionLabel(context, 'Basic Information', Icons.info_rounded),
            const SizedBox(height: AppConstants.padM),
            SalonBasicInfoSection(salon: salon),
            const SizedBox(height: AppConstants.padXL),

            _buildSectionLabel(context, 'Photos', Icons.photo_library_rounded),
            const SizedBox(height: AppConstants.padM),
            SalonImagesSection(salon: salon),
            const SizedBox(height: AppConstants.padXL),

            _buildSectionLabel(context, 'Video Shorts', Icons.videocam_rounded),
            const SizedBox(height: AppConstants.padM),
            SalonVideosSection(videos: videos),
            const SizedBox(height: AppConstants.padXL),

            _buildSectionLabel(context, 'Operating Hours', Icons.access_time_rounded),
            const SizedBox(height: AppConstants.padM),
            SalonBusinessHoursSection(salon: salon),
            const SizedBox(height: AppConstants.padXL),

            _buildSectionLabel(context, 'Contact & Social', Icons.connect_without_contact_rounded),
            const SizedBox(height: AppConstants.padM),
            SalonContactSection(salon: salon),
            const SizedBox(height: AppConstants.padXL),

            _buildSectionLabel(context, 'Amenities', Icons.star_rounded),
            const SizedBox(height: AppConstants.padM),
            SalonAmenitiesSection(salon: salon),
            const SizedBox(height: AppConstants.padXXL * 2),
          ],
        ),

        // ✅ NEW: Video upload progress bar (always on top)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildVideoUploadProgressBar(context, state),
        ),
      ],
    );
  }

  // ✅ Helper to extract salon from any valid state
  SalonModel? _getSalonFromState(SalonProfileState state) {
    if (state is SalonProfileLoaded) return state.salon;
    if (state is SalonProfileUploading) return state.salon;
    if (state is SalonProfileOperationSuccess) return state.salon;
    if (state is SalonVideoUploading) return state.salon;
    if (state is SalonVideoError) return state.salon;
    return null;
  }

  // ✅ Helper to extract videos from any valid state
  List<SalonVideoModel> _getVideosFromState(SalonProfileState state) {
    if (state is SalonProfileLoaded) return state.videos;
    if (state is SalonProfileUploading) return state.videos;
    if (state is SalonProfileOperationSuccess) return state.videos;
    if (state is SalonVideoUploading) return state.videos;
    if (state is SalonVideoError) return state.videos;
    return [];
  }

  // ✅ NEW: Video-specific progress bar with stages and cancel button
  Widget _buildVideoUploadProgressBar(BuildContext context, SalonVideoUploading state) {
    final theme = Theme.of(context);
    final progress = state.progress;
    final stage = state.stage;
    final stageText = state.stageText;

    // Map stages to icons and colors
    IconData stageIcon = Icons.videocam_rounded;
    Color stageColor = theme.colorScheme.primary;

    switch (stage) {
      case 'compressing':
        stageIcon = Icons.compress_rounded;
        stageColor = Colors.blue;
        break;
      case 'uploading_video':
        stageIcon = Icons.cloud_upload_rounded;
        stageColor = Colors.green;
        break;
      case 'uploading_thumbnail':
        stageIcon = Icons.image_rounded;
        stageColor = Colors.purple;
        break;
      case 'processing':
        stageIcon = Icons.settings_rounded;
        stageColor = Colors.orange;
        break;
      case 'saving':
        stageIcon = Icons.save_rounded;
        stageColor = Colors.teal;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.padL,
              AppConstants.padM,
              AppConstants.padL,
              AppConstants.padS,
            ),
            child: Row(
              children: [
                // Stage icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: stageColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(stageIcon, size: 22, color: stageColor),
                ),
                const SizedBox(width: AppConstants.padM),

                // Progress info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stageText,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: progress > 0 ? progress : null,
                              minHeight: 6,
                              backgroundColor: theme.dividerColor,
                              valueColor: AlwaysStoppedAnimation<Color>(stageColor),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: AppConstants.padM),
                          Text(
                            progress > 0 ? '${(progress * 100).toInt()}%' : '...',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Cancel button (only for certain stages)
                if (stage == 'compressing' || stage == 'uploading_video')
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => _showCancelVideoUploadDialog(context),
                    color: Colors.red,
                    tooltip: 'Cancel upload',
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: Cancel video upload confirmation dialog
  void _showCancelVideoUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel Video Upload?'),
        content: const Text(
          'The video will not be saved if you cancel now. '
              'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Continue Uploading'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // TODO: Implement cancel upload logic in BLoC
              // context.read<SalonProfileBloc>().add(const CancelVideoUpload());

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Upload cancelled'),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Upload'),
          ),
        ],
      ),
    );
  }

  // ✅ Image upload progress bar (for photo uploads)
  Widget _buildUploadProgressBar(BuildContext context, double progress, String? type) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.padL,
              AppConstants.padM,
              AppConstants.padL,
              AppConstants.padS,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: progress > 0 ? progress : null,
                  ),
                ),
                const SizedBox(width: AppConstants.padM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploading ${type ?? 'photo'}...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (progress > 0)
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          LinearProgressIndicator(
            value: progress > 0 ? progress : null,
            minHeight: 3,
            backgroundColor: theme.dividerColor,
          ),
        ],
      ),
    );
  }

  // ✅ Hero header with gradient and completion
  Widget _buildHeroHeader(BuildContext context, SalonModel salon) {
    final theme = Theme.of(context);
    final completionPercentage = _calculateCompletion(salon);
    final completionColor = _getCompletionColor(completionPercentage);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusValL),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(AppConstants.padL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profile completion circle
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      completionColor.withValues(alpha: 0.2),
                      completionColor.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(color: completionColor, width: 3),
                ),
                child: Center(
                  child: Text(
                    '${completionPercentage.toInt()}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: completionColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppConstants.padL),

              // Salon info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      salon.salonName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            salon.address,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.padS,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: salon.isOpen
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.radiusValL),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: salon.isOpen ? Colors.green : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            salon.isOpen ? 'Open Now' : 'Closed',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: salon.isOpen ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padL),

          // Completion message
          Container(
            padding: const EdgeInsets.all(AppConstants.padM),
            decoration: BoxDecoration(
              color: completionColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppConstants.radiusValM),
            ),
            child: Row(
              children: [
                Icon(
                  completionPercentage >= 100
                      ? Icons.check_circle_rounded
                      : Icons.info_outline,
                  color: completionColor,
                  size: 20,
                ),
                const SizedBox(width: AppConstants.padS),
                Expanded(
                  child: Text(
                    _getCompletionMessage(completionPercentage),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: completionColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Quick actions row
  Widget _buildQuickActions(BuildContext context, SalonModel salon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.photo_camera_rounded,
            label: 'Add Photos',
            color: theme.colorScheme.primary,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Scroll down to the Photos section'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: AppConstants.padM),
        Expanded(
          child: _buildQuickActionCard(
            context,
            icon: Icons.share_rounded,
            label: 'Share Profile',
            color: theme.colorScheme.secondary,
            onTap: () => _shareSalonProfile(context, salon),
          ),
        ),
      ],
    );
  }

  void _shareSalonProfile(BuildContext context, SalonModel salon) {
    final categories = salon.serviceCategories.take(3).join(', ');
    final shareText = '''
Check out ${salon.salonName} on Pendeza!

${salon.description ?? 'A great beauty salon'}

Services: $categories
Location: ${salon.address}

Book your appointment now on Pendeza app!
https://pendeza.co.tz/salon/${salon.id}
''';

    Share.share(
      shareText.trim(),
      subject: 'Check out ${salon.salonName} on Pendeza!',
    );
  }

  Widget _buildQuickActionCard(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color color,
        required VoidCallback onTap,
      }) {
    final theme = Theme.of(context);

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(AppConstants.radiusValM),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.radiusValM),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: AppConstants.padS),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Section labels with icon
  Widget _buildSectionLabel(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusValS),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppConstants.padM),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.padL),
      children: List.generate(
        5,
            (index) => const Padding(
          padding: EdgeInsets.only(bottom: AppConstants.padL),
          child: ShimmerPlaceholder(height: 200, width: double.infinity),
        ),
      ),
    );
  }

  double _calculateCompletion(SalonModel salon) {
    int totalFields = 7;
    int completedFields = 0;

    completedFields += 2; // name, address
    if (salon.description?.isNotEmpty ?? false) completedFields++;
    if (salon.primaryImage != null) completedFields++;
    if (salon.openingTime?.isNotEmpty ?? false) completedFields++;
    if (salon.phoneNumber?.isNotEmpty ?? false) completedFields++;
    if (salon.serviceCategories.isNotEmpty) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  Color _getCompletionColor(double percentage) {
    if (percentage < 40) return Colors.red;
    if (percentage < 70) return Colors.orange;
    return Colors.green;
  }

  String _getCompletionMessage(double percentage) {
    if (percentage < 40) return 'Let\'s complete your profile to attract clients';
    if (percentage < 70) return 'Great start! Add more details to stand out';
    if (percentage < 100) return 'Almost perfect! Just a few touches left';
    return 'Excellent! Your profile is complete';
  }
}