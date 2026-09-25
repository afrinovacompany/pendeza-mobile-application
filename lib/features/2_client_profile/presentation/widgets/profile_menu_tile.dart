import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

class ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;
  final bool showChevron;
  final bool isDestructive;

  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor,
    this.showChevron = true,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveIconColor = isDestructive
        ? theme.colorScheme.error
        : (iconColor ?? theme.colorScheme.primary);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            ClientIconTile(icon: icon, color: effectiveIconColor, size: 42),
            const SizedBox(width: 14),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: ClientTheme.heading(context).copyWith(
                      color: isDestructive ? theme.colorScheme.error : null,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: ClientTheme.caption(context)),
                  ],
                ],
              ),
            ),

            // Trailing Widget
            if (trailing != null) trailing!,

            if (showChevron && trailing == null)
              Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: ClientTheme.textSecondary(context),
              ),
          ],
        ),
      ),
    );
  }
}
