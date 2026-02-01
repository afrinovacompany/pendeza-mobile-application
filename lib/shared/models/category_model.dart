import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

/// Represents a service category in the Pendeza app.
///
/// Designed for a premium UI using custom PNG icons instead of emojis.
/// Supports gender targeting for the "Personalized" dashboard view.
class CategoryModel extends Equatable {
  /// Unique identifier (e.g., 'hair_salon', 'barbershop')
  /// This ID is used to construct the icon filename: "category_{id}.png"
  final String id;

  /// Display name (e.g., "Hair Salon")
  final String name;

  /// URL to the white transparent PNG icon in Firebase Storage.
  final String? iconUrl;

  /// Primary color for this category (hex integer).
  /// Used for the gradient background on the dashboard chips.
  final int color;

  /// Target gender for personalization algorithms.
  /// Values: 'female', 'male', 'all'
  final String targetGender;

  const CategoryModel({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.color,
    this.targetGender = 'all',
  });

  /// Helper to get the Color object from the hex integer
  Color get colorObj => Color(color);

  @override
  List<Object?> get props => [id, name, iconUrl, color, targetGender];
}