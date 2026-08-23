// =============================================================================
// Payment Method Option Widget
// =============================================================================
// A selectable payment method card with icon, title, subtitle, and badge.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import '../models/payment_method.dart';

class PaymentMethodOption extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final bool isDisabled;
  final String? badge;
  final Color? badgeColor;
  final String? customSubtitle;
  final VoidCallback? onTap;

  const PaymentMethodOption({
    super.key,
    required this.method,
    required this.isSelected,
    this.isDisabled = false,
    this.badge,
    this.badgeColor,
    this.customSubtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIsSelected = isSelected && !isDisabled;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppConstants.padM),
              decoration: BoxDecoration(
                border: Border.all(
                  color: effectiveIsSelected
                      ? theme.colorScheme.primary
                      : Colors.grey.shade200,
                  width: effectiveIsSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
                color: effectiveIsSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.06)
                    : theme.colorScheme.surface,
                boxShadow: effectiveIsSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Icon container
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: effectiveIsSelected
                          ? LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withValues(alpha: 0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: effectiveIsSelected ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      method.icon,
                      color: effectiveIsSelected
                          ? Colors.white
                          : Colors.grey.shade500,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppConstants.padM),

                  // Title and subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                method.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: effectiveIsSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: badgeColor ?? Colors.blue,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badge!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          customSubtitle ?? method.subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Animated check / radio
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: effectiveIsSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.shade300,
                        width: effectiveIsSelected ? 2 : 1.5,
                      ),
                      color: effectiveIsSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                    child: effectiveIsSelected
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
