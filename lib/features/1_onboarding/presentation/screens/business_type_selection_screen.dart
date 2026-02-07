import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import 'owner_business_details_screen.dart';


class BusinessTypeSelectionScreen extends StatefulWidget {
  const BusinessTypeSelectionScreen({super.key});

  @override
  State<BusinessTypeSelectionScreen> createState() => _BusinessTypeSelectionScreenState();
}

class _BusinessTypeSelectionScreenState extends State<BusinessTypeSelectionScreen> {
  List<dynamic> _businessTypes = [];
  final List<String> _selectedTypeIds = [];
  final List<String> _selectedTypeNames = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessTypes();
  }

  Future<void> _loadBusinessTypes() async {
    try {
      final String response = await rootBundle.loadString('assets/data/business_types.json');
      final List<dynamic> data = json.decode(response);
      if (mounted) {
        setState(() {
          _businessTypes = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          // Key: "business_type.error_loading"
          SnackBar(content: Text('business_type.error_loading'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  void _toggleSelection(String id, String name) {
    setState(() {
      if (_selectedTypeIds.contains(id)) {
        _selectedTypeIds.remove(id);
        _selectedTypeNames.remove(name);
      } else {
        _selectedTypeIds.add(id);
        _selectedTypeNames.add(name);
      }
    });
  }

  void _proceedToNextStep() {
    if (_selectedTypeIds.isEmpty) return;

    // Aggregate suggested categories from selected types
    final Set<String> suggestedCategories = {};
    for (var type in _businessTypes) {
      if (_selectedTypeIds.contains(type['id'])) {
        final List<dynamic> categories = type['suggestedCategories'] ?? [];
        suggestedCategories.addAll(categories.map((e) => e.toString()));
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OwnerBusinessDetailsScreen(
          businessTypeIds: _selectedTypeIds,
          businessTypeNames: _selectedTypeNames,
          suggestedCategories: suggestedCategories.toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _ = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        // Key: "business_type.title"
        title: Text('business_type.title'.tr()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppConstants.padL),
            child: Column(
              children: [
                // Key: "business_type.headline"
                Text(
                  'business_type.headline'.tr(),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.padS),
                // Key: "business_type.subtitle"
                Text(
                  'business_type.subtitle'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: AppConstants.padM,
                mainAxisSpacing: AppConstants.padM,
              ),
              itemCount: _businessTypes.length,
              itemBuilder: (context, index) {
                final type = _businessTypes[index];
                final isSelected = _selectedTypeIds.contains(type['id']);
                return _BusinessTypeCard(
                  type: type,
                  isSelected: isSelected,
                  onTap: () => _toggleSelection(type['id'], type['name']),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppConstants.padL),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: PrimaryGradientButton(
              // Key: "common.continue"
              text: '${'common.continue'.tr()} (${_selectedTypeIds.length})',
              onPressed: _selectedTypeIds.isNotEmpty ? _proceedToNextStep : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessTypeCard extends StatelessWidget {
  final dynamic type;
  final bool isSelected;
  final VoidCallback onTap;

  const _BusinessTypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Map icon string names to IconData
    // You might need a more comprehensive mapping or a package like flutter_icons
    IconData getIcon(String iconName) {
      switch (iconName) {
        case 'content_cut': return Icons.content_cut;
        case 'spa': return Icons.spa;
        case 'face_retouching_natural': return Icons.face_retouching_natural;
        case 'favorite': return Icons.favorite;
        case 'wc': return Icons.wc;
        case 'face': return Icons.face;
        case 'remove_circle_outline': return Icons.remove_circle_outline;
        case 'more_horiz': return Icons.more_horiz;
        default: return Icons.store;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : theme.colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                getIcon(type['icon']),
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.7),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                type['name'],
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? primaryColor : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle, color: primaryColor, size: 16),
              ),
          ],
        ),
      ),
    );
  }
}