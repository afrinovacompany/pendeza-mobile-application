import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/utils/validators.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_bloc.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_event.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/bloc/services_state.dart';
import 'package:pendeza/features/3_owner_management/services/presentation/widgets/categorized_service_dropdowns.dart';
import 'package:pendeza/shared/models/service_definition_model.dart';
import 'package:pendeza/shared/models/service_model.dart';
import 'package:pendeza/shared/widgets/primary_gradient_button.dart';
import 'package:pendeza/shared/widgets/text_form_field.dart';

class AddEditServiceScreen extends StatefulWidget {
  final ServiceModel? service;
  const AddEditServiceScreen({super.key, this.service});

  @override
  State<AddEditServiceScreen> createState() => _AddEditServiceScreenState();
}

class _AddEditServiceScreenState extends State<AddEditServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _durationController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _staffNoteController;
  late final TextEditingController _discountedPriceController;

  List<ServiceCategory> _serviceDefinitions = [];
  bool _definitionsLoading = true;
  bool _isActive = true;
  bool _isFeatured = false;
  bool _requiresDeposit = false;
  bool _showAdvancedOptions = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service?.name);
    _priceController =
        TextEditingController(text: widget.service?.price.toStringAsFixed(0));
    _durationController =
        TextEditingController(text: widget.service?.durationMinutes.toString());
    _descriptionController =
        TextEditingController(text: widget.service?.description);
    _categoryController = TextEditingController(text: widget.service?.category);
    _staffNoteController =
        TextEditingController(text: widget.service?.staffNote);
    _discountedPriceController = TextEditingController(
        text: widget.service?.discountedPrice?.toStringAsFixed(0));

    if (_isEditing) {
      _isActive = widget.service!.isActive;
      _isFeatured = widget.service!.isFeatured;
      _requiresDeposit = widget.service!.requiresDeposit;
    }

    _loadServiceDefinitions();
  }

  Future<void> _loadServiceDefinitions() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/beauty_services.json');
      final data = json.decode(response) as List<dynamic>;
      if (mounted) {
        setState(() {
          _serviceDefinitions =
              data.map((d) => ServiceCategory.fromJson(d)).toList();
          _definitionsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _definitionsLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error: Could not load service definitions.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _staffNoteController.dispose();
    _discountedPriceController.dispose();
    super.dispose();
  }

  void _saveService() {
    if (_formKey.currentState?.validate() ?? false) {
      final discountedPrice = _discountedPriceController.text.isNotEmpty
          ? double.tryParse(_discountedPriceController.text)
          : null;

      final service = ServiceModel(
        id: widget.service?.id ?? '',
        salonId: '',
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        durationMinutes: int.tryParse(_durationController.text) ?? 0,
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
        isActive: _isActive,
        isFeatured: _isFeatured,
        requiresDeposit: _requiresDeposit,
        staffNote: _staffNoteController.text.trim().isNotEmpty
            ? _staffNoteController.text.trim()
            : null,
        discountedPrice: discountedPrice,
        bookingsCount: widget.service?.bookingsCount ?? 0,
        imageUrl: widget.service?.imageUrl,
        tags: widget.service?.tags ?? [],
        sortOrder: widget.service?.sortOrder ?? 0,
      );

      if (_isEditing) {
        context.read<ServicesBloc>().add(UpdateServiceRequested(service));
      } else {
        context.read<ServicesBloc>().add(AddServiceRequested(service));
      }
    }
  }

  void _deleteService() {
    if (!_isEditing) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('owner.services.delete_confirm_title'.tr()),
          content: Text(
              'owner.services.delete_confirm_msg'.tr(args: [widget.service!.name])),
          actions: <Widget>[
            TextButton(
              child: Text('common.cancel'.tr()),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text('owner.services.delete_btn'.tr()),
              onPressed: () {
                context
                    .read<ServicesBloc>()
                    .add(DeleteServiceRequested(widget.service!.id));
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'owner.services.edit_title'.tr()
            : 'owner.services.add_title'.tr()),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(CupertinoIcons.trash, color: Colors.red),
              onPressed: _deleteService,
            )
        ],
      ),
      body: BlocConsumer<ServicesBloc, ServicesState>(
        listener: (context, state) {
          if (state is ServiceOperationSuccess) {
            context.pop();
          }
          if (state is ServicesError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          final isSaving = state is ServiceOperationInProgress;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.padL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status Toggle (only show when editing)
                  if (_isEditing) ...[
                    _buildStatusCard(theme),
                    const SizedBox(height: AppConstants.padL),
                  ],

                  // Service Selection from Templates
                  if (_definitionsLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    CategorizedServiceDropdowns(
                      serviceData: _serviceDefinitions,
                      initialCategory: _categoryController.text,
                      initialService: _nameController.text,
                      onCategorySelected: (category) {
                        setState(() {
                          _categoryController.text = category;
                          _nameController.clear();
                          _descriptionController.clear();
                          _priceController.clear();
                          _durationController.clear();
                        });
                      },
                      onServiceSelected: (service) {
                        setState(() {
                          _nameController.text = service.name;
                          _descriptionController.text = service.description;
                          // Auto-fill suggested price and duration
                          if (service.defaultPrice != null &&
                              _priceController.text.isEmpty) {
                            _priceController.text =
                                service.defaultPrice!.toStringAsFixed(0);
                          }
                          if (service.defaultDuration != null &&
                              _durationController.text.isEmpty) {
                            _durationController.text =
                                service.defaultDuration.toString();
                          }
                        });
                      },
                    ),
                  const SizedBox(height: AppConstants.padL),

                  // Price & Duration Row
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextFormField(
                          controller: _priceController,
                          labelText: '${'owner.services.price_label'.tr()} (TZS)',
                          hintText: 'e.g. 25000',
                          keyboardType: TextInputType.number,
                          validator: (value) => AppValidators.notEmpty(value),
                        ),
                      ),
                      const SizedBox(width: AppConstants.padM),
                      Expanded(
                        child: CustomTextFormField(
                          controller: _durationController,
                          labelText: '${'owner.services.duration_label'.tr()} (min)',
                          hintText: 'e.g. 60',
                          keyboardType: TextInputType.number,
                          validator: (value) => AppValidators.notEmpty(value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.padL),

                  // Description
                  CustomTextFormField(
                    controller: _descriptionController,
                    labelText: 'owner.services.desc_label'.tr(),
                    hintText: 'owner.services.desc_hint'.tr(),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppConstants.padL),

                  // Advanced Options Toggle
                  _buildAdvancedOptionsToggle(theme),

                  // Advanced Options Section
                  if (_showAdvancedOptions) ...[
                    const SizedBox(height: AppConstants.padM),
                    _buildAdvancedOptions(theme),
                  ],

                  const SizedBox(height: AppConstants.padXL),

                  // Save Button
                  PrimaryGradientButton(
                    text: _isEditing
                        ? 'owner.services.save_btn'.tr()
                        : 'owner.services.add_btn'.tr(),
                    onPressed: isSaving ? null : _saveService,
                    isLoading: isSaving,
                  ),

                  // Booking Stats (only when editing)
                  if (_isEditing && widget.service!.bookingsCount > 0) ...[
                    const SizedBox(height: AppConstants.padXL),
                    _buildBookingStats(theme),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: _isActive
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isActive ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.pause_circle_fill,
            color: _isActive ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: AppConstants.padM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isActive ? 'Active' : 'Paused',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isActive ? AppColors.success : AppColors.warning,
                  ),
                ),
                Text(
                  _isActive
                      ? 'This service is visible to clients'
                      : 'This service is hidden from clients',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) => setState(() => _isActive = value),
            activeTrackColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedOptionsToggle(ThemeData theme) {
    return InkWell(
      onTap: () => setState(() => _showAdvancedOptions = !_showAdvancedOptions),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              _showAdvancedOptions
                  ? CupertinoIcons.chevron_down
                  : CupertinoIcons.chevron_right,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Advanced Options',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Optional',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Discounted Price
          CustomTextFormField(
            controller: _discountedPriceController,
            labelText: 'Sale Price in TZS (Optional)',
            hintText: 'Leave empty for no discount',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: AppConstants.padM),

          // Staff Note
          CustomTextFormField(
            controller: _staffNoteController,
            labelText: 'Staff Note (Internal)',
            hintText: 'Notes visible only to your team',
            maxLines: 2,
          ),
          const SizedBox(height: AppConstants.padM),

          // Featured Toggle
          _buildToggleOption(
            theme,
            'Featured Service',
            'Highlight this service in your menu',
            CupertinoIcons.star_fill,
            Colors.amber,
            _isFeatured,
            (value) => setState(() => _isFeatured = value),
          ),
          const SizedBox(height: AppConstants.padS),

          // Deposit Toggle
          _buildToggleOption(
            theme,
            'Requires Deposit',
            'Clients must pay deposit when booking',
            CupertinoIcons.money_dollar_circle_fill,
            AppColors.primary,
            _requiresDeposit,
            (value) => setState(() => _requiresDeposit = value),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppConstants.padS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: color,
        ),
      ],
    );
  }

  Widget _buildBookingStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.padM),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.chart_bar_fill, size: 18),
              const SizedBox(width: 8),
              Text(
                'Performance',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                theme,
                '${widget.service!.bookingsCount}',
                'Total Bookings',
                CupertinoIcons.calendar,
              ),
              if (widget.service!.isPopular)
                _buildStatItem(
                  theme,
                  'Popular',
                  'Top Service',
                  CupertinoIcons.star_fill,
                  color: Colors.amber,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String value,
    String label,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color ?? theme.colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
