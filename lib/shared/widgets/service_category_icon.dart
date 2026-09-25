import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Icon that best matches a service category name.
IconData serviceCategoryIcon(String category) {
  final cat = category.toLowerCase();
  if (cat.contains('hair')) return CupertinoIcons.scissors;
  if (cat.contains('nail')) return Icons.back_hand_outlined;
  if (cat.contains('massage')) return Icons.spa;
  if (cat.contains('skin') || cat.contains('facial')) return Icons.face;
  if (cat.contains('makeup') || cat.contains('beauty')) return Icons.brush;
  if (cat.contains('braid') || cat.contains('extension')) return Icons.person;
  if (cat.contains('lash') || cat.contains('brow')) return Icons.remove_red_eye;
  if (cat.contains('men') || cat.contains('groom')) return Icons.content_cut;
  if (cat.contains('body') || cat.contains('spa')) return Icons.spa;
  if (cat.contains('tattoo') || cat.contains('piercing')) return Icons.edit;
  if (cat.contains('medical')) return Icons.medical_services;
  return CupertinoIcons.scissors;
}
