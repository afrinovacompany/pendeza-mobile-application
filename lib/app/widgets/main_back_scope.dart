import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'adaptive/adaptive_dialog.dart';

/// Whether the app may close itself.
///
/// Only Android has a system Back that leaves the app. On iOS there is no
/// Back and Apple's guidelines say an app must not quit on its own
/// (`SystemNavigator.pop` is ignored there), so no exit prompt is offered.
bool get canExitAppProgrammatically =>
    defaultTargetPlatform == TargetPlatform.android;

/// Asks "Do you want to close the app?" and closes it on Yes.
///
/// Does nothing on platforms where an app can't close itself (see
/// [canExitAppProgrammatically]).
Future<void> confirmAndExitApp(BuildContext context) async {
  if (!canExitAppProgrammatically) return;

  final shouldExit = await showAdaptiveConfirmDialog(
    context: context,
    title: 'common.exit_title'.tr(),
    content: 'common.exit_message'.tr(),
    confirmText: 'common.yes'.tr(),
    cancelText: 'common.no'.tr(),
    isDestructive: true,
  );
  if (shouldExit) {
    await SystemNavigator.pop();
  }
}

/// Back-button behaviour for the screen that hosts the app's main tabs.
///
/// * On another screen: go back to where the user came from.
/// * On a tab other than Home (e.g. Profile): go to Home instead of leaving.
/// * On Home: ask whether to close the app (Android only).
///
/// Wrapping the tabs in a [PopScope] is also what makes Android's predictive
/// back gesture hand the event to the app instead of closing it.
class MainBackScope extends StatelessWidget {
  /// Whether the visible screen is one of the main tabs.
  final bool isOnMainTab;

  /// Index of the selected tab; 0 is Home.
  final int currentIndex;

  /// The visible screen is not a tab and can simply be popped.
  final bool canPopSecondary;

  /// Leave a non-tab screen that has nothing to pop back to.
  final VoidCallback onLeaveSecondary;

  /// Switch to the Home tab.
  final VoidCallback onGoHome;

  /// Replaces the exit prompt (for tests).
  final Future<void> Function(BuildContext context)? onExit;

  final Widget child;

  const MainBackScope({
    super.key,
    required this.isOnMainTab,
    required this.currentIndex,
    required this.canPopSecondary,
    required this.onLeaveSecondary,
    required this.onGoHome,
    required this.child,
    this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPopSecondary,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!isOnMainTab) {
          onLeaveSecondary();
          return;
        }
        if (currentIndex != 0) {
          onGoHome();
          return;
        }
        (onExit ?? confirmAndExitApp)(context);
      },
      child: child,
    );
  }
}
