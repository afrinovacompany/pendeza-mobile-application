import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/shared/models/category_model.dart';
import 'package:pendeza/shared/utils/placeholder_images.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

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
    final childAspectRatio = screenWidth > 600 ? 2.0 : 1.75;

    return GridView.builder(
      padding: EdgeInsets.zero, // parent handles padding
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: displayList.length,
      itemBuilder: (context, index) => _CategoryCard(
        category: displayList[index],
        tone: ClientPalette.at(index),
        onTap: () => onCategorySelected(displayList[index].id),
      ),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  final CategoryModel category;
  final Color tone;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.tone,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  /// Local asset first, then a network fallback if the asset is missing.
  Widget _buildCategoryImage(Color fallbackColor) {
    if (widget.category.iconUrl == null) return const SizedBox.shrink();

    Widget fallback() => Center(
          child: Icon(
            CupertinoIcons.sparkles,
            color: fallbackColor.withValues(alpha: 0.35),
            size: 30,
          ),
        );

    return Image.asset(
      widget.category.iconUrl!,
      fit: BoxFit.cover,
      alignment: Alignment.bottomCenter,
      errorBuilder: (context, error, stackTrace) {
        final networkUrl = PlaceholderImages.forCategory(widget.category.id);
        if (networkUrl == null) return fallback();
        return CachedNetworkImage(
          imageUrl: networkUrl,
          fit: BoxFit.cover,
          alignment: Alignment.bottomCenter,
          placeholder: (context, url) => fallback(),
          errorWidget: (context, url, error) => fallback(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = ClientTheme.isDark(context);
    final tone = widget.tone;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                tone.withValues(alpha: dark ? 0.30 : 0.20),
                tone.withValues(alpha: dark ? 0.12 : 0.06),
              ],
            ),
            border: Border.all(color: tone.withValues(alpha: dark ? 0.28 : 0.18)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageWidth = constraints.maxWidth * 0.42;
              return Stack(
                children: [
                  // Photo, clipped to the tile's right edge.
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    width: imageWidth,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(22),
                        bottomRight: Radius.circular(22),
                      ),
                      child: _buildCategoryImage(tone),
                    ),
                  ),
                  // Label + arrow.
                  Positioned.fill(
                    child: Padding(
                      // Keep the label clear of the photo on the right.
                      padding: EdgeInsets.fromLTRB(14, 14, imageWidth + 6, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'categories.${widget.category.name}'.tr(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: ClientTheme.heading(context).copyWith(
                              fontSize: 13.5,
                              height: 1.2,
                            ),
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: tone.withValues(alpha: dark ? 0.35 : 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              CupertinoIcons.arrow_up_right,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
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
