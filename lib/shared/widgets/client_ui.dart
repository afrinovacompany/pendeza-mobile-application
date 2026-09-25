import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';

/// Shared building blocks for the client-facing screens (dashboard, profile…).
///
/// Colours are derived from the active [ThemeData] so light and dark mode both
/// work; the brand purple gradient is the one deliberate constant.

// ═════════════════════════════════════════════════════════════════════════════
// TOKENS
// ═════════════════════════════════════════════════════════════════════════════

class ClientTheme {
  ClientTheme._();

  static const double gutter = 20;

  static bool isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Page background. Slightly tinted in light mode so white cards separate
  /// from it (the app's light background is almost pure white).
  static Color background(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    if (isDark(c)) return cs.surfaceContainerLowest;
    return Color.alphaBlend(
      cs.primary.withValues(alpha: 0.04),
      const Color(0xFFF7F7FB),
    );
  }

  static Color card(BuildContext c) => Theme.of(c).colorScheme.surface;

  /// [tint] washed over the card colour – a selected / highlighted card that
  /// stays opaque (a translucent fill would pick up the page background).
  static Color tinted(BuildContext c, Color tint,
          {double light = 0.07, double dark = 0.16}) =>
      Color.alphaBlend(
        tint.withValues(alpha: isDark(c) ? dark : light),
        card(c),
      );

  static Color inset(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return isDark(c)
        ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
        : cs.primary.withValues(alpha: 0.05);
  }

  static Color border(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return isDark(c) ? cs.outline : cs.outline.withValues(alpha: 0.6);
  }

  static Color textPrimary(BuildContext c) =>
      Theme.of(c).colorScheme.onSurface;

  static Color textSecondary(BuildContext c) =>
      Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.62);

  static List<BoxShadow> shadow(BuildContext c) =>
      isDark(c) ? const [] : AppColors.lightShadowSm;

  /// Brand hero gradient (deeper in dark mode so white text stays readable).
  static LinearGradient heroGradient(BuildContext c) => isDark(c)
      ? const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B3BB8), Color(0xFF6C5CE7)],
        )
      : const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C5CE7), Color(0xFF8C7CF0)],
        );

  // ── typography ────────────────────────────────────────────────────────────

  static TextStyle display(BuildContext c) => TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -0.4,
        color: textPrimary(c),
      );

  static TextStyle title(BuildContext c) => TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 19,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.2,
        color: textPrimary(c),
      );

  static TextStyle heading(BuildContext c) => TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: textPrimary(c),
      );

  static TextStyle body(BuildContext c) => TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: textPrimary(c),
      );

  static TextStyle caption(BuildContext c) => TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: textSecondary(c),
      );

  static TextStyle label(BuildContext c) => TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: 0.6,
        color: textSecondary(c),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
// HERO
// ═════════════════════════════════════════════════════════════════════════════

/// Brand gradient panel with soft glows – the header of dashboard and profile.
class ClientBrandHero extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final EdgeInsetsGeometry margin;

  const ClientBrandHero({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 30,
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(
              alpha: ClientTheme.isDark(context) ? 0.18 : 0.30,
            ),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: ClientTheme.heroGradient(context),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: -50,
                top: -60,
                child: _Glow(size: 220, alpha: 0.16),
              ),
              Positioned(
                left: -70,
                bottom: -90,
                child: _Glow(
                  size: 240,
                  alpha: 0.30,
                  color: AppColors.primaryLight,
                ),
              ),
              const Positioned(
                right: 40,
                bottom: -40,
                child: _Glow(size: 120, alpha: 0.18, color: AppColors.accent),
              ),
              // Keep hero copy from outgrowing the panel at huge text sizes.
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.2,
                child: Padding(padding: padding, child: child),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final double alpha;
  final Color color;

  const _Glow({
    required this.size,
    required this.alpha,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              color.withValues(alpha: 0),
            ],
          ),
        ),
      );
}

/// Gradient call-to-action button. Shows a spinner while [isLoading] and greys
/// out when [onPressed] is null.
class ClientPrimaryButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  const ClientPrimaryButton({
    super.key,
    required this.text,
    this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final active = enabled || isLoading;
    final muted = ClientTheme.textSecondary(context);

    return Semantics(
      button: true,
      enabled: enabled,
      label: text,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          color: active
              ? null
              : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(18),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              text,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppTextStyles.fontFamily,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                                color: enabled ? Colors.white : muted,
                              ),
                            ),
                            if (icon != null) ...[
                              const SizedBox(width: 8),
                              Icon(
                                icon,
                                size: 18,
                                color: enabled ? Colors.white : muted,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact brand header for pushed screens: back button, title, optional
/// subtitle and trailing actions.
class ClientPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onBack;

  /// Hide the back button on screens that are tab roots.
  final bool showBack;

  const ClientPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onBack,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return ClientBrandHero(
      radius: 28,
      padding: EdgeInsets.fromLTRB(showBack ? 14 : 20, 14, 14, 14),
      child: Row(
        children: [
          if (showBack) ...[
            GlassCircleButton(
              icon: CupertinoIcons.back,
              size: 42,
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
          for (final action in actions) ...[
            const SizedBox(width: 8),
            action,
          ],
        ],
      ),
    );
  }
}

/// Translucent white circle button used on top of [ClientBrandHero].
class GlassCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final int badgeCount;
  final double size;

  const GlassCircleButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.badgeCount = 0,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.white.withValues(alpha: 0.20),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );

    return Tooltip(
      message: tooltip ?? '',
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          if (badgeCount > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF6C5CE7), width: 2),
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
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

// ═════════════════════════════════════════════════════════════════════════════
// SURFACES
// ═════════════════════════════════════════════════════════════════════════════

class ClientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? color;
  final Color? borderColor;

  const ClientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 22,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? ClientTheme.border(context)),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: ClientTheme.shadow(context),
      ),
      child: Material(
        color: color ?? ClientTheme.card(context),
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Rounded square icon holder. [color] tints it; [solid] fills it with a
/// gradient of that colour and a white glyph.
class ClientIconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final bool solid;

  const ClientIconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.solid = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.32);
    if (solid) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(color, Colors.white, 0.18)!,
              Color.lerp(color, Colors.black, 0.12)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
              spreadRadius: -3,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.48),
      );
    }
    final dark = ClientTheme.isDark(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.20 : 0.12),
        borderRadius: radius,
      ),
      child: Icon(
        icon,
        color: dark ? Color.lerp(color, Colors.white, 0.25) : color,
        size: size * 0.5,
      ),
    );
  }
}

class ClientPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool onDark;

  const ClientPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final dark = ClientTheme.isDark(context);
    final fg = onDark
        ? Colors.white
        : (dark ? Color.lerp(color, Colors.white, 0.25)! : color);
    final bg = onDark
        ? Colors.white.withValues(alpha: 0.20)
        : color.withValues(alpha: dark ? 0.20 : 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
        border: onDark
            ? Border.all(color: Colors.white.withValues(alpha: 0.28))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: AppTextStyles.fontFamily,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECTION HEADER
// ═════════════════════════════════════════════════════════════════════════════

class ClientSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Extra widget shown before the action (e.g. a status pill).
  final Widget? trailing;

  const ClientSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ClientTheme.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ClientTheme.title(context),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: ClientTheme.caption(context)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(100),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: TextStyle(
                        fontFamily: AppTextStyles.fontFamily,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ClientTheme.isDark(context)
                            ? cs.primary
                            : AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      CupertinoIcons.arrow_right,
                      size: 14,
                      color: ClientTheme.isDark(context)
                          ? cs.primary
                          : AppColors.primaryDark,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small rotating tint list so categories/menus get varied but on-brand
/// colours without hand-picking each one.
class ClientPalette {
  ClientPalette._();

  static const List<Color> tones = [
    AppColors.primary,
    Color(0xFFFF7A90), // rose
    Color(0xFF00B894), // mint
    Color(0xFFF5A623), // amber
    Color(0xFF4DA3FF), // sky
    Color(0xFFB57BFF), // orchid
  ];

  static Color at(int index) => tones[index % tones.length];

  /// Stable pseudo-random pick for a string key (e.g. a category id).
  static Color forKey(String key) =>
      at(key.codeUnits.fold<int>(0, (a, b) => a + b) % tones.length);
}

// ═════════════════════════════════════════════════════════════════════════════
// STATES + TABS
// ═════════════════════════════════════════════════════════════════════════════

/// Friendly empty / error state: a soft halo icon, a title, a message and an
/// optional call-to-action.
class ClientEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  const ClientEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tone = color ?? Theme.of(context).colorScheme.primary;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 116,
                height: 116,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tone.withValues(alpha: 0.22),
                      tone.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child: ClientIconTile(
                  icon: icon,
                  color: tone,
                  size: 64,
                  solid: true,
                ),
              ),
              const SizedBox(height: 22),
              Text(
                title,
                textAlign: TextAlign.center,
                style: ClientTheme.title(context),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: ClientTheme.caption(context).copyWith(
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Pill-style segmented control driven by a [TabController] (or the nearest
/// [DefaultTabController]).
class ClientSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final TabController? controller;

  const ClientSegmentedTabs({super.key, required this.labels, this.controller});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ink = ClientTheme.isDark(context) ? cs.primary : AppColors.primaryDark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ClientTheme.inset(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ClientTheme.border(context)),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.15,
        child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(14),
        labelPadding: EdgeInsets.zero,
        labelColor: ink,
        unselectedLabelColor: ClientTheme.textSecondary(context),
        labelStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTextStyles.fontFamily,
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        indicator: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: ClientTheme.shadow(context),
        ),
        tabs: [
          for (final label in labels) Tab(height: 42, text: label),
        ],
        ),
      ),
    );
  }
}
