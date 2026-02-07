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

/// ✅ FIX: Changed to StatefulWidget to properly manage BLoC lifecycle
/// This prevents the BLoC from being recreated on every rebuild
class SalonProfileScreen extends StatefulWidget {
  const SalonProfileScreen({super.key});

  @override
  State<SalonProfileScreen> createState() => _SalonProfileScreenState();
}

class _SalonProfileScreenState extends State<SalonProfileScreen> {
  /// ✅ FIX: Create bloc instance once and keep it alive
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
    // ✅ FIX: Only load profile once when screen is first shown
    if (!_isInitialized) {
      _salonProfileBloc.add(const LoadSalonProfile());
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    // ✅ FIX: Close the bloc when screen is disposed
    _salonProfileBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Use BlocProvider.value to provide existing instance
    // instead of creating a new one
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salon Profile'),
        elevation: 0,
        actions: [
          // Preview button
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
        // ✅ FIX: Add buildWhen to prevent unnecessary rebuilds
        buildWhen: (previous, current) {
          // Don't rebuild for operation success (handled by listener)
          // This prevents the flicker
          if (current is SalonProfileOperationSuccess) {
            return false;
          }
          return true;
        },
        // ✅ Listen for success and show feedback
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
        },
        builder: (context, state) {
          // ✅ FIX: Only show full loading on initial load
          if (state is SalonProfileInitial) {
            return _buildLoadingState();
          }

          // ✅ FIX: Show loading with existing data if available
          if (state is SalonProfileLoading) {
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
              // ✅ FIX: Better way to wait for refresh
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.all(AppConstants.padL),
                  children: [
                    // ✅ IMPROVED: Hero header with completion
                    _buildHeroHeader(context, salon),
                    const SizedBox(height: AppConstants.padL),

                    // ✅ Quick action cards
                    _buildQuickActions(context, salon),
                    const SizedBox(height: AppConstants.padXL),

                    // Section label
                    _buildSectionLabel(context, 'Basic Information', Icons.info_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonBasicInfoSection(salon: salon),
                    const SizedBox(height: AppConstants.padXL),

                    // Images section with improved label
                    _buildSectionLabel(context, 'Photos', Icons.photo_library_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonImagesSection(salon: salon),
                    const SizedBox(height: AppConstants.padXL),

                    // 🎬 Video Shorts section
                    _buildSectionLabel(context, 'Video Shorts', Icons.videocam_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonVideosSection(videos: _getVideosFromState(state)),
                    const SizedBox(height: AppConstants.padXL),

                    // Business hours
                    _buildSectionLabel(context, 'Operating Hours', Icons.access_time_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonBusinessHoursSection(salon: salon),
                    const SizedBox(height: AppConstants.padXL),

                    // Contact
                    _buildSectionLabel(context, 'Contact & Social', Icons.connect_without_contact_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonContactSection(salon: salon),
                    const SizedBox(height: AppConstants.padXL),

                    // Amenities
                    _buildSectionLabel(context, 'Amenities', Icons.star_rounded),
                    const SizedBox(height: AppConstants.padM),
                    SalonAmenitiesSection(salon: salon),
                    const SizedBox(height: AppConstants.padXXL * 2),
                  ],
                ),

                // ✅ IMPROVED: Upload progress overlay
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

  // ✅ NEW: Hero header with gradient and completion
  Widget _buildHeroHeader(BuildContext context, SalonModel salon) {
    final theme = Theme.of(context);
    final completionPercentage = _calculateCompletion(salon);
    final completionColor = _getCompletionColor(completionPercentage);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusValL),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
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
                      completionColor.withOpacity(0.2),
                      completionColor.withOpacity(0.1),
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
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            salon.address,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
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
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
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
              color: completionColor.withOpacity(0.1),
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

  // ✅ Quick actions row
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
              // Will be handled by the images section
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
      color: color.withOpacity(0.1),
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

  // ✅ NEW: Section labels
  Widget _buildSectionLabel(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
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

  // ✅ IMPROVED: Upload progress bar with animation
  Widget _buildUploadProgressBar(BuildContext context, double progress, String? type) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
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

  Widget _buildLoadingState() {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.padL),
      children: List.generate(
        5,
            (index) => Padding(
          padding: const EdgeInsets.only(bottom: AppConstants.padL),
          child: const ShimmerPlaceholder(height: 200, width: double.infinity),
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