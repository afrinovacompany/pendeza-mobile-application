import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import 'package:pendeza/app/config/platform_config.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/widgets/adaptive/adaptive_app_bar.dart';

/// A platform-adaptive scaffold that uses Material Scaffold on Android
/// and CupertinoPageScaffold on iOS.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    this.appBar,
    this.title,
    this.leading,
    this.trailing,
    this.automaticallyImplyLeading = true,
    required this.body,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
  });

  /// Custom app bar widget. If provided, [title], [leading], and [trailing] are ignored.
  final PreferredSizeWidget? appBar;

  /// Title for the app bar (used if [appBar] is null)
  final String? title;

  /// Leading widget for the app bar (used if [appBar] is null)
  final Widget? leading;

  /// Trailing widget(s) for the app bar (used if [appBar] is null)
  final Widget? trailing;

  /// Whether to automatically add a back button
  final bool automaticallyImplyLeading;

  /// The main content of the scaffold
  final Widget body;

  /// Floating action button (Material only, ignored on iOS)
  final Widget? floatingActionButton;

  /// FAB location (Material only)
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Bottom navigation bar
  final Widget? bottomNavigationBar;

  /// Background color of the scaffold
  final Color? backgroundColor;

  /// Whether to resize body when keyboard appears
  final bool resizeToAvoidBottomInset;

  /// Whether the body extends behind the app bar
  final bool extendBodyBehindAppBar;

  /// Whether the body extends to the bottom
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkBackground : AppColors.background);

    // Build the app bar if title is provided and no custom appBar
    final effectiveAppBar = appBar ??
        (title != null
            ? AdaptiveAppBar(
                title: title!,
                leading: leading,
                trailing: trailing,
                automaticallyImplyLeading: automaticallyImplyLeading,
              )
            : null);

    return PlatformScaffold(
      appBar: effectiveAppBar != null
          ? PlatformAppBar(
              title: Text(title ?? ''),
              leading: leading,
              trailingActions: trailing != null ? [trailing!] : null,
              automaticallyImplyLeading: automaticallyImplyLeading,
              backgroundColor: isDark ? AppColors.darkSurface : AppColors.primary,
              material: (_, _) => MaterialAppBarData(
                elevation: 1,
                centerTitle: true,
              ),
              cupertino: (_, _) => CupertinoNavigationBarData(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 0.5,
                  ),
                ),
              ),
            )
          : null,
      body: body,
      backgroundColor: bgColor,
      material: (_, _) => MaterialScaffoldData(
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavBar: bottomNavigationBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        extendBody: extendBody,
      ),
      cupertino: (_, _) => CupertinoPageScaffoldData(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        navigationBar: effectiveAppBar != null
            ? CupertinoNavigationBar(
                middle: Text(
                  title ?? '',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : Colors.white,
                  ),
                ),
                leading: leading,
                trailing: trailing,
                automaticallyImplyLeading: automaticallyImplyLeading,
                backgroundColor:
                    isDark ? AppColors.darkSurface : AppColors.primary,
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.border,
                    width: 0.5,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// A simple adaptive scaffold without an app bar
class AdaptiveScaffoldBody extends StatelessWidget {
  const AdaptiveScaffoldBody({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.safeArea = true,
  });

  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = backgroundColor ??
        (isDark ? AppColors.darkBackground : AppColors.background);

    Widget content = child;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (safeArea) {
      content = SafeArea(child: content);
    }

    if (PlatformConfig.useCupertino) {
      return CupertinoPageScaffold(
        backgroundColor: bgColor,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: content,
    );
  }
}
