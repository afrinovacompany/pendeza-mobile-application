import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/shared/models/salon_model.dart';

/// A clean, professional card displaying key salon stats and action buttons.
class SalonQuickInfoCard extends StatelessWidget {
  final SalonModel salon;
  final double averageRating;
  final int totalReviews;

  const SalonQuickInfoCard({
    super.key,
    required this.salon,
    required this.averageRating,
    required this.totalReviews,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.padL),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: AppConstants.radiusL,
          // Subtle professional shadow
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.border,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Row 1: Key Stats (Rating | Location)
            Row(
              children: [
                // RATING BLOCK
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(CupertinoIcons.star_fill, size: 18, color: AppColors.warning),
                      const SizedBox(width: 6),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        ' ($totalReviews)',
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // LOCATION BLOCK
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(CupertinoIcons.location, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          salon.district ?? salon.region ?? 'Tanzania',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),

            // Row 2: Action Buttons (Call, WhatsApp, Map, Hours)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (salon.phoneNumber != null)
                  _buildActionButton(
                    context,
                    label: 'Call',
                    icon: CupertinoIcons.phone_fill,
                    color: AppColors.success,
                    onTap: () => _makePhoneCall(salon.phoneNumber!),
                  ),
                if (salon.whatsappNumber != null)
                  _buildActionButton(
                    context,
                    label: 'Chat',
                    icon: CupertinoIcons.chat_bubble_fill,
                    color: const Color(0xFF25D366), // WhatsApp Green
                    onTap: () => _openWhatsApp(salon.whatsappNumber!),
                  ),
                _buildActionButton(
                  context,
                  label: 'Map',
                  icon: CupertinoIcons.map_fill,
                  color: AppColors.info,
                  onTap: () {}, // TODO: Implement Map
                ),
                _buildActionButton(
                  context,
                  label: 'Hours',
                  icon: CupertinoIcons.time_solid,
                  color: AppColors.accent,
                  onTap: () => _showHoursDialog(context, salon),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, {
        required String label,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWhatsApp(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showHoursDialog(BuildContext context, SalonModel salon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Business Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeRow('Open', salon.openingTime),
            const SizedBox(height: 8),
            _buildTimeRow('Close', salon.closingTime),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, String time) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}