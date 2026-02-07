import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';

class SalonDescriptionSection extends StatefulWidget {
  final SalonModel salon;

  const SalonDescriptionSection({super.key, required this.salon});

  @override
  State<SalonDescriptionSection> createState() => _SalonDescriptionSectionState();
}

class _SalonDescriptionSectionState extends State<SalonDescriptionSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expandController;
  late Animation<double> _iconRotation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _iconRotation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _expandController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _expandController.forward();
      } else {
        _expandController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = widget.salon.description ?? 'No description available.';
    final hasLongDescription = description.length > 150;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.1),
                      theme.colorScheme.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  CupertinoIcons.info_circle_fill,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'About ${widget.salon.salonName}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.padM),

          // Description with smooth expansion
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded
                ? _buildExpandedDescription(theme, description)
                : _buildCollapsedDescription(theme, description),
          ),

          // See More/Less Button
          if (hasLongDescription)
            Padding(
              padding: const EdgeInsets.only(top: AppConstants.padS),
              child: GestureDetector(
                onTap: _toggleExpanded,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.1),
                        theme.colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded ? 'Show Less' : 'Read More',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      RotationTransition(
                        turns: _iconRotation,
                        child: Icon(
                          CupertinoIcons.chevron_down,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: AppConstants.padL),
          _buildServiceCategories(context, widget.salon.serviceCategories),
        ],
      ),
    );
  }

  Widget _buildCollapsedDescription(ThemeData theme, String description) {
    return Text(
      description,
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildExpandedDescription(ThemeData theme, String description) {
    return Text(
      description,
      style: theme.textTheme.bodyLarge?.copyWith(
        height: 1.6,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildServiceCategories(BuildContext context, List<String> categories) {
    final theme = Theme.of(context);

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              CupertinoIcons.tag_fill,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Services Offered',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.padS),
        Wrap(
          spacing: AppConstants.padS,
          runSpacing: AppConstants.padS,
          children: categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;

            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                // BUG FIX: Curves.easeOutBack can overshoot 1.0 or go below 0.0.
                // We must clamp the value for Opacity to prevent crashes.
                final safeOpacity = value.clamp(0.0, 1.0);

                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: safeOpacity,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.padM,
                        vertical: AppConstants.padS,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.15),
                            theme.colorScheme.secondary.withValues(alpha: 0.15),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}