import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import '../bloc/salon_profile_bloc.dart';
import '../bloc/salon_profile_event.dart';

class EditContactDialog extends StatefulWidget {
  final SalonModel salon;

  const EditContactDialog({
    super.key,
    required this.salon,
  });

  @override
  State<EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<EditContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _phoneController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _instagramController;
  late final TextEditingController _facebookController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.salon.phoneNumber);
    _whatsappController =
        TextEditingController(text: widget.salon.whatsappNumber);
    _instagramController = TextEditingController(text: widget.salon.instagram);
    _facebookController = TextEditingController(text: widget.salon.facebook);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _whatsappController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Contact & Social Media',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.padL),

                // Phone Number
                Text(
                  'Phone Number *',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppConstants.padXS),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    hintText: '+255 712 345 678',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!value.startsWith('+') && !value.startsWith('0')) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.padM),

                // WhatsApp Number
                Text(
                  'WhatsApp Number',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppConstants.padXS),
                TextFormField(
                  controller: _whatsappController,
                  decoration: InputDecoration(
                    hintText: '+255 712 345 678',
                    prefixIcon: Icon(
                      Icons.chat_bubble_rounded,
                      color: const Color(0xFF25D366),
                    ),
                    helperText: 'Same as phone? Tap to copy',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.content_copy),
                      onPressed: () {
                        _whatsappController.text = _phoneController.text;
                      },
                      tooltip: 'Copy from phone',
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppConstants.padM),

                // Instagram
                Text(
                  'Instagram Username',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppConstants.padXS),
                TextFormField(
                  controller: _instagramController,
                  decoration: InputDecoration(
                    hintText: 'yoursalon',
                    prefixText: '@',
                    prefixIcon: Icon(
                      Icons.camera_alt_rounded,
                      color: const Color(0xFFE4405F),
                    ),
                    helperText: 'Without the @ symbol',
                  ),
                  keyboardType: TextInputType.text,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                  ],
                ),
                const SizedBox(height: AppConstants.padM),

                // Facebook
                Text(
                  'Facebook Page',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppConstants.padXS),
                TextFormField(
                  controller: _facebookController,
                  decoration: InputDecoration(
                    hintText: 'facebook.com/yoursalon',
                    prefixIcon: Icon(
                      Icons.facebook_rounded,
                      color: const Color(0xFF1877F2),
                    ),
                    helperText: 'Full Facebook page URL',
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: AppConstants.padXL),

                // Info message
                Container(
                  padding: const EdgeInsets.all(AppConstants.padM),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    // FIX: Use radiusValM (double) instead of radiusM (BorderRadius)
                    borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppConstants.padS),
                      Expanded(
                        child: Text(
                          'Clients can call or message you directly from your salon profile',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.padL),

                // Save button
                PrimaryGradientButton(
                  onPressed: _handleSave,
                  text: 'Save Changes',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSave() {
    if (_formKey.currentState!.validate()) {
      // Clean Instagram username (remove @ if user added it)
      final instagram = _instagramController.text.trim();
      final cleanInstagram =
      instagram.isNotEmpty ? instagram.replaceAll('@', '') : null;

      context.read<SalonProfileBloc>().add(
        UpdateContactInfo(
          phoneNumber: _phoneController.text.trim(),
          whatsappNumber: _whatsappController.text.trim().isEmpty
              ? null
              : _whatsappController.text.trim(),
          instagram: cleanInstagram,
          facebook: _facebookController.text.trim().isEmpty
              ? null
              : _facebookController.text.trim(),
        ),
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact information updated!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}