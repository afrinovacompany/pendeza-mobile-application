import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/services/notification_service.dart';
import 'package:pendeza/app/services/service_locator.dart';

/// Enhanced Admin Notification Management Screen
///
/// Features:
/// - Clean, card-based UI
/// - Inline notification composer
/// - 🆕 Image upload support
/// - 🆕 Call-to-Action button with custom route
/// - Real-time notification history
/// - Success/failure tracking
/// - Target audience selection
class AdminManageNotificationsScreen extends StatefulWidget {
  const AdminManageNotificationsScreen({super.key});

  @override
  State<AdminManageNotificationsScreen> createState() =>
      _AdminManageNotificationsScreenState();
}

class _AdminManageNotificationsScreenState
    extends State<AdminManageNotificationsScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _actionLabelController = TextEditingController();
  final _actionRouteController = TextEditingController();

  // State
  String _targetAudience = 'all';
  String _notificationType = 'general';
  bool _isSending = false;
  bool _isUploadingImage = false;
  late TabController _tabController;

  // 🆕 Image state
  File? _selectedImage;
  String? _uploadedImageUrl;

  // Streams
  Stream<QuerySnapshot>? _sentNotificationsStream;

  // Predefined action routes
  final List<Map<String, String>> _predefinedRoutes = [
    {'label': 'None', 'route': ''},
    {'label': 'Home / Dashboard', 'route': '/client/dashboard'},
    {'label': 'Discover Salons', 'route': '/client/discover'},
    {'label': 'My Appointments', 'route': '/client/appointments'},
    {'label': 'My Wallet', 'route': '/client/wallet'},
    {'label': 'Favorites', 'route': '/client/favorites'},
    {'label': 'Profile', 'route': '/client/profile'},
    {'label': 'Custom...', 'route': 'custom'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initStreams();
  }

  void _initStreams() {
    _sentNotificationsStream = FirebaseFirestore.instance
        .collection('notification_inbox')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _actionLabelController.dispose();
    _actionRouteController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Center'),
        backgroundColor:
        isDark ? AppColors.darkSurfaceVariant : theme.colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Compose', icon: Icon(CupertinoIcons.pencil, size: 20)),
            Tab(text: 'History', icon: Icon(CupertinoIcons.clock, size: 20)),
          ],
        ),
      ),
      backgroundColor: isDark
          ? AppColors.darkBackground
          : theme.scaffoldBackgroundColor.withAlpha(245),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildComposerTab(theme, isDark),
          _buildHistoryTab(theme, isDark),
        ],
      ),
    );
  }

  // ==================== COMPOSER TAB ====================
  Widget _buildComposerTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.padL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick Stats
          _buildQuickStats(theme, isDark),
          const SizedBox(height: AppConstants.padXL),

          // Composer Card
          Card(
            elevation: isDark ? 2 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: AppConstants.radiusL,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.padL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildComposerHeader(theme),
                  const SizedBox(height: AppConstants.padL),
                  const Divider(),
                  const SizedBox(height: AppConstants.padL),

                  // Target Audience
                  _buildAudienceSection(theme, isDark),
                  const SizedBox(height: AppConstants.padXL),

                  // Notification Type
                  _buildTypeSection(theme, isDark),
                  const SizedBox(height: AppConstants.padXL),

                  // Title Input
                  _buildTitleInput(theme),
                  const SizedBox(height: AppConstants.padL),

                  // Body Input
                  _buildBodyInput(theme),
                  const SizedBox(height: AppConstants.padXL),

                  // 🆕 Image Section
                  _buildImageSection(theme, isDark),
                  const SizedBox(height: AppConstants.padXL),

                  // 🆕 Call-to-Action Section
                  _buildActionSection(theme, isDark),
                  const SizedBox(height: AppConstants.padXL),

                  // Send Button
                  _buildSendButton(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposerHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppConstants.padS),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: AppConstants.radiusS,
          ),
          child: const Icon(
            CupertinoIcons.bell_fill,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: AppConstants.padM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send Push Notification',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Reach your users instantly',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudienceSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Target Audience',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.padM),
        Wrap(
          spacing: AppConstants.padM,
          runSpacing: AppConstants.padS,
          children: [
            _buildAudienceChip(
              label: 'Everyone',
              value: 'all',
              icon: CupertinoIcons.person_3_fill,
              color: AppColors.primary,
              theme: theme,
              isDark: isDark,
            ),
            _buildAudienceChip(
              label: 'Clients Only',
              value: 'clients',
              icon: CupertinoIcons.person_fill,
              color: AppColors.success,
              theme: theme,
              isDark: isDark,
            ),
            _buildAudienceChip(
              label: 'Salon Owners',
              value: 'owners',
              icon: CupertinoIcons.briefcase_fill,
              color: AppColors.accent2,
              theme: theme,
              isDark: isDark,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAudienceChip({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required ThemeData theme,
    required bool isDark,
  }) {
    final isSelected = _targetAudience == value;

    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _targetAudience = value);
      },
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : color,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade100,
      selectedColor: color,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? color : Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildTypeSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Type',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.padM),
        Wrap(
          spacing: AppConstants.padS,
          runSpacing: AppConstants.padS,
          children: [
            _buildTypeChip('general', 'General', CupertinoIcons.bell, theme),
            _buildTypeChip(
                'promotion', 'Promotion', CupertinoIcons.tag, theme),
            _buildTypeChip(
                'appointment', 'Appointment', CupertinoIcons.calendar, theme),
            _buildTypeChip('system', 'System', CupertinoIcons.gear, theme),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(
      String value, String label, IconData icon, ThemeData theme) {
    final isSelected = _notificationType == value;

    return ChoiceChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _notificationType = value);
      },
      avatar: Icon(icon, size: 16),
      label: Text(label),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTitleInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notification Title *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.padS),
        TextField(
          controller: _titleController,
          maxLength: 60,
          decoration: InputDecoration(
            hintText: 'e.g., New Feature Available!',
            prefixIcon: const Icon(CupertinoIcons.textformat),
            border: OutlineInputBorder(
              borderRadius: AppConstants.radiusM,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildBodyInput(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Message Body *',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.padS),
        TextField(
          controller: _bodyController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'Write your notification message here...',
            prefixIcon: const Padding(
              padding: EdgeInsets.only(bottom: 60),
              child: Icon(CupertinoIcons.text_alignleft),
            ),
            border: OutlineInputBorder(
              borderRadius: AppConstants.radiusM,
            ),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // 🆕 Image Section
  Widget _buildImageSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Image (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'NEW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.info,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.padS),
        Text(
          'Add an image to make your notification more engaging',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppConstants.padM),

        // Image Preview or Picker
        if (_selectedImage != null || _uploadedImageUrl != null)
          _buildImagePreview(theme)
        else
          _buildImagePicker(theme, isDark),
      ],
    );
  }

  Widget _buildImagePicker(ThemeData theme, bool isDark) {
    return InkWell(
      onTap: _pickImage,
      borderRadius: AppConstants.radiusM,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
          borderRadius: AppConstants.radiusM,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo_on_rectangle,
              size: 32,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add image',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            Text(
              'JPG, PNG (max 2MB)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(ThemeData theme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: AppConstants.radiusM,
          child: _selectedImage != null
              ? Image.file(
            _selectedImage!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          )
              : Image.network(
            _uploadedImageUrl!,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        // Upload indicator
        if (_isUploadingImage)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: AppConstants.radiusM,
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        // Remove button
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: _removeImage,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.xmark,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 🆕 Call-to-Action Section
  Widget _buildActionSection(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Call-to-Action (Optional)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'NEW',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.padS),
        Text(
          'Add a button that takes users to a specific screen',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: AppConstants.padM),

        // Button Label
        TextField(
          controller: _actionLabelController,
          decoration: InputDecoration(
            hintText: 'Button text (e.g., "Book Now", "View Offer")',
            prefixIcon: const Icon(CupertinoIcons.hand_point_right),
            border: OutlineInputBorder(
              borderRadius: AppConstants.radiusM,
            ),
          ),
        ),
        const SizedBox(height: AppConstants.padM),

        // Route Dropdown
        DropdownButtonFormField<String>(
          value: _actionRouteController.text.isEmpty
              ? ''
              : (_predefinedRoutes
              .any((r) => r['route'] == _actionRouteController.text)
              ? _actionRouteController.text
              : 'custom'),
          decoration: InputDecoration(
            labelText: 'Destination Screen',
            prefixIcon: const Icon(CupertinoIcons.link),
            border: OutlineInputBorder(
              borderRadius: AppConstants.radiusM,
            ),
          ),
          items: _predefinedRoutes.map((route) {
            return DropdownMenuItem<String>(
              value: route['route'],
              child: Text(route['label']!),
            );
          }).toList(),
          onChanged: (value) {
            if (value == 'custom') {
              _showCustomRouteDialog();
            } else {
              setState(() {
                _actionRouteController.text = value ?? '';
              });
            }
          },
        ),

        // Custom route input (if custom selected)
        if (_actionRouteController.text.isNotEmpty &&
            !_predefinedRoutes.any((r) => r['route'] == _actionRouteController.text))
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.padM),
            child: TextField(
              controller: _actionRouteController,
              decoration: InputDecoration(
                hintText: 'Custom route (e.g., /salon/abc123)',
                prefixIcon: const Icon(CupertinoIcons.doc_text),
                border: OutlineInputBorder(
                  borderRadius: AppConstants.radiusM,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    final isValid = _titleController.text.trim().isNotEmpty &&
        _bodyController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isValid && !_isSending ? _sendNotification : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppConstants.radiusM,
          ),
          elevation: 2,
        ),
        child: _isSending
            ? const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.paperplane_fill),
            const SizedBox(width: 12),
            Text(
              'Send Notification',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HISTORY TAB ====================
  Widget _buildHistoryTab(ThemeData theme, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _sentNotificationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.bell_slash,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications sent yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.padL),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildNotificationHistoryCard(data, theme, isDark);
          },
        );
      },
    );
  }

  Widget _buildQuickStats(ThemeData theme, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _sentNotificationsStream,
      builder: (context, snapshot) {
        final totalSent = snapshot.data?.docs.length ?? 0;
        final delivered = snapshot.data?.docs
            .where((d) => (d.data() as Map)['delivered'] == true)
            .length ??
            0;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Sent',
                totalSent.toString(),
                CupertinoIcons.paperplane,
                AppColors.primary,
                theme,
                isDark,
              ),
            ),
            const SizedBox(width: AppConstants.padM),
            Expanded(
              child: _buildStatCard(
                'Delivered',
                delivered.toString(),
                CupertinoIcons.checkmark_circle,
                AppColors.success,
                theme,
                isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      Color color,
      ThemeData theme,
      bool isDark,
      ) {
    return Card(
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.radiusM),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppConstants.padS),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: AppConstants.radiusS,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: AppConstants.padM),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationHistoryCard(
      Map<String, dynamic> notif,
      ThemeData theme,
      bool isDark,
      ) {
    final title = notif['title'] as String? ?? 'Untitled';
    final body = notif['body'] as String? ?? '';
    final sentAt = (notif['sentAt'] as Timestamp?)?.toDate();
    final targetAudience = notif['targetAudience'] as String? ?? 'unknown';
    final delivered = notif['delivered'] as bool? ?? false;
    final imageUrl = notif['imageUrl'] as String?;
    final actionLabel = notif['actionLabel'] as String?;

    IconData audienceIcon;
    Color audienceColor;
    switch (targetAudience) {
      case 'clients':
        audienceIcon = CupertinoIcons.person_fill;
        audienceColor = AppColors.success;
        break;
      case 'owners':
        audienceIcon = CupertinoIcons.briefcase_fill;
        audienceColor = AppColors.accent2;
        break;
      default:
        audienceIcon = CupertinoIcons.person_3_fill;
        audienceColor = AppColors.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.padM),
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.radiusM,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : Colors.grey.shade200,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.padL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppConstants.padXS),
                  decoration: BoxDecoration(
                    color: audienceColor.withOpacity(0.1),
                    borderRadius: AppConstants.radiusS,
                  ),
                  child: Icon(audienceIcon, size: 16, color: audienceColor),
                ),
                const SizedBox(width: AppConstants.padS),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.padS,
                    vertical: AppConstants.padXXS,
                  ),
                  decoration: BoxDecoration(
                    color: delivered
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.warning.withOpacity(0.1),
                    borderRadius: AppConstants.radiusS,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        delivered
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.clock_fill,
                        size: 12,
                        color: delivered ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        delivered ? 'Delivered' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: delivered ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.padS),

            // Body
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // Image preview
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: AppConstants.padS),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.photo,
                    size: 14,
                    color: AppColors.info,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Has image',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
            ],

            // Action label
            if (actionLabel != null && actionLabel.isNotEmpty) ...[
              const SizedBox(height: AppConstants.padXS),
              Row(
                children: [
                  Icon(
                    CupertinoIcons.hand_point_right,
                    size: 14,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'CTA: $actionLabel',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppConstants.padS),

            // Footer
            Row(
              children: [
                Icon(
                  CupertinoIcons.clock,
                  size: 14,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  sentAt != null ? _formatDateTime(sentAt) : 'Unknown time',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _uploadedImageUrl = null;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _uploadedImageUrl = null;
    });
  }

  void _showCustomRouteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Route'),
        content: TextField(
          controller: _actionRouteController,
          decoration: const InputDecoration(
            hintText: 'e.g., /salon/abc123',
            labelText: 'Route path',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return _uploadedImageUrl;

    setState(() => _isUploadingImage = true);

    try {
      final fileName =
          'notification_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('notification_images')
          .child(fileName);

      await ref.putFile(_selectedImage!);
      final url = await ref.getDownloadURL();

      setState(() {
        _uploadedImageUrl = url;
        _isUploadingImage = false;
      });

      return url;
    } catch (e) {
      setState(() => _isUploadingImage = false);
      _showErrorSnackbar('Failed to upload image: $e');
      return null;
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      _showErrorSnackbar('Please fill in both title and message');
      return;
    }

    setState(() => _isSending = true);

    try {
      // Upload image first if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      }

      final notificationService = sl<NotificationService>();

      // Build extra data
      Map<String, dynamic>? data;
      if (_actionRouteController.text.isNotEmpty ||
          _actionLabelController.text.isNotEmpty ||
          imageUrl != null) {
        data = {
          if (_actionRouteController.text.isNotEmpty)
            'route': _actionRouteController.text,
          if (_actionLabelController.text.isNotEmpty)
            'actionLabel': _actionLabelController.text,
          if (imageUrl != null) 'imageUrl': imageUrl,
          'type': _notificationType,
        };
      }

      await notificationService.sendNotificationToRole(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        role: _targetAudience == 'all' ? null : _targetAudience,
        data: data,
      );

      // Clear form
      _titleController.clear();
      _bodyController.clear();
      _actionLabelController.clear();
      _actionRouteController.clear();
      setState(() {
        _targetAudience = 'all';
        _notificationType = 'general';
        _selectedImage = null;
        _uploadedImageUrl = null;
      });

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white),
                SizedBox(width: 12),
                Text('Notification sent successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Switch to history tab
        _tabController.animateTo(1);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to send notification: $e');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(CupertinoIcons.exclamationmark_circle_fill,
                color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return DateFormat('MMM d, y').format(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
