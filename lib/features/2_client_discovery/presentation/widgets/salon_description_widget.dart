import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/shared/models/salon_model.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

/// "About" card of the salon overview: description with read-more and the
/// categories the salon offers.
class SalonDescriptionSection extends StatefulWidget {
  final SalonModel salon;

  const SalonDescriptionSection({super.key, required this.salon});

  @override
  State<SalonDescriptionSection> createState() =>
      _SalonDescriptionSectionState();
}

class _SalonDescriptionSectionState extends State<SalonDescriptionSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final raw = widget.salon.description?.trim();
    final hasDescription = raw != null && raw.isNotEmpty;
    final description =
        hasDescription ? raw : 'client.salon_details.no_description'.tr();
    final hasLongDescription = hasDescription && raw.length > 150;
    final accent = ClientTheme.isDark(context)
        ? Theme.of(context).colorScheme.primary
        : AppColors.primaryDark;
    final categories = widget.salon.serviceCategories;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
      child: ClientCard(
        padding: const EdgeInsets.all(18),
        radius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ClientIconTile(
                  icon: CupertinoIcons.info_circle_fill,
                  color: AppColors.primary,
                  size: 38,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'client.salon_details.about'
                        .tr(args: [widget.salon.salonName]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ClientTheme.heading(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Text(
                description,
                maxLines: _isExpanded ? null : 4,
                overflow:
                    _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                style: ClientTheme.body(context).copyWith(
                  height: 1.6,
                  color: hasDescription
                      ? ClientTheme.textSecondary(context)
                      : ClientTheme.textSecondary(context)
                          .withValues(alpha: 0.7),
                  fontStyle: hasDescription ? null : FontStyle.italic,
                ),
              ),
            ),
            if (hasLongDescription)
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isExpanded
                            ? 'client.salon_details.show_less'.tr()
                            : 'client.salon_details.read_more'.tr(),
                        style: TextStyle(
                          fontFamily: AppTextStyles.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 250),
                        child: Icon(
                          CupertinoIcons.chevron_down,
                          size: 14,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (categories.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(height: 1, color: ClientTheme.border(context)),
              const SizedBox(height: 14),
              Text(
                'client.salon_details.offered'.tr().toUpperCase(),
                style: ClientTheme.label(context),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final category in categories)
                    _CategoryChip(label: category),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;

  const _CategoryChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = ClientPalette.forKey(label);
    final dark = ClientTheme.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.20 : 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: dark ? Color.lerp(color, Colors.white, 0.3) : color,
        ),
      ),
    );
  }
}
