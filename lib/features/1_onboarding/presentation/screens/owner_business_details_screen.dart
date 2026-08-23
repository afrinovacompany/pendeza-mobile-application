import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_bloc.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_event.dart';
import 'package:pendeza/features/0_auth/presentation/bloc/auth_state.dart';
import '../../../../app/config/theme/app_constants.dart';
import '../../../../app/utils/validators.dart';
import '../../../../shared/widgets/primary_gradient_button.dart';
import '../../../../shared/widgets/text_form_field.dart';

class OwnerBusinessDetailsScreen extends StatefulWidget {
  final List<String> businessTypeIds;
  final List<String> businessTypeNames;
  final List<String> suggestedCategories;

  const OwnerBusinessDetailsScreen({
    super.key,
    required this.businessTypeIds,
    required this.businessTypeNames,
    required this.suggestedCategories,
  });

  @override
  State<OwnerBusinessDetailsScreen> createState() => _OwnerBusinessDetailsScreenState();
}

class _OwnerBusinessDetailsScreenState extends State<OwnerBusinessDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _salonNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _categoriesController = TextEditingController();

  // Location Data
  List<dynamic> _regions = [];
  String? _selectedRegion;
  String? _selectedDistrict;
  List<String> _availableDistricts = [];
  bool _isLoadingRegions = true;

  @override
  void initState() {
    super.initState();
    _loadRegions();
    // Pre-fill categories
    if (widget.suggestedCategories.isNotEmpty) {
      _categoriesController.text = widget.suggestedCategories.join(', ');
    }
  }

  Future<void> _loadRegions() async {
    try {
      final String response = await rootBundle.loadString('assets/location/tanzaniaRegionsAndDistricts.json');
      final List<dynamic> data = json.decode(response);

      // Sort regions alphabetically
      data.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      if (mounted) {
        setState(() {
          _regions = data;
          _isLoadingRegions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingRegions = false);
      }
    }
  }

  void _onRegionChanged(String? newRegion) {
    if (newRegion == null) return;

    final regionData = _regions.firstWhere((r) => r['name'] == newRegion, orElse: () => null);
    final List<dynamic> districtData = regionData?['districts'] ?? [];

    final List<String> districts = districtData
        .map((d) => d['name'] as String)
        .toList();

    districts.sort(); // Sort districts alphabetically

    setState(() {
      _selectedRegion = newRegion;
      _availableDistricts = districts;
      _selectedDistrict = null; // Reset district when region changes
    });
  }

  void _completeSetup() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final authState = context.read<AuthBloc>().state;

    // We need the UID from the current state
    String? uid;
    if (authState is OwnerProfileSetupRequired) {
      uid = authState.user.uid;
    } else if (authState is Authenticated) {
      uid = authState.user.uid;
    }

    if (uid == null) return;

    final categories = _categoriesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    context.read<AuthBloc>().add(
      CompleteOwnerProfile(
        ownerId: uid,
        salonName: _salonNameController.text.trim(),
        address: _addressController.text.trim(),
        serviceCategories: categories,
        // NEW FIELDS PASSED HERE
        businessTypeIds: widget.businessTypeIds,
        businessTypeNames: widget.businessTypeNames,
        region: _selectedRegion,
        district: _selectedDistrict,
      ),
    );
  }

  @override
  void dispose() {
    _salonNameController.dispose();
    _addressController.dispose();
    _categoriesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: theme.colorScheme.error),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          appBar: AppBar(
            // Key: "onboarding.owner.title"
            title: Text('onboarding.owner.title'.tr()),
            elevation: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.padL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Key: "onboarding.owner.headline"
                    Text(
                      'onboarding.owner.headline'.tr(),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppConstants.padL),

                    // Salon Name
                    CustomTextFormField(
                      controller: _salonNameController,
                      // Key: "onboarding.owner.salon_name_label"
                      labelText: 'onboarding.owner.salon_name_label'.tr(),
                      // Key: "onboarding.owner.salon_name_hint"
                      hintText: 'onboarding.owner.salon_name_hint'.tr(),
                      prefixIcon: Icons.store,
                      validator: AppValidators.notEmpty,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppConstants.padL),

                    // Region Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRegion,
                      decoration: InputDecoration(
                        // Key: "onboarding.owner.region_label"
                        labelText: 'onboarding.owner.region_label'.tr(),
                        prefixIcon: const Icon(Icons.map),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      items: _regions.map<DropdownMenuItem<String>>((region) {
                        return DropdownMenuItem(
                          value: region['name'],
                          child: Text(region['name']),
                        );
                      }).toList(),
                      onChanged: isLoading || _isLoadingRegions ? null : _onRegionChanged,
                      // Key: "onboarding.owner.region_error"
                      validator: (val) => val == null ? 'onboarding.owner.region_error'.tr() : null,
                    ),
                    const SizedBox(height: AppConstants.padL),

                    // District Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedDistrict,
                      decoration: InputDecoration(
                        // Key: "onboarding.owner.district_label"
                        labelText: 'onboarding.owner.district_label'.tr(),
                        prefixIcon: const Icon(Icons.location_city),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                      ),
                      items: _availableDistricts.map<DropdownMenuItem<String>>((district) {
                        return DropdownMenuItem(
                          value: district,
                          child: Text(district),
                        );
                      }).toList(),
                      onChanged: isLoading ? null : (val) => setState(() => _selectedDistrict = val),
                      // Key: "onboarding.owner.district_error"
                      validator: (val) => val == null ? 'onboarding.owner.district_error'.tr() : null,
                    ),
                    const SizedBox(height: AppConstants.padL),

                    // Street Address
                    CustomTextFormField(
                      controller: _addressController,
                      // Key: "onboarding.owner.address_label"
                      labelText: 'onboarding.owner.address_label'.tr(),
                      // Key: "onboarding.owner.address_hint"
                      hintText: 'onboarding.owner.address_hint'.tr(),
                      prefixIcon: Icons.location_on,
                      validator: AppValidators.notEmpty,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppConstants.padL),

                    // Categories
                    CustomTextFormField(
                      controller: _categoriesController,
                      // Key: "onboarding.owner.categories_label"
                      labelText: 'onboarding.owner.categories_label'.tr(),
                      // Key: "onboarding.owner.categories_hint"
                      hintText: 'onboarding.owner.categories_hint'.tr(),
                      prefixIcon: Icons.category,
                      maxLines: 2,
                      validator: AppValidators.notEmpty,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: AppConstants.padXL),

                    PrimaryGradientButton(
                      // Key: "onboarding.owner.button"
                      text: 'onboarding.owner.button'.tr(),
                      onPressed: isLoading ? null : _completeSetup,
                      isLoading: isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}