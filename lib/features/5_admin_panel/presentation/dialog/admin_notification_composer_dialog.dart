import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/shared/widgets/text_form_field.dart';

// You'll need to create this widget file next
import '../widgets/notification_preview_widget.dart';



// Import the notification preview widget

class AdminNotificationComposerDialog extends StatefulWidget {
  const AdminNotificationComposerDialog({super.key});

  @override
  State<AdminNotificationComposerDialog> createState() =>
      _AdminNotificationComposerDialogState();
}

class _AdminNotificationComposerDialogState
    extends State<AdminNotificationComposerDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Form Controllers
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _routeController = TextEditingController();
  final _promoCodeController = TextEditingController();
  final _discountController = TextEditingController();

  // Form State
  String _targetAudience = 'all';
  String _priority = 'high';
  bool _saveToInbox = true;
  XFile? _image;
  bool _isLoading = false;
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _routeController.dispose();
    _promoCodeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _image = image);
    }
  }

  Future<String?> _uploadImage() async {
    if (_image == null) return null;

    try {
      final fileName = 'notification_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref('notifications').child(fileName);
      await ref.putFile(File(_image!.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Upload image if selected
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage();
      }

      // Build custom data
      final customData = <String, String>{};
      if (_promoCodeController.text.isNotEmpty) {
        customData['promoCode'] = _promoCodeController.text;
      }
      if (_discountController.text.isNotEmpty) {
        customData['discount'] = _discountController.text;
      }

      // Call Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable(
        'send_admin_notification',
      );

      final result = await callable.call({
        'title': _titleController.text,
        'body': _bodyController.text,
        'imageUrl': imageUrl,
        'targetAudience': _targetAudience,
        'route': _routeController.text.isNotEmpty
            ? _routeController.text
            : null,
        'customData': customData.isNotEmpty ? customData : null,
        'priority': _priority,
        'saveToInbox': _saveToInbox,
      });

      if (mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  CupertinoIcons.checkmark_circle_fill,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Notification Sent!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Delivered to ${result.data['analytics']['sent']} users',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppConstants.radiusM,
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppConstants.radiusM,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: screenSize.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurfaceVariant : Colors.white,
            borderRadius: AppConstants.radiusXL,
            boxShadow: isDark ? AppColors.darkShadowLg : AppColors.lightShadowLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              _buildHeader(theme, isDark),

              // Content
              Expanded(
                child: Row(
                  children: [
                    // Form Section
                    Expanded(
                      flex: _showPreview ? 1 : 2,
                      child: _buildFormSection(theme, isDark),
                    ),

                    // Preview Section
                    if (_showPreview)
                      Expanded(
                        child: _buildPreviewSection(theme, isDark),
                      ),
                  ],
                ),
              ),

              // Footer
              _buildFooter(theme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: AppConstants.radiusM,
            ),
            child: const Icon(
              CupertinoIcons.bell_fill,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppConstants.padM),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send Notification',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Reach your users instantly',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.padL),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Upload
            _buildImageUpload(theme, isDark),
            const SizedBox(height: AppConstants.padL),

            // Title
            Text(
              'Notification Content',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.padS),
            CustomTextFormField(
              controller: _titleController,
              labelText: 'Title *',
              hintText: 'e.g., Summer Sale! 🌞',
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppConstants.padM),

            // Body
            CustomTextFormField(
              controller: _bodyController,
              labelText: 'Message *',
              hintText: 'e.g., Get 30% off all spa treatments',
              maxLines: 3,
              validator: (v) => v?.isEmpty == true ? 'Required' : null,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppConstants.padL),

            // Target Audience
            Text(
              'Target Audience',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.padS),
            _buildAudienceSelector(theme, isDark),
            const SizedBox(height: AppConstants.padL),

            // Advanced Options
            _buildExpandableSection(
              title: 'Advanced Options',
              theme: theme,
              isDark: isDark,
              children: [
                // Deep Link
                TextFormField(
                  controller: _routeController,
                  decoration: InputDecoration(
                    labelText: 'Deep Link (Optional)',
                    hintText: '/client/promotions/summer',
                    prefixIcon: const Icon(CupertinoIcons.link, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: AppConstants.radiusM,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.padM),
                // Promo Code
                TextFormField(
                  controller: _promoCodeController,
                  decoration: InputDecoration(
                    labelText: 'Promo Code (Optional)',
                    hintText: 'e.g., SUMMER30',
                    prefixIcon: const Icon(CupertinoIcons.tag, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: AppConstants.radiusM,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.padM),
                // Discount
                TextFormField(
                  controller: _discountController,
                  decoration: InputDecoration(
                    labelText: 'Discount % (Optional)',
                    hintText: 'e.g., 30',
                    prefixIcon: const Icon(CupertinoIcons.percent, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: AppConstants.radiusM,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppConstants.padM),
                // Priority
                DropdownButtonFormField<String>(
                  value: _priority,
                  decoration: InputDecoration(
                    labelText: 'Priority',
                    prefixIcon: const Icon(CupertinoIcons.flag, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: AppConstants.radiusM,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'high',
                      child: Text('High Priority'),
                    ),
                    DropdownMenuItem(
                      value: 'normal',
                      child: Text('Normal Priority'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _priority = v!),
                ),
                const SizedBox(height: AppConstants.padM),
                CheckboxListTile(
                  value: _saveToInbox,
                  onChanged: (v) => setState(() => _saveToInbox = v!),
                  title: const Text('Save to notification history'),
                  subtitle: const Text('Store in database for in-app display'),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUpload(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkSurface
              : Colors.grey.shade100,
          borderRadius: AppConstants.radiusM,
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 2,
            style: BorderStyle.solid,
          ),
          image: _image != null
              ? DecorationImage(
            image: FileImage(File(_image!.path)),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: _image == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.photo_on_rectangle,
              size: 40,
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              'Add promotional image (optional)',
              style: TextStyle(
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : Colors.grey,
              ),
            ),
          ],
        )
            : Stack(
          children: [
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(CupertinoIcons.xmark_circle_fill),
                color: Colors.white,
                onPressed: () => setState(() => _image = null),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudienceSelector(ThemeData theme, bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildAudienceChip(
          'all',
          'All Users',
          CupertinoIcons.globe,
          AppColors.primary,
          theme,
          isDark,
        ),
        _buildAudienceChip(
          'clients',
          'Clients Only',
          CupertinoIcons.person_2_fill,
          AppColors.success,
          theme,
          isDark,
        ),
        _buildAudienceChip(
          'owners',
          'Owners Only',
          CupertinoIcons.building_2_fill,
          AppColors.accent2,
          theme,
          isDark,
        ),
      ],
    );
  }

  Widget _buildAudienceChip(
      String value,
      String label,
      IconData icon,
      Color color,
      ThemeData theme,
      bool isDark,
      ) {
    final isSelected = _targetAudience == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? color : null),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _targetAudience = value);
        }
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      backgroundColor: isDark
          ? AppColors.darkSurface
          : Colors.grey.shade100,
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required ThemeData theme,
    required bool isDark,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.padM),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildPreviewSection(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
        border: Border(
          left: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.padM),
            child: Text(
              'Preview',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: NotificationPreviewWidget(
                title: _titleController.text.isNotEmpty
                    ? _titleController.text
                    : 'Notification Title',
                body: _bodyController.text.isNotEmpty
                    ? _bodyController.text
                    : 'Your message will appear here',
                imageUrl: _image?.path,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkSurface
            : Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () {
              setState(() => _showPreview = !_showPreview);
            },
            icon: Icon(
              _showPreview
                  ? CupertinoIcons.eye_slash
                  : CupertinoIcons.eye,
            ),
            label: Text(_showPreview ? 'Hide Preview' : 'Show Preview'),
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: AppConstants.padS),
          PrimaryGradientButton(
            onPressed: _sendNotification,
            text: 'Send Notification',
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }
}