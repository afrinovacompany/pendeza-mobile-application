import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';

/// A widget that previews how the notification will look on a device
class NotificationPreviewWidget extends StatelessWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final bool isLocalFile;

  const NotificationPreviewWidget({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
    this.isLocalFile = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 360,
      margin: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: AppConstants.radiusL,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App header
          _buildNotificationHeader(isDark),

          // Notification content
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.padM,
              AppConstants.padS,
              AppConstants.padM,
              AppConstants.padM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App icon
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        CupertinoIcons.sparkles,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: AppConstants.padS),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pendeza',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.white.withOpacity(0.7)
                                  : Colors.black.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'now',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.black.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.padS),

                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppConstants.padXXS),

                // Body
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.7),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

                // Image (if provided)
                if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.padM),
                  ClipRRect(
                    borderRadius: AppConstants.radiusM,
                    child: isLocalFile
                        ? Image.file(
                      File(imageUrl!),
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder(isDark);
                      },
                    )
                        : Image.network(
                      imageUrl!,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildImagePlaceholder(isDark);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.padM,
        vertical: AppConstants.padS,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade100,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'NOTIFICATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : Colors.black.withOpacity(0.5),
            ),
          ),
          Icon(
            CupertinoIcons.chevron_down,
            size: 14,
            color: isDark
                ? Colors.white.withOpacity(0.6)
                : Colors.black.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(bool isDark) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A2A)
            : Colors.grey.shade200,
        borderRadius: AppConstants.radiusM,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.photo_on_rectangle,
            size: 40,
            color: isDark
                ? Colors.white.withOpacity(0.3)
                : Colors.black.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          Text(
            'Image Preview',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? Colors.white.withOpacity(0.5)
                  : Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alternative Android-style notification preview
class AndroidNotificationPreview extends StatelessWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final bool isLocalFile;

  const AndroidNotificationPreview({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
    this.isLocalFile = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      margin: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: const Color(0xFF202124),
        borderRadius: AppConstants.radiusM,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppConstants.padM),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    CupertinoIcons.sparkles,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: AppConstants.padS),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pendeza',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'now',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_down,
                  size: 16,
                  color: Colors.white60,
                ),
              ],
            ),
          ),

          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              AppConstants.padM,
              0,
              AppConstants.padM,
              AppConstants.padM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppConstants.padXXS),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                if (imageUrl != null && imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: AppConstants.padS),
                  ClipRRect(
                    borderRadius: AppConstants.radiusS,
                    child: isLocalFile
                        ? Image.file(
                      File(imageUrl!),
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    )
                        : Image.network(
                      imageUrl!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}