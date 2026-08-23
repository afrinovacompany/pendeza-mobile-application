import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/shared/models/category_model.dart';
import 'package:pendeza/shared/utils/placeholder_images.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive: 2 columns for phones, 3 for tablets
    final crossAxisCount = screenWidth > 600 ? 3 : 2;
    // Adjust aspect ratio based on screen width
    final childAspectRatio = screenWidth > 600 ? 2.6 : 2.4;

    return GridView.builder(
      padding: EdgeInsets.zero, // Remove internal padding - parent handles it
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: AppConstants.padM,
        mainAxisSpacing: AppConstants.padM,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        // Simplified animation - single fade-in for entire grid on load
        return _CategoryCard(
          category: displayList[index],
          onTap: () => onCategorySelected(displayList[index].id),
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

  /// Builds the category image: tries local asset first, then falls back
  /// to a network image from Unsplash if the local asset is missing.
  Widget _buildCategoryImage(Color textColor) {
    if (widget.category.iconUrl == null) return const SizedBox.shrink();

    return Image.asset(
      widget.category.iconUrl!,
      fit: BoxFit.cover,
      alignment: Alignment.bottomCenter,
      errorBuilder: (context, error, stackTrace) {
        // Local asset missing - try network fallback
        final networkUrl = PlaceholderImages.forCategory(widget.category.id);
        if (networkUrl != null) {
          return CachedNetworkImage(
            imageUrl: networkUrl,
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            placeholder: (context, url) => Center(
              child: Icon(
                Icons.spa,
                color: textColor.withValues(alpha: 0.15),
                size: 28,
              ),
            ),
            errorWidget: (context, url, error) => Center(
              child: Icon(
                Icons.spa,
                color: textColor.withValues(alpha: 0.2),
                size: 28,
              ),
            ),
          );
        }
        return Center(
          child: Icon(
            Icons.spa,
            color: textColor.withValues(alpha: 0.2),
            size: 28,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.colorScheme.surfaceContainerHighest;
    final textColor = theme.colorScheme.onSurface;

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
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: isDark ? 0.2 : 0.08),
              width: isDark ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive dimensions once
              final imageWidth = (constraints.maxWidth * 0.38).clamp(60.0, 90.0);
              final textRightPadding = (constraints.maxWidth * 0.40).clamp(50.0, 80.0);

              return Stack(
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

                  // Text - adaptive padding
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 14.0,
                          right: textRightPadding,
                        ),
                        child: Text(
                          'categories.${widget.category.name}'.tr(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            height: 1.2,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),

                  // Image - responsive width
                  Positioned(
                    right: 0,
                    bottom: 0,
                    top: 0,
                    width: imageWidth,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      child: _buildCategoryImage(textColor),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}