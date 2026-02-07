import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/category_model.dart';

class CategoryGridWidget extends StatelessWidget {
  final List<CategoryModel> categories;
  final Function(String categoryId) onCategorySelected;
  final bool showAll;

  const CategoryGridWidget({
    super.key,
    required this.categories,
    required this.onCategorySelected,
    this.showAll = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayList = showAll ? categories : categories.take(6).toList();

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppConstants.padM,
        mainAxisSpacing: AppConstants.padM,
        childAspectRatio: 2.4,
      ),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 300 + (index * 80)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: child,
              ),
            );
          },
          child: _CategoryCard(
            category: displayList[index],
            onTap: () => onCategorySelected(displayList[index].id),
          ),
        );
      },
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : const Color(0xFFF5F7FA);

    final textColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: isDark
                ? Border.all(
              color: Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary.withValues(alpha: 0.02),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              // Text
              Positioned.fill(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 60.0,
                    ),
                    child: Text(
                      widget.category.name.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.2,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),

              // Image
              Positioned(
                right: 0,
                bottom: 0,
                top: 0,
                width: 75,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: widget.category.iconUrl != null
                      ? Image.asset(
                    widget.category.iconUrl!,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.spa,
                          color: textColor.withValues(alpha: 0.2),
                          size: 28,
                        ),
                      );
                    },
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}