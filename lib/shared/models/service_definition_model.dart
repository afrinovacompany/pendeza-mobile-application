// lib/shared/models/service_definition_model.dart

import 'package:equatable/equatable.dart';

class ServiceDefinition extends Equatable {
  final String name;
  final String description;

  const ServiceDefinition({required this.name, required this.description});

  factory ServiceDefinition.fromJson(Map<String, dynamic> json) {
    return ServiceDefinition(
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [name, description];
}

class ServiceCategory extends Equatable {
  final String category;
  final List<ServiceDefinition> services;

  const ServiceCategory({required this.category, required this.services});

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    final serviceList = json['services'] as List<dynamic>? ?? [];
    final services = serviceList
        .map((i) => ServiceDefinition.fromJson(i as Map<String, dynamic>))
        .toList();

    return ServiceCategory(
      category: json['category'] as String? ?? '',
      services: services,
    );
  }

  @override
  List<Object?> get props => [category, services];
}