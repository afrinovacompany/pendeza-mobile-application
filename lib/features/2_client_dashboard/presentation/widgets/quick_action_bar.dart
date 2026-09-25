import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

import '../../../../app/config/app_router.dart';

/// Four shortcut tiles under the dashboard header.
///
/// Navigation is intentionally unchanged from the previous version.
class QuickActionsBar extends StatelessWidget {
  final Function(String action)? onActionTap;

  const QuickActionsBar({super.key, this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
      // IntrinsicHeight: equal-height tiles inside a sliver (unbounded height).
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _QuickAction(
                label: 'client.dashboard.quick_actions.offers'.tr(),
                icon: CupertinoIcons.tag_fill,
                color: const Color(0xFFFF7A90),
                onTap: () {
                  onActionTap?.call('offers');
                  // Navigate to discovery without extra filter
                  // Discovery screen will handle "offers" logic internally if needed
                  context.go(AppRoutes.clientDiscover);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                label: 'client.dashboard.quick_actions.near_me'.tr(),
                icon: CupertinoIcons.location_solid,
                color: ClientPalette.tones[0],
                onTap: () {
                  onActionTap?.call('near_me');
                  // Navigate to discovery without extra filter
                  // Discovery screen will handle "near_me" logic internally if needed
                  context.go(AppRoutes.clientDiscover);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                label: 'client.dashboard.quick_actions.trending'.tr(),
                icon: CupertinoIcons.flame_fill,
                color: const Color(0xFFF5A623),
                onTap: () {
                  onActionTap?.call('trending');
                  // Navigate to discovery without extra filter
                  // Discovery screen will handle "trending" logic internally if needed
                  context.go(AppRoutes.clientDiscover);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                label: 'client.dashboard.quick_actions.saved'.tr(),
                icon: CupertinoIcons.heart_fill,
                color: const Color(0xFFB57BFF),
                onTap: () {
                  onActionTap?.call('favorites');
                  context.push('/client/favorites');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClientCard(
      onTap: onTap,
      radius: 20,
      padding: const EdgeInsets.fromLTRB(6, 14, 6, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClientIconTile(icon: icon, color: color, size: 48, solid: true),
          const SizedBox(height: 10),
          // Tiny caption: don't let system text scaling break words apart.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 30),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTheme.body(context).copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
