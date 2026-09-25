import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pendeza/app/services/notification_service.dart';
import 'package:pendeza/app/services/service_locator.dart';
import 'package:pendeza/features/5_admin_panel/presentation/widgets/admin_ui.dart';
import 'package:pendeza/shared/widgets/custom_snackbar.dart';

/// Admin Notification Center.
///
/// Features:
/// - Inline notification composer (audience, type, title, body)
/// - Image upload support
/// - Call-to-Action button with custom route
/// - Real-time notification history
/// - Success/failure tracking
class AdminManageNotificationsScreen extends StatefulWidget {
  /// Replaces the Firestore inbox listener. Tests only.
  @visibleForTesting
  final Stream<List<Map<String, dynamic>>>? debugInboxStream;

  const AdminManageNotificationsScreen({super.key, this.debugInboxStream});

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

  // Image state
  File? _selectedImage;
  String? _uploadedImageUrl;

  // Inbox (notification history).
  //
  // A Firestore `snapshots()` stream is a *broadcast* stream: it does not replay
  // its last event to late listeners. The Compose tab's stat tiles subscribed
  // first and consumed the initial snapshot, so a StreamBuilder created later
  // by the History tab waited forever for an event that had already fired.
  // Instead we listen exactly once here and let every tab read the latest value
  // from this notifier, which always holds the current state.
  final ValueNotifier<_InboxState> _inbox =
      ValueNotifier(const _InboxState.loading());
  StreamSubscription<List<Map<String, dynamic>>>? _inboxSub;
  Timer? _inboxSlowTimer;
  static const _inboxSlowAfter = Duration(seconds: 15);

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
    _listenInbox();
  }

  Stream<List<Map<String, dynamic>>> _openInboxStream() {
    final injected = widget.debugInboxStream;
    if (injected != null) return injected;
    return FirebaseFirestore.instance
        .collection('notification_inbox')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  void _listenInbox() {
    _inboxSub?.cancel();
    _inboxSlowTimer?.cancel();
    _inbox.value = const _InboxState.loading();

    // If nothing arrives (offline, blocked by App Check, …) say so instead of
    // showing a skeleton forever. A late event still replaces the error.
    _inboxSlowTimer = Timer(_inboxSlowAfter, () {
      if (mounted && _inbox.value.loading) {
        _inbox.value = const _InboxState.error(
          'This is taking longer than expected. Check your connection and try again.',
        );
      }
    });

    _inboxSub = _openInboxStream().listen(
      (items) {
        _inboxSlowTimer?.cancel();
        _inbox.value = _InboxState.data(items);
      },
      onError: (Object error) {
        _inboxSlowTimer?.cancel();
        _inbox.value = _InboxState.error(_friendlyInboxError(error));
      },
    );
  }

  String _friendlyInboxError(Object error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'You don’t have permission to read notification history.';
      }
      if (error.code == 'unavailable') {
        return 'Can’t reach the server right now. Check your connection.';
      }
      return error.message ?? error.code;
    }
    return error.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _actionLabelController.dispose();
    _actionRouteController.dispose();
    _tabController.dispose();
    _inboxSub?.cancel();
    _inboxSlowTimer?.cancel();
    _inbox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Notifications',
      subtitle: 'Send push messages to users',
      icon: CupertinoIcons.bell_fill,
      toolbar: AdminSegmentedTabBar(
        controller: _tabController,
        tabs: const [
          (label: 'Compose', icon: CupertinoIcons.pencil),
          (label: 'History', icon: CupertinoIcons.clock),
        ],
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _CenteredColumn(child: _buildComposerTab(context)),
          _CenteredColumn(child: _buildHistoryTab(context)),
        ],
      ),
    );
  }

  // ==================== COMPOSER TAB ====================
  Widget _buildComposerTab(BuildContext context) {
    final gutter = AdminTheme.gutter(MediaQuery.sizeOf(context).width);

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildQuickStats(context),
          const SizedBox(height: 16),
          AdminCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AdminSectionHeader(
                  title: 'Compose notification',
                  subtitle: 'Reach your users instantly',
                ),
                const SizedBox(height: 22),
                _buildAudienceSection(context),
                const SizedBox(height: 22),
                _buildTypeSection(context),
                const SizedBox(height: 22),
                _buildTitleInput(context),
                const SizedBox(height: 16),
                _buildBodyInput(context),
                const SizedBox(height: 22),
                _buildImageSection(context),
                const SizedBox(height: 22),
                _buildActionSection(context),
                const SizedBox(height: 26),
                _buildSendButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldLabel(
    BuildContext context,
    String text, {
    String? helper,
    String? badge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              text,
              style: AdminTheme.body(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            if (badge != null) ...[
              const SizedBox(width: 8),
              AdminPill(label: badge, tone: AdminTone.info),
            ],
          ],
        ),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(helper, style: AdminTheme.caption(context)),
        ],
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildAudienceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Target audience'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AdminFilterChip(
              label: 'Everyone',
              icon: CupertinoIcons.person_3_fill,
              selected: _targetAudience == 'all',
              onTap: () => setState(() => _targetAudience = 'all'),
            ),
            AdminFilterChip(
              label: 'Clients only',
              icon: CupertinoIcons.person_fill,
              tone: AdminTone.success,
              selected: _targetAudience == 'clients',
              onTap: () => setState(() => _targetAudience = 'clients'),
            ),
            AdminFilterChip(
              label: 'Salon owners',
              icon: CupertinoIcons.briefcase_fill,
              tone: AdminTone.info,
              selected: _targetAudience == 'owners',
              onTap: () => setState(() => _targetAudience = 'owners'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeSection(BuildContext context) {
    Widget chip(String value, String label, IconData icon) => AdminFilterChip(
          label: label,
          icon: icon,
          selected: _notificationType == value,
          onTap: () => setState(() => _notificationType = value),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Notification type'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('general', 'General', CupertinoIcons.bell),
            chip('promotion', 'Promotion', CupertinoIcons.tag),
            chip('appointment', 'Appointment', CupertinoIcons.calendar),
            chip('system', 'System', CupertinoIcons.gear),
          ],
        ),
      ],
    );
  }

  Widget _buildTitleInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Title *'),
        TextField(
          controller: _titleController,
          maxLength: 60,
          style: AdminTheme.body(context),
          decoration: const InputDecoration(
            hintText: 'e.g., New feature available!',
            prefixIcon: Icon(CupertinoIcons.textformat, size: 20),
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  Widget _buildBodyInput(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(context, 'Message *'),
        TextField(
          controller: _bodyController,
          maxLines: 4,
          maxLength: 500,
          style: AdminTheme.body(context),
          decoration: const InputDecoration(
            hintText: 'Write your notification message here…',
          ),
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // Image Section
  Widget _buildImageSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(
          context,
          'Image',
          helper: 'Make the notification more engaging',
          badge: 'Optional',
        ),
        if (_selectedImage != null || _uploadedImageUrl != null)
          _buildImagePreview(context)
        else
          _buildImagePicker(context),
      ],
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    return InkWell(
      onTap: _pickImage,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 124,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AdminTheme.inset(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.border(context)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AdminIconTile(
              icon: CupertinoIcons.photo_on_rectangle,
              size: 44,
            ),
            const SizedBox(height: 10),
            Text('Tap to add an image', style: AdminTheme.body(context)),
            Text('JPG or PNG, up to 2 MB', style: AdminTheme.caption(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _selectedImage != null
              ? Image.file(
                  _selectedImage!,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.network(
                  _uploadedImageUrl!,
                  height: 170,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
        // Upload indicator
        if (_isUploadingImage)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
        // Remove button
        Positioned(
          top: 10,
          right: 10,
          child: IconButton(
            tooltip: 'Remove image',
            onPressed: _removeImage,
            icon: const Icon(CupertinoIcons.xmark, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: AdminTheme.card(context),
              foregroundColor: AdminTheme.toneInk(context, AdminTone.danger),
            ),
          ),
        ),
      ],
    );
  }

  // Call-to-Action Section
  Widget _buildActionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(
          context,
          'Call-to-action',
          helper: 'Add a button that opens a specific screen',
          badge: 'Optional',
        ),

        // Button Label
        TextField(
          controller: _actionLabelController,
          style: AdminTheme.body(context),
          decoration: const InputDecoration(
            hintText: 'Button text (e.g., "Book Now", "View Offer")',
            prefixIcon: Icon(CupertinoIcons.hand_point_right, size: 20),
          ),
        ),
        const SizedBox(height: 12),

        // Route Dropdown
        DropdownButtonFormField<String>(
          initialValue: _actionRouteController.text.isEmpty
              ? ''
              : (_predefinedRoutes
                      .any((r) => r['route'] == _actionRouteController.text)
                  ? _actionRouteController.text
                  : 'custom'),
          isExpanded: true,
          style: AdminTheme.body(context),
          decoration: const InputDecoration(
            labelText: 'Destination screen',
            prefixIcon: Icon(CupertinoIcons.link, size: 20),
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
            !_predefinedRoutes
                .any((r) => r['route'] == _actionRouteController.text))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextField(
              controller: _actionRouteController,
              style: AdminTheme.body(context),
              decoration: const InputDecoration(
                hintText: 'Custom route (e.g., /salon/abc123)',
                prefixIcon: Icon(CupertinoIcons.doc_text, size: 20),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSendButton(BuildContext context) {
    final isValid = _titleController.text.trim().isNotEmpty &&
        _bodyController.text.trim().isNotEmpty;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isValid && !_isSending ? _sendNotification : null,
        style: AdminTheme.filledButton(context)
            .copyWith(minimumSize: const WidgetStatePropertyAll(Size(0, 52))),
        icon: _isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(CupertinoIcons.paperplane_fill, size: 18),
        label: Text(_isSending ? 'Sending…' : 'Send notification'),
      ),
    );
  }

  // ==================== HISTORY TAB ====================
  Widget _buildHistoryTab(BuildContext context) {
    return ValueListenableBuilder<_InboxState>(
      valueListenable: _inbox,
      builder: (context, inbox, _) {
        if (inbox.loading) {
          return const AdminLoadingState(itemHeight: 120, count: 4);
        }

        if (inbox.error != null) {
          return AdminEmptyState(
            icon: CupertinoIcons.exclamationmark_triangle_fill,
            tone: AdminTone.danger,
            title: 'Couldn’t load history',
            message: inbox.error,
            actionLabel: 'Try again',
            onAction: _listenInbox,
          );
        }

        if (inbox.items.isEmpty) {
          return const AdminEmptyState(
            icon: CupertinoIcons.bell_slash,
            title: 'No notifications sent yet',
            message: 'Messages you send will show up here with their status.',
          );
        }

        final gutter = AdminTheme.gutter(MediaQuery.sizeOf(context).width);
        return RefreshIndicator(
          onRefresh: () async => _listenInbox(),
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
            itemCount: inbox.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildNotificationHistoryCard(context, inbox.items[index]),
          ),
        );
      },
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return ValueListenableBuilder<_InboxState>(
      valueListenable: _inbox,
      builder: (context, inbox, _) {
        final reached = inbox.items.fold<int>(
          0,
          (total, n) => total + _analyticsCount(n, 'sent'),
        );

        return Row(
          children: [
            Expanded(
              child: AdminStatTile(
                icon: CupertinoIcons.paperplane_fill,
                label: 'Recent broadcasts',
                value: inbox.loading ? '–' : '${inbox.items.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminStatTile(
                icon: CupertinoIcons.checkmark_circle_fill,
                label: 'Devices reached',
                value: inbox.loading ? '–' : '$reached',
                tone: AdminTone.success,
              ),
            ),
          ],
        );
      },
    );
  }

  /// `analytics.sent` / `analytics.failed` as written by the Cloud Function.
  int _analyticsCount(Map<String, dynamic> notif, String key) {
    final analytics = notif['analytics'];
    if (analytics is Map && analytics[key] is num) {
      return (analytics[key] as num).toInt();
    }
    return 0;
  }

  Widget _buildNotificationHistoryCard(
    BuildContext context,
    Map<String, dynamic> notif,
  ) {
    final title = notif['title'] as String? ?? 'Untitled';
    final body = notif['body'] as String? ?? '';
    final sentAt = (notif['sentAt'] as Timestamp?)?.toDate();
    final targetAudience = notif['targetAudience'] as String? ?? 'unknown';
    final imageUrl = notif['imageUrl'] as String?;
    // The composer sends the CTA label inside `customData`.
    final customData = notif['customData'];
    final actionLabel = (notif['actionLabel'] as String?) ??
        (customData is Map ? customData['actionLabel'] as String? : null);

    // Delivery: the Cloud Function stores counts under `analytics`; older
    // documents used a plain `delivered` flag; topic sends store neither.
    final sentCount = _analyticsCount(notif, 'sent');
    final failedCount = _analyticsCount(notif, 'failed');
    final legacyDelivered = notif['delivered'] == true;
    final String deliveryLabel;
    final AdminTone deliveryTone;
    final IconData deliveryIcon;
    if (sentCount > 0 || legacyDelivered) {
      deliveryLabel = sentCount > 0 ? 'Sent to $sentCount' : 'Delivered';
      deliveryTone = AdminTone.success;
      deliveryIcon = CupertinoIcons.checkmark_circle_fill;
    } else if (failedCount > 0) {
      deliveryLabel = 'Failed';
      deliveryTone = AdminTone.danger;
      deliveryIcon = CupertinoIcons.xmark_circle_fill;
    } else {
      deliveryLabel = 'Sent';
      deliveryTone = AdminTone.info;
      deliveryIcon = CupertinoIcons.paperplane_fill;
    }

    final IconData audienceIcon;
    final AdminTone audienceTone;
    final String audienceLabel;
    switch (targetAudience) {
      case 'clients':
        audienceIcon = CupertinoIcons.person_fill;
        audienceTone = AdminTone.success;
        audienceLabel = 'Clients';
        break;
      case 'owners':
        audienceIcon = CupertinoIcons.briefcase_fill;
        audienceTone = AdminTone.info;
        audienceLabel = 'Salon owners';
        break;
      default:
        audienceIcon = CupertinoIcons.person_3_fill;
        audienceTone = AdminTone.primary;
        audienceLabel = targetAudience.startsWith('topic:')
            ? 'Topic · ${targetAudience.substring(6)}'
            : 'Everyone';
    }

    return AdminCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AdminIconTile(icon: audienceIcon, tone: audienceTone, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AdminTheme.body(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(audienceLabel, style: AdminTheme.caption(context)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AdminPill(
                label: deliveryLabel,
                tone: deliveryTone,
                icon: deliveryIcon,
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              body,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AdminTheme.body(context).copyWith(
                fontWeight: FontWeight.w400,
                color: AdminTheme.textSecondary(context),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                const AdminPill(
                  label: 'Has image',
                  tone: AdminTone.info,
                  icon: CupertinoIcons.photo,
                ),
              if (actionLabel != null && actionLabel.isNotEmpty)
                AdminPill(
                  label: 'CTA: $actionLabel',
                  tone: AdminTone.success,
                  icon: CupertinoIcons.hand_point_right,
                ),
              if (failedCount > 0 && sentCount > 0)
                AdminPill(
                  label: '$failedCount failed',
                  tone: AdminTone.warning,
                  icon: CupertinoIcons.exclamationmark_triangle_fill,
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.clock,
                    size: 13,
                    color: AdminTheme.textSecondary(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sentAt != null ? _formatDateTime(sentAt) : 'Unknown time',
                    style: AdminTheme.caption(context),
                  ),
                ],
              ),
            ],
          ),
        ],
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
      builder: (dialogContext) => AdminDialogFrame(
        icon: CupertinoIcons.link,
        title: 'Custom route',
        message: 'Enter the in-app path the button should open.',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style:
                AdminTheme.textButton(dialogContext, tone: AdminTone.neutral),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {});
            },
            style: AdminTheme.filledButton(dialogContext),
            child: const Text('Save'),
          ),
        ],
        child: TextField(
          controller: _actionRouteController,
          autofocus: true,
          style: AdminTheme.body(dialogContext),
          decoration: const InputDecoration(
            hintText: 'e.g., /salon/abc123',
            labelText: 'Route path',
          ),
        ),
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
        CustomSnackBar.show(
          context,
          message: 'Notification sent successfully!',
          type: SnackBarType.success,
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
    if (!mounted) return;
    CustomSnackBar.show(
      context,
      message: message,
      type: SnackBarType.error,
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

/// Keeps form-like content readable on wide screens.
class _CenteredColumn extends StatelessWidget {
  final Widget child;
  const _CenteredColumn({required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: child,
      ),
    );
  }
}

/// Latest known state of the notification inbox.
class _InboxState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;

  const _InboxState.loading()
      : loading = true,
        error = null,
        items = const [];

  const _InboxState.error(String this.error)
      : loading = false,
        items = const [];

  const _InboxState.data(this.items)
      : loading = false,
        error = null;
}
