import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';

/// A wrapper that groups [ProfileMenuTile]s into a visually distinct card.
class ProfileSectionCard extends StatelessWidget {
  final List<Widget> children;

  const ProfileSectionCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusValL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final idx = entry.key;
          final widget = entry.value;

          return Column(
            children: [
              widget,
              if (idx < children.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}