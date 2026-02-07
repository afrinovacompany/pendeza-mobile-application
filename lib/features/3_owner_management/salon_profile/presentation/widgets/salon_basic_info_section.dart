import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import '../bloc/salon_profile_bloc.dart';
import '../bloc/salon_profile_event.dart';

class SalonBasicInfoSection extends StatelessWidget {
  final SalonModel salon;

  const SalonBasicInfoSection({
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
              'Basic Information',
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
              // Salon Name
              _buildInfoRow(
                context,
                icon: Icons.store_rounded,
                label: 'Salon Name',
                value: salon.salonName,
              ),
              const Divider(height: AppConstants.padL),

              // Description
              _buildInfoRow(
                context,
                icon: Icons.description_rounded,
                label: 'Description',
                value: salon.description ?? 'Add a description',
                isPlaceholder: salon.description == null,
              ),
              const Divider(height: AppConstants.padL),

              // Address
              _buildInfoRow(
                context,
                icon: Icons.location_on_rounded,
                label: 'Address',
                value: salon.address,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        bool isPlaceholder = false,
      }) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
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
              const SizedBox(height: 4),
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
      ],
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SalonProfileBloc>(),
        // FIX: Now calling the correct EditSalonDialog widget defined below
        child: EditSalonDialog(salon: salon),
      ),
    );
  }
}

// FIX: Created the missing EditSalonDialog widget for basic info
class EditSalonDialog extends StatefulWidget {
  final SalonModel salon;

  const EditSalonDialog({
    super.key,
    required this.salon,
  });

  @override
  State<EditSalonDialog> createState() => _EditSalonDialogState();
}

class _EditSalonDialogState extends State<EditSalonDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _salonNameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _salonNameController = TextEditingController(text: widget.salon.salonName);
    _descriptionController = TextEditingController(text: widget.salon.description ?? '');
    _addressController = TextEditingController(text: widget.salon.address);
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
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
                        'Edit Basic Information',
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

                // Salon Name
                Text(
                  'Salon Name *',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppConstants.padXS),
                TextFormField(
                  controller: _salonNameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter salon name',
                    prefixIcon: Icon(Icons.store_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Salon name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.padM),

                // Description
                Text(
                  'Description',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppConstants.padXS),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Describe your salon (optional)',
                    prefixIcon: Icon(Icons.description_rounded),
                  ),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: AppConstants.padM),

                // Address
                Text(
                  'Address *',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: AppConstants.padXS),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    hintText: 'Enter salon address',
                    prefixIcon: Icon(Icons.location_on_rounded),
                  ),
                  maxLines: 2,
                  keyboardType: TextInputType.streetAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppConstants.padXL),

                // Info message
                Container(
                  padding: const EdgeInsets.all(AppConstants.padM),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
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
                          'This information will be visible to all clients',
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
      final description = _descriptionController.text.trim();

      context.read<SalonProfileBloc>().add(
        UpdateBasicInfo(
          salonName: _salonNameController.text.trim(),
          description: description.isEmpty ? null : description,
          address: _addressController.text.trim(),
        ),
      );

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Basic information updated!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}