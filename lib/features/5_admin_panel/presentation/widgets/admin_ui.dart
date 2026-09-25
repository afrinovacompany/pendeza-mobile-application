import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/shared/widgets/loading_indicator.dart';
import 'package:pendeza/shared/widgets/theme_mode_button.dart';

/// Shared building blocks for the admin panel.
///
/// Everything here derives its colours from the active [ThemeData] (plus the
/// brand/semantic palette in [AppColors]), so the admin side follows light and
/// dark mode exactly like the rest of the app instead of hard-coding
/// `Colors.red` / `Colors.green` / `Colors.grey`.

// ═════════════════════════════════════════════════════════════════════════════
// TOKENS
// ═════════════════════════════════════════════════════════════════════════════

/// Semantic colour roles used by pills, stat tiles, buttons and dialogs.
enum AdminTone { neutral, primary, accent, success, warning, danger, info }

class AdminTheme {
  AdminTheme._();

  static const double maxContentWidth = 1180;
  static const double wideBreakpoint = 900;

  static bool isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Horizontal page gutter that grows with the viewport.
  static double gutter(double width) => width < 600 ? 16 : 24;

  /// Page background. Slightly tinted in light mode so white cards actually
  /// separate from it (the app's light background is almost pure white).
  static Color background(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    if (isDark(c)) return cs.surfaceContainerLowest;
    return Color.alphaBlend(
      cs.primary.withValues(alpha: 0.045),
      const Color(0xFFF6F6FA),
    );
  }

  static Color card(BuildContext c) => Theme.of(c).colorScheme.surface;

  /// Slightly raised fill for inset areas inside a card.
  static Color inset(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return isDark(c)
        ? cs.surfaceContainerHighest.withValues(alpha: 0.55)
        : cs.primary.withValues(alpha: 0.05);
  }

  static Color border(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    return isDark(c) ? cs.outline : cs.outline.withValues(alpha: 0.7);
  }

  static Color textPrimary(BuildContext c) =>
      Theme.of(c).colorScheme.onSurface;

  static Color textSecondary(BuildContext c) =>
      Theme.of(c).colorScheme.onSurface.withValues(alpha: 0.62);

  static List<BoxShadow> shadow(BuildContext c) =>
      isDark(c) ? const [] : AppColors.lightShadowSm;

  /// Fill / icon colour for a tone.
  static Color toneBase(BuildContext c, AdminTone tone) {
    final cs = Theme.of(c).colorScheme;
    switch (tone) {
      case AdminTone.neutral:
        return cs.onSurface.withValues(alpha: 0.55);
      case AdminTone.primary:
        return cs.primary;
      case AdminTone.accent:
        return AppColors.accent;
      case AdminTone.success:
        return AppColors.success;
      case AdminTone.warning:
        return const Color(0xFFF5A623);
      case AdminTone.danger:
        return AppColors.error;
      case AdminTone.info:
        return AppColors.info;
    }
  }

  /// Text-safe colour for a tone (darker in light mode for contrast).
  static Color toneInk(BuildContext c, AdminTone tone) {
    final cs = Theme.of(c).colorScheme;
    final dark = isDark(c);
    switch (tone) {
      case AdminTone.neutral:
        return textSecondary(c);
      case AdminTone.primary:
        return dark ? cs.primary : AppColors.primaryDark;
      case AdminTone.accent:
        return dark ? AppColors.accent : const Color(0xFFB2482D);
      case AdminTone.success:
        return dark ? AppColors.successLight : const Color(0xFF007A63);
      case AdminTone.warning:
        return dark ? AppColors.warning : const Color(0xFF8A5A00);
      case AdminTone.danger:
        return dark ? AppColors.errorLight : const Color(0xFFC62F2F);
      case AdminTone.info:
        return dark ? AppColors.info : const Color(0xFF1F6FB5);
    }
  }

  static Color toneTint(BuildContext c, AdminTone tone, {double? alpha}) =>
      toneBase(c, tone).withValues(alpha: alpha ?? (isDark(c) ? 0.2 : 0.12));

  /// [toneTint] flattened onto the card colour, so it stays clean when it
  /// sits directly on the (tinted) page background instead of on a card.
  static Color toneSurface(BuildContext c, AdminTone tone, {double alpha = 0.10}) =>
      Color.alphaBlend(toneBase(c, tone).withValues(alpha: alpha), card(c));

  // ── Typography (Poppins via theme, sized for dense admin content) ─────────

  static TextStyle title(BuildContext c) => TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: textPrimary(c),
      );

  static TextStyle heading(BuildContext c) => TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: 16,
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
        letterSpacing: 0.3,
        color: textSecondary(c),
      );

  // ── Buttons ───────────────────────────────────────────────────────────────

  static const _buttonText = TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static ButtonStyle filledButton(
    BuildContext c, {
    AdminTone tone = AdminTone.primary,
  }) {
    final cs = Theme.of(c).colorScheme;
    final dark = isDark(c);
    Color fill;
    Color fg;
    switch (tone) {
      case AdminTone.primary:
        fill = cs.primary;
        fg = cs.onPrimary;
        break;
      case AdminTone.success:
        fill = dark ? AppColors.success : const Color(0xFF00896C);
        fg = dark ? const Color(0xFF06231C) : Colors.white;
        break;
      case AdminTone.danger:
        fill = dark ? AppColors.errorLight : const Color(0xFFD64545);
        fg = dark ? const Color(0xFF2A0B0B) : Colors.white;
        break;
      case AdminTone.info:
        fill = dark ? AppColors.info : const Color(0xFF2B7CC4);
        fg = dark ? const Color(0xFF071B2E) : Colors.white;
        break;
      case AdminTone.warning:
        fill = toneBase(c, tone);
        fg = const Color(0xFF2B1B00);
        break;
      case AdminTone.accent:
        fill = toneBase(c, tone);
        fg = const Color(0xFF3A1409);
        break;
      case AdminTone.neutral:
        fill = cs.onSurface.withValues(alpha: 0.85);
        fg = cs.surface;
        break;
    }
    return FilledButton.styleFrom(
      backgroundColor: fill,
      foregroundColor: fg,
      disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
      disabledForegroundColor: cs.onSurface.withValues(alpha: 0.38),
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      textStyle: _buttonText,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.radiusM),
      elevation: 0,
    );
  }

  static ButtonStyle outlinedButton(
    BuildContext c, {
    AdminTone tone = AdminTone.primary,
  }) {
    final ink = toneInk(c, tone);
    return OutlinedButton.styleFrom(
      foregroundColor: ink,
      minimumSize: const Size(0, 46),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      textStyle: _buttonText,
      side: BorderSide(color: toneBase(c, tone).withValues(alpha: 0.6)),
      shape: RoundedRectangleBorder(borderRadius: AppConstants.radiusM),
    );
  }

  static ButtonStyle textButton(
    BuildContext c, {
    AdminTone tone = AdminTone.primary,
  }) {
    return TextButton.styleFrom(
      foregroundColor: toneInk(c, tone),
      minimumSize: const Size(0, 44),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      textStyle: _buttonText,
      shape: RoundedRectangleBorder(borderRadius: AppConstants.radiusM),
    );
  }
}

/// Semantic tone for a user role.
AdminTone adminRoleTone(String? role) {
  switch (role) {
    case 'admin':
      return AdminTone.danger;
    case 'owner':
      return AdminTone.info;
    case 'client':
      return AdminTone.success;
    default:
      return AdminTone.neutral;
  }
}

/// Human readable role label ("owner" → "Owner").
String adminRoleLabel(String? role) {
  if (role == null || role.isEmpty) return 'No role';
  return role[0].toUpperCase() + role.substring(1);
}

// ═════════════════════════════════════════════════════════════════════════════
// SHELL SCOPE
// ═════════════════════════════════════════════════════════════════════════════

/// Lets pages ask the shell for shell-level actions without importing it.
class AdminShellScope extends InheritedWidget {
  /// True when the shell is showing the compact (phone) layout, which has no
  /// sidebar and therefore needs an account/sign-out action in each header.
  final bool compact;
  final VoidCallback onLogout;

  const AdminShellScope({
    super.key,
    required this.compact,
    required this.onLogout,
    required super.child,
  });

  static AdminShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AdminShellScope>();

  @override
  bool updateShouldNotify(AdminShellScope old) => compact != old.compact;
}

// ═════════════════════════════════════════════════════════════════════════════
// PAGE
// ═════════════════════════════════════════════════════════════════════════════

/// Standard admin page: one consistent header (no stacked app bars), an
/// optional pinned toolbar under it, and width-constrained content.
class AdminPage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget> actions;

  /// Pinned under the header (search field, tabs…). Padded by the page gutter.
  final Widget? toolbar;

  /// Pinned under [toolbar]. Full-bleed: it manages its own gutter so a
  /// horizontally scrolling [AdminFilterBar] can scroll edge to edge.
  final Widget? filters;
  final Widget child;
  final Widget? floatingActionButton;

  const AdminPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.actions = const [],
    this.toolbar,
    this.filters,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final shell = AdminShellScope.maybeOf(context);
    final width = MediaQuery.sizeOf(context).width;
    final gutter = AdminTheme.gutter(width);

    return Scaffold(
      backgroundColor: AdminTheme.background(context),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AdminTheme.maxContentWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(gutter, 16, gutter, 12),
                  child: Row(
                    children: [
                      if (icon != null) ...[
                        AdminIconTile(icon: icon!, gradient: true),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AdminTheme.title(context),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (subtitle != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  subtitle!,
                                  style: AdminTheme.caption(context),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      ...actions,
                      if (shell != null && shell.compact)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: ThemeModeButton(size: 44),
                        ),
                      if (shell != null && shell.compact)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: IconButton(
                            tooltip: 'Sign out',
                            onPressed: shell.onLogout,
                            style: IconButton.styleFrom(
                              backgroundColor: AdminTheme.card(context),
                              foregroundColor:
                                  AdminTheme.textSecondary(context),
                              side: BorderSide(
                                  color: AdminTheme.border(context)),
                            ),
                            icon: const Icon(
                              CupertinoIcons.square_arrow_right,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (toolbar != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 8),
                    child: toolbar!,
                  ),
                if (filters != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 8),
                    child: filters!,
                  ),
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SURFACES
// ═════════════════════════════════════════════════════════════════════════════

class AdminCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final Clip clipBehavior;

  const AdminCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = 18,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor ?? AdminTheme.border(context)),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: AdminTheme.shadow(context),
      ),
      child: Material(
        color: color ?? AdminTheme.card(context),
        shape: shape,
        clipBehavior: clipBehavior,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Rounded square holding an icon; the gradient variant is the brand mark.
class AdminIconTile extends StatelessWidget {
  final IconData icon;
  final AdminTone tone;
  final bool gradient;
  final double size;

  const AdminIconTile({
    super.key,
    required this.icon,
    this.tone = AdminTone.primary,
    this.gradient = false,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.3);
    if (gradient) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AdminTheme.toneTint(context, tone),
        borderRadius: radius,
      ),
      child: Icon(icon, color: AdminTheme.toneInk(context, tone), size: size * 0.5),
    );
  }
}

class AdminPill extends StatelessWidget {
  final String label;
  final AdminTone tone;
  final IconData? icon;

  const AdminPill({
    super.key,
    required this.label,
    this.tone = AdminTone.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final ink = AdminTheme.toneInk(context, tone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AdminTheme.toneTint(context, tone),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: ink),
            const SizedBox(width: 4),
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
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AdminSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AdminTheme.heading(context)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(subtitle!, style: AdminTheme.caption(context)),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AdminStatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final AdminTone tone;
  final VoidCallback? onTap;

  const AdminStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.tone = AdminTone.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AdminCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AdminIconTile(icon: icon, tone: tone, size: 40),
              const Spacer(),
              if (onTap != null)
                Icon(
                  CupertinoIcons.arrow_up_right,
                  size: 16,
                  color: AdminTheme.textSecondary(context),
                ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: AdminTheme.title(context).copyWith(fontSize: 28),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AdminTheme.caption(context),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INPUTS
// ═════════════════════════════════════════════════════════════════════════════

class AdminSearchField extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const AdminSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  @override
  State<AdminSearchField> createState() => _AdminSearchFieldState();
}

class _AdminSearchFieldState extends State<AdminSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => TextField(
        controller: _controller,
        onChanged: widget.onChanged,
        textInputAction: TextInputAction.search,
        style: AdminTheme.body(context),
        cursorColor: Theme.of(context).colorScheme.primary,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: AdminTheme.body(context).copyWith(
            color: AdminTheme.textSecondary(context).withValues(alpha: 0.8),
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: AdminTheme.card(context),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          prefixIcon: Icon(
            CupertinoIcons.search,
            size: 18,
            color: AdminTheme.textSecondary(context),
          ),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Clear',
                  icon: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    size: 18,
                    color: AdminTheme.textSecondary(context),
                  ),
                  onPressed: () {
                    _controller.clear();
                    widget.onChanged('');
                  },
                ),
          border: border(AdminTheme.border(context)),
          enabledBorder: border(AdminTheme.border(context)),
          focusedBorder:
              border(Theme.of(context).colorScheme.primary, 1.6),
        ),
      ),
    );
  }
}

class AdminFilterChip extends StatelessWidget {
  final String label;
  final int? count;
  final IconData? icon;
  final bool selected;
  final AdminTone tone;
  final VoidCallback onTap;

  const AdminFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.icon,
    this.tone = AdminTone.primary,
  });

  @override
  Widget build(BuildContext context) {
    final base = AdminTheme.toneBase(context, tone);
    final ink = AdminTheme.toneInk(context, tone);
    return Material(
      color: selected
          ? AdminTheme.toneTint(context, tone, alpha: 0.16)
          : AdminTheme.card(context),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? base : AdminTheme.border(context),
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? ink : AdminTheme.textSecondary(context),
                ),
                const SizedBox(width: 7),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTextStyles.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? ink : AdminTheme.textSecondary(context),
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: selected
                        ? base.withValues(alpha: 0.22)
                        : AdminTheme.inset(context),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: selected ? ink : AdminTheme.textSecondary(context),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontally scrolling row for [AdminFilterChip]s.
class AdminFilterBar extends StatelessWidget {
  final List<Widget> chips;
  const AdminFilterBar({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    final gutter = AdminTheme.gutter(MediaQuery.sizeOf(context).width);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
        ],
      ),
    );
  }
}

/// Pill-style segmented control driven by a [TabController].
class AdminSegmentedTabBar extends StatelessWidget {
  final TabController controller;
  final List<({String label, IconData icon})> tabs;

  const AdminSegmentedTabBar({
    super.key,
    required this.controller,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AdminTheme.inset(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminTheme.border(context)),
      ),
      child: TabBar(
        controller: controller,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(10),
        labelPadding: EdgeInsets.zero,
        labelColor: AdminTheme.toneInk(context, AdminTone.primary),
        unselectedLabelColor: AdminTheme.textSecondary(context),
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
          borderRadius: BorderRadius.circular(10),
          boxShadow: AdminTheme.shadow(context),
        ),
        tabs: [
          for (final t in tabs)
            Tab(
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 16),
                  const SizedBox(width: 8),
                  Text(t.label),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// STATES
// ═════════════════════════════════════════════════════════════════════════════

class AdminEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final AdminTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AdminEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.tone = AdminTone.primary,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AdminTheme.toneTint(context, tone, alpha: 0.12),
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: AdminTheme.toneInk(context, tone),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AdminTheme.heading(context),
              ),
              if (message != null) ...[
                const SizedBox(height: 6),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AdminTheme.caption(context).copyWith(fontSize: 13.5),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: onAction,
                  style: AdminTheme.filledButton(context, tone: tone),
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

class AdminErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AdminErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AdminEmptyState(
      icon: CupertinoIcons.exclamationmark_triangle_fill,
      tone: AdminTone.danger,
      title: 'Something went wrong',
      message: message,
      actionLabel: 'Try again',
      onAction: onRetry,
    );
  }
}

/// Skeleton list shown while admin data is loading.
class AdminLoadingState extends StatelessWidget {
  final int count;
  final double itemHeight;

  const AdminLoadingState({super.key, this.count = 6, this.itemHeight = 76});

  @override
  Widget build(BuildContext context) {
    final gutter = AdminTheme.gutter(MediaQuery.sizeOf(context).width);
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 24),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => ShimmerPlaceholder(
        width: double.infinity,
        height: itemHeight,
        borderRadius: BorderRadius.circular(18),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIALOGS & SHEETS
// ═════════════════════════════════════════════════════════════════════════════

/// Rounded, theme-aware dialog frame used by every admin dialog.
class AdminDialogFrame extends StatelessWidget {
  final IconData? icon;
  final AdminTone tone;
  final String title;
  final String? message;
  final Widget? child;
  final List<Widget> actions;
  final double maxWidth;

  const AdminDialogFrame({
    super.key,
    required this.title,
    this.icon,
    this.tone = AdminTone.primary,
    this.message,
    this.child,
    this.actions = const [],
    this.maxWidth = 420,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.card(context),
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                AdminIconTile(icon: icon!, tone: tone, size: 48),
                const SizedBox(height: 16),
              ],
              Text(title, style: AdminTheme.heading(context).copyWith(fontSize: 18)),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  style: AdminTheme.caption(context).copyWith(fontSize: 13.5),
                ),
              ],
              if (child != null) ...[
                const SizedBox(height: 16),
                child!,
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Flexible(child: actions[i]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Confirmation dialog. Resolves to `true` only when the user confirms.
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  AdminTone tone = AdminTone.primary,
  IconData icon = CupertinoIcons.question_circle_fill,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AdminDialogFrame(
      icon: icon,
      tone: tone,
      title: title,
      message: message,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: AdminTheme.textButton(ctx, tone: AdminTone.neutral),
          child: Text(cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: AdminTheme.filledButton(ctx, tone: tone),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Icon + label + value row used in detail sheets and dialogs.
class AdminInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AdminInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminIconTile(icon: icon, size: 32, tone: AdminTone.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: AdminTheme.label(context)),
                const SizedBox(height: 2),
                Text(value, style: AdminTheme.body(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a themed modal bottom sheet with a drag handle.
Future<T?> showAdminSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    backgroundColor: AdminTheme.card(context),
    constraints: const BoxConstraints(maxWidth: 640),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: builder,
  );
}
