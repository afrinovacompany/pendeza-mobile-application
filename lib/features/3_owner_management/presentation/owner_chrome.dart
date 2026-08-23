import 'package:flutter/material.dart';

import '../../../app/widgets/adaptive/adaptive_app_bar.dart';
import '../../../shared/models/appointment_model.dart';

/// Tab app bar matching the polished client/auth surface style.
PreferredSizeWidget ownerTabAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
  bool automaticallyImplyLeading = false,
}) {
  final theme = Theme.of(context);
  return AdaptiveAppBar(
    title: title,
    automaticallyImplyLeading: automaticallyImplyLeading,
    backgroundColor: theme.scaffoldBackgroundColor,
    foregroundColor: theme.colorScheme.onSurface,
    elevation: 0,
    centerTitle: true,
    actions: actions,
  );
}

Color ownerAppointmentStatusColor(ThemeData theme, String status) {
  switch (status) {
    case AppointmentStatus.confirmed:
      return theme.colorScheme.primary;
    case AppointmentStatus.completed:
      return theme.colorScheme.tertiary;
    case AppointmentStatus.pendingPayment:
      return theme.colorScheme.secondary;
    case AppointmentStatus.cancelled:
    case AppointmentStatus.paymentFailed:
      return theme.colorScheme.error;
    case AppointmentStatus.noShow:
      return theme.colorScheme.onSurface.withValues(alpha: 0.45);
    default:
      return theme.colorScheme.outline;
  }
}
