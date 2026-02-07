// lib/shared/models/service_definition_model.dart
// Pre-defined service templates for quick service creation

import 'package:equatable/equatable.dart';

/// A pre-defined service template with suggested pricing and duration.
class ServiceDefinition extends Equatable {
  final String name;
  final String description;
  final int? defaultDuration; // Suggested duration in minutes
  final double? defaultPrice; // Suggested price in TZS

  const ServiceDefinition({
    required this.name,
    required this.description,
    this.defaultDuration,
    this.defaultPrice,
  });

  factory ServiceDefinition.fromJson(Map<String, dynamic> json) {
    return ServiceDefinition(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      defaultDuration: json['defaultDuration'] as int?,
      defaultPrice: (json['defaultPrice'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [name, description, defaultDuration, defaultPrice];
}

/// A category of services with icon for display.
class ServiceCategory extends Equatable {
  final String category;
  final String? icon; // SF Symbol or icon name
  final List<ServiceDefinition> services;

  const ServiceCategory({
    required this.category,
    this.icon,
    required this.services,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    final serviceList = json['services'] as List<dynamic>? ?? [];
    final services = serviceList
        .map((i) => ServiceDefinition.fromJson(i as Map<String, dynamic>))
        .toList();

    return ServiceCategory(
      category: json['category'] as String? ?? '',
      icon: json['icon'] as String?,
      services: services,
    );
  }

  @override
  List<Object?> get props => [category, icon, services];
}