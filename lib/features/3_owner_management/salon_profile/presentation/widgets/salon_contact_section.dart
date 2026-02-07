import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import '../bloc/salon_profile_bloc.dart';
import '../dialogs/edit_salon_dialog.dart';

class SalonContactSection extends StatelessWidget {
  final SalonModel salon;

  const SalonContactSection({
    super.key,
    required this.salon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Contact & Social Media',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              onPressed: () => _showEditDialog(context),
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: AppConstants.padM),
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phone Number
              _buildContactRow(
                context,
                icon: Icons.phone_rounded,
                label: 'Phone',
                value: salon.phoneNumber ?? 'Add phone number',
                isPlaceholder: salon.phoneNumber == null,
                onTap: salon.phoneNumber != null
                    ? () => _makePhoneCall(salon.phoneNumber!)
                    : null,
              ),
              const Divider(height: AppConstants.padL),

              // WhatsApp
              _buildContactRow(
                context,
                icon: Icons.chat_bubble_rounded,
                iconColor: const Color(0xFF25D366), // WhatsApp green
                label: 'WhatsApp',
                value: salon.whatsappNumber ?? 'Add WhatsApp number',
                isPlaceholder: salon.whatsappNumber == null,
                onTap: salon.whatsappNumber != null
                    ? () => _openWhatsApp(salon.whatsappNumber!)
                    : null,
              ),
              const Divider(height: AppConstants.padL),

              // Instagram
              _buildContactRow(
                context,
                icon: Icons.camera_alt_rounded,
                iconColor: const Color(0xFFE4405F), // Instagram pink
                label: 'Instagram',
                value: salon.instagram != null
                    ? '@${salon.instagram}'
                    : 'Add Instagram',
                isPlaceholder: salon.instagram == null,
                onTap: salon.instagram != null
                    ? () => _openInstagram(salon.instagram!)
                    : null,
              ),
              const Divider(height: AppConstants.padL),

              // Facebook
              _buildContactRow(
                context,
                icon: Icons.facebook_rounded,
                iconColor: const Color(0xFF1877F2), // Facebook blue
                label: 'Facebook',
                value: salon.facebook ?? 'Add Facebook page',
                isPlaceholder: salon.facebook == null,
                onTap: salon.facebook != null
                    ? () => _openFacebook(salon.facebook!)
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        bool isPlaceholder = false,
        VoidCallback? onTap,
        Color? iconColor,
      }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      // ✅ FIX: Use the BorderRadius object AppConstants.radiusS directly
      borderRadius: AppConstants.radiusS,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary).withOpacity(0.1),
                // ✅ FIX: Use the BorderRadius object AppConstants.radiusS directly
                borderRadius: AppConstants.radiusS,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppConstants.padM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: isPlaceholder
                          ? theme.colorScheme.onSurface.withOpacity(0.4)
                          : null,
                      fontStyle: isPlaceholder ? FontStyle.italic : null,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
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

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SalonProfileBloc>(),
        child: EditContactDialog(salon: salon),
      ),
    );
  }

  // Phone Call
  Future<void> _makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  // WhatsApp
  Future<void> _openWhatsApp(String phoneNumber) async {
    // Remove any non-digit characters
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('https://wa.me/$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Instagram
  Future<void> _openInstagram(String username) async {
    // Remove @ if present
    final cleanUsername = username.replaceAll('@', '');
    final uri = Uri.parse('https://instagram.com/$cleanUsername');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // Facebook
  Future<void> _openFacebook(String pageUrl) async {
    final uri = Uri.parse(pageUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}