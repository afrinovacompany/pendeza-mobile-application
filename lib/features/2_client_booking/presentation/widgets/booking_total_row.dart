import 'package:flutter/material.dart';

import '../../../../shared/widgets/client_ui.dart';

/// A label / value line of the booking summary (e.g. total duration).
class BookingTotalRow extends StatelessWidget {
  final String title;
  final String value;

  const BookingTotalRow({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(title, style: ClientTheme.body(context))),
          const SizedBox(width: 12),
          Text(
            value,
            style: ClientTheme.body(context).copyWith(
              fontWeight: FontWeight.w700,
              color: ClientTheme.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}
