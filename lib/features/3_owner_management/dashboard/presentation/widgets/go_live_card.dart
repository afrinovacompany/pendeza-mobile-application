import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/config/app_router.dart';
import '../../../../../app/config/theme/app_constants.dart';
import '../../domain/models/go_live_checklist.dart';

class GoLiveCard extends StatelessWidget {
  final GoLiveChecklist checklist;

  const GoLiveCard({super.key, required this.checklist});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Established, listed salons don't need a daily "you're live" nag.
    if (checklist.isListed && checklist.isComplete) {
      return const SizedBox.shrink();
    }

    if (checklist.isPending) {
      return _banner(
        context,
        theme,
        icon: CupertinoIcons.clock_fill,
        color: theme.colorScheme.secondary,
        title: 'owner.dashboard.golive_pending_title'.tr(),
        body: 'owner.dashboard.golive_pending_body'.tr(),
        showChecklist: !checklist.isComplete,
      );
    }

    if (checklist.isRejected) {
      final reason = checklist.rejectionReason?.trim();
      return _banner(
        context,
        theme,
        icon: CupertinoIcons.exclamationmark_triangle_fill,
        color: theme.colorScheme.error,
        title: 'owner.dashboard.golive_rejected_title'.tr(),
        body: (reason != null && reason.isNotEmpty)
            ? reason
            : 'owner.dashboard.golive_pending_body'.tr(),
        showChecklist: true,
      );
    }

    return _banner(
      context,
      theme,
      icon: CupertinoIcons.info_circle_fill,
      color: theme.colorScheme.primary,
      title: 'owner.dashboard.golive_approved_incomplete_title'.tr(),
      body: 'owner.dashboard.golive_approved_incomplete_body'.tr(),
      showChecklist: true,
    );
  }

  Widget _banner(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required bool showChecklist,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.padL),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppConstants.radiusL,
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: AppConstants.padS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (showChecklist) ...[
            const SizedBox(height: AppConstants.padM),
            Text(
              'owner.dashboard.golive_checklist_title'.tr(),
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppConstants.padS),
            _item(
              context,
              done: checklist.hasPhoto,
              label: 'owner.dashboard.golive_photo'.tr(),
              onTap: () => context.push(AppRoutes.ownerSalonProfile),
            ),
            _item(
              context,
              done: checklist.hasHours,
              label: 'owner.dashboard.golive_hours'.tr(),
              onTap: () => context.push(AppRoutes.ownerSalonProfile),
            ),
            _item(
              context,
              done: checklist.hasPhone,
              label: 'owner.dashboard.golive_phone'.tr(),
              onTap: () => context.push(AppRoutes.ownerSalonProfile),
            ),
            _item(
              context,
              done: checklist.hasService,
              label: 'owner.dashboard.golive_service'.tr(),
              onTap: () => context.go(AppRoutes.ownerServices),
            ),
          ],
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required bool done,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: done ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              done
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              size: 20,
              color: done
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: theme.colorScheme.onSurface.withValues(
                    alpha: done ? 0.5 : 0.9,
                  ),
                ),
              ),
            ),
            if (!done)
              Icon(
                CupertinoIcons.chevron_right,
                size: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}
