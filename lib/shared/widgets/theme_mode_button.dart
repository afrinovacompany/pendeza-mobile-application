import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pendeza/app/bloc/theme_cubit.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';

/// Icon for a [ThemeMode]: sun (light), moon (dark) or half-circle (system).
IconData themeModeIcon(ThemeMode mode) => switch (mode) {
      ThemeMode.light => CupertinoIcons.sun_max_fill,
      ThemeMode.dark => CupertinoIcons.moon_fill,
      ThemeMode.system => CupertinoIcons.circle_lefthalf_fill,
    };

String themeModeLabel(ThemeMode mode) => switch (mode) {
      ThemeMode.light => 'appearance.light'.tr(),
      ThemeMode.dark => 'appearance.dark'.tr(),
      ThemeMode.system => 'appearance.system'.tr(),
    };

/// A round button showing the current theme mode; tap to choose another.
///
/// [onDark] renders the translucent "glass" look used on the brand hero
/// headers; otherwise it is a plain card-coloured button.
class ThemeModeButton extends StatelessWidget {
  final bool onDark;
  final double size;

  const ThemeModeButton({super.key, this.onDark = false, this.size = 46});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, mode) => Tooltip(
        message: '${'appearance.title'.tr()}: ${themeModeLabel(mode)}',
        child: Material(
          color: onDark ? Colors.white.withValues(alpha: 0.20) : cs.surface,
          shape: CircleBorder(
            side: BorderSide(
              color: onDark
                  ? Colors.white.withValues(alpha: 0.28)
                  : cs.outline.withValues(alpha: 0.6),
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => showThemeModeSheet(context),
            child: SizedBox(
              width: size,
              height: size,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => RotationTransition(
                  turns: Tween<double>(begin: 0.85, end: 1).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Icon(
                  themeModeIcon(mode),
                  key: ValueKey(mode),
                  size: 21,
                  color: onDark ? Colors.white : cs.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet with the three appearance options.
Future<void> showThemeModeSheet(BuildContext context) {
  final cubit = context.read<ThemeCubit>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: const _ThemeModeSheet(),
    ),
  );
}

class _ThemeModeSheet extends StatelessWidget {
  const _ThemeModeSheet();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, current) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'appearance.title'.tr(),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'appearance.subtitle'.tr(),
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 13,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            for (final mode in const [
              ThemeMode.system,
              ThemeMode.light,
              ThemeMode.dark,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ModeTile(
                  mode: mode,
                  selected: mode == current,
                  onTap: () {
                    context.read<ThemeCubit>().setThemeMode(mode);
                    Navigator.of(context).pop();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTile({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  String get _subtitle => switch (mode) {
        ThemeMode.system => 'appearance.system_desc'.tr(),
        ThemeMode.light => 'appearance.light_desc'.tr(),
        ThemeMode.dark => 'appearance.dark_desc'.tr(),
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: selected ? cs.primary.withValues(alpha: 0.10) : cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: selected ? cs.primary : cs.outline.withValues(alpha: 0.6),
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: selected ? AppColors.primaryGradient : null,
                  color: selected ? null : cs.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  themeModeIcon(mode),
                  size: 20,
                  color: selected ? Colors.white : cs.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      themeModeLabel(mode),
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      _subtitle,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 12.5,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(CupertinoIcons.checkmark_circle_fill,
                    color: cs.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
