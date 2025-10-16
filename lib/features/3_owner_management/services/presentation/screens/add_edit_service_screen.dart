import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

  List<ServiceCategory> _serviceDefinitions = [];
  bool _definitionsLoading = true;

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
    super.dispose();
  }

  void _saveService() {
    if (_formKey.currentState?.validate() ?? false) {
      final service = ServiceModel(
        id: widget.service?.id ??
            '', // ID will be ignored for new, but needed for update
        salonId: '', // BLoC will fill this in
        name: _nameController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        durationMinutes: int.tryParse(_durationController.text) ?? 0,
        description: _descriptionController.text.trim(),
        category: _categoryController.text.trim(),
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

    // Show a confirmation dialog before deleting
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete the service "${widget.service!.name}"? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Service' : 'Add New Service'),
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
                        });
                      },
                      onServiceSelected: (service) {
                        setState(() {
                          _nameController.text = service.name;
                          _descriptionController.text = service.description;
                        });
                      },
                    ),
                  const SizedBox(height: AppConstants.padL),
                  CustomTextFormField(
                    controller: _priceController,
                    labelText: 'Price (TSh)',
                    hintText: 'e.g., 25000',
                    keyboardType: TextInputType.number,
                    validator: (value) => AppValidators.notEmpty(value),
                  ),
                  const SizedBox(height: AppConstants.padL),
                  CustomTextFormField(
                    controller: _durationController,
                    labelText: 'Duration (in minutes)',
                    hintText: 'e.g., 45',
                    keyboardType: TextInputType.number,
                    validator: (value) => AppValidators.notEmpty(value),
                  ),
                  const SizedBox(height: AppConstants.padL),
                  CustomTextFormField(
                    controller: _descriptionController,
                    labelText: 'Description (Optional)',
                    hintText: 'A short description of the service...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppConstants.padXL),
                  PrimaryGradientButton(
                    text: _isEditing ? 'SAVE CHANGES' : 'ADD SERVICE',
                    onPressed: isSaving ? null : _saveService,
                    isLoading: isSaving,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
