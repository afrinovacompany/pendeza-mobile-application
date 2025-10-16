// lib/features/3_owner_management/services/presentation/widgets/categorized_service_dropdowns.dart

import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/service_definition_model.dart';

class CategorizedServiceDropdowns extends StatefulWidget {
  final List<ServiceCategory> serviceData;
  final Function(ServiceDefinition service) onServiceSelected;
  final Function(String category) onCategorySelected;
  final String? initialCategory;
  final String? initialService;

  const CategorizedServiceDropdowns({
    super.key,
    required this.serviceData,
    required this.onServiceSelected,
    required this.onCategorySelected,
    this.initialCategory,
    this.initialService,
  });

  @override
  State<CategorizedServiceDropdowns> createState() =>
      _CategorizedServiceDropdownsState();
}

class _CategorizedServiceDropdownsState
    extends State<CategorizedServiceDropdowns> {
  ServiceCategory? _selectedCategory;
  ServiceDefinition? _selectedService;
  List<ServiceDefinition> _filteredServices = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      try {
        _selectedCategory = widget.serviceData.firstWhere(
              (c) => c.category == widget.initialCategory,
        );
        _filteredServices = _selectedCategory?.services ?? [];
        if (widget.initialService != null) {
          _selectedService = _filteredServices.firstWhere(
                (s) => s.name == widget.initialService,
          );
        }
      } catch (e) {
        // Handle case where initial values don't match data
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ServiceCategory>(
          value: _selectedCategory,
          isExpanded: true,
          hint: const Text('Select a Category'),
          decoration: const InputDecoration(labelText: 'Service Category'),
          items: widget.serviceData.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category.category),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue == null) return;
            setState(() {
              _selectedCategory = newValue;
              _selectedService = null; // Reset service selection
              _filteredServices = newValue.services;
              widget.onCategorySelected(newValue.category);
            });
          },
          validator: (value) =>
          value == null ? 'Please select a category' : null,
        ),
        const SizedBox(height: AppConstants.padL),
        DropdownButtonFormField<ServiceDefinition>(
          value: _selectedService,
          isExpanded: true,
          hint: const Text('Select a Service'),
          decoration: const InputDecoration(labelText: 'Service Name'),
          items: _filteredServices.map((service) {
            return DropdownMenuItem(
              value: service,
              child: Text(service.name),
            );
          }).toList(),
          onChanged: (newValue) {
            if (newValue == null) return;
            setState(() {
              _selectedService = newValue;
              widget.onServiceSelected(newValue);
            });
          },
          validator: (value) =>
          value == null ? 'Please select a service' : null,
        ),
      ],
    );
  }
}