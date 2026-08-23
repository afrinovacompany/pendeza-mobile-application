import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/custom_card.dart';
import '../bloc/salon_profile_bloc.dart';
import '../bloc/salon_profile_event.dart';

/// Common amenities that salons offer
const List<String> AVAILABLE_AMENITIES = [
  'WiFi',
  'Parking',
  'Air Conditioning',
  'Credit Cards',
  'Mobile Money',
  'Wheelchair Accessible',
  'Kids Friendly',
  'Refreshments',
  'Magazine/Books',
  'TV',
];

class SalonAmenitiesSection extends StatelessWidget {
  final SalonModel salon;

  const SalonAmenitiesSection({
    super.key,
    required this.salon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentAmenities = salon.amenities ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Amenities & Features',
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

        if (currentAmenities.isEmpty)
          CustomCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.padXL),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: theme.colorScheme.primary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: AppConstants.padM),
                    Text(
                      'Add amenities to attract more clients',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          CustomCard(
            child: Wrap(
              spacing: AppConstants.padS,
              runSpacing: AppConstants.padS,
              children: currentAmenities.map((amenity) {
                return _buildAmenityChip(context, amenity);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAmenityChip(BuildContext context, String amenity) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.padM,
        vertical: AppConstants.padS,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        // FIX: Use radiusValL (double) instead of radiusL (BorderRadius)
        borderRadius: BorderRadius.circular(AppConstants.radiusValL),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAmenityIcon(amenity),
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppConstants.padXS),
          Text(
            amenity,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi_rounded;
      case 'parking':
        return Icons.local_parking_rounded;
      case 'air conditioning':
        return Icons.ac_unit_rounded;
      case 'credit cards':
        return Icons.credit_card_rounded;
      case 'mobile money':
        return Icons.phone_android_rounded;
      case 'wheelchair accessible':
        return Icons.accessible_rounded;
      case 'kids friendly':
        return Icons.child_friendly_rounded;
      case 'refreshments':
        return Icons.local_cafe_rounded;
      case 'magazine/books':
        return Icons.menu_book_rounded;
      case 'tv':
        return Icons.tv_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<SalonProfileBloc>(),
        child: _EditAmenitiesDialog(salon: salon),
      ),
    );
  }
}

/// Dialog for editing amenities
class _EditAmenitiesDialog extends StatefulWidget {
  final SalonModel salon;

  const _EditAmenitiesDialog({required this.salon});

  @override
  State<_EditAmenitiesDialog> createState() => _EditAmenitiesDialogState();
}

class _EditAmenitiesDialogState extends State<_EditAmenitiesDialog> {
  late List<String> _selectedAmenities;

  @override
  void initState() {
    super.initState();
    _selectedAmenities = List.from(widget.salon.amenities ?? []);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.padL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Amenities',
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
              const SizedBox(height: AppConstants.padM),

              Text(
                'Select all that apply to your salon',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: AppConstants.padL),

              // Amenities List
              ...AVAILABLE_AMENITIES.map((amenity) {
                final isSelected = _selectedAmenities.contains(amenity);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedAmenities.add(amenity);
                      } else {
                        _selectedAmenities.remove(amenity);
                      }
                    });
                  },
                  title: Row(
                    children: [
                      Icon(
                        _getAmenityIcon(amenity),
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: AppConstants.padS),
                      Text(amenity),
                    ],
                  ),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }),

              const SizedBox(height: AppConstants.padL),

              // Selected count
              Container(
                padding: const EdgeInsets.all(AppConstants.padM),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  // FIX: Use radiusValM (double) instead of radiusM (BorderRadius)
                  borderRadius: BorderRadius.circular(AppConstants.radiusValM),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: AppConstants.padS),
                    Expanded(
                      child: Text(
                        '${_selectedAmenities.length} amenities selected',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.padL),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(AppConstants.padM),
                  ),
                  child: const Text('Save Amenities'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi_rounded;
      case 'parking':
        return Icons.local_parking_rounded;
      case 'air conditioning':
        return Icons.ac_unit_rounded;
      case 'credit cards':
        return Icons.credit_card_rounded;
      case 'mobile money':
        return Icons.phone_android_rounded;
      case 'wheelchair accessible':
        return Icons.accessible_rounded;
      case 'kids friendly':
        return Icons.child_friendly_rounded;
      case 'refreshments':
        return Icons.local_cafe_rounded;
      case 'magazine/books':
        return Icons.menu_book_rounded;
      case 'tv':
        return Icons.tv_rounded;
      default:
        return Icons.check_circle_rounded;
    }
  }

  void _handleSave() {
    context.read<SalonProfileBloc>().add(
      UpdateAmenities(_selectedAmenities),
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Amenities updated!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}