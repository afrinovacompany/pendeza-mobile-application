import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';

/// A vertical stat (value over label) shown on the brand profile hero.
class ProfileStatItem extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTap;

  const ProfileStatItem({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.9,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
