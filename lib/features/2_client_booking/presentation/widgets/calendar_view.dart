import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';

/// A widget that displays a horizontally scrollable list of dates.
class HorizontalDayPicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime firstDate;

  HorizontalDayPicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  }) : firstDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30, // Show the next 30 days
        itemBuilder: (context, index) {
          final date = firstDate.add(Duration(days: index));
          final isSelected = date.day == selectedDate.day &&
              date.month == selectedDate.month &&
              date.year == selectedDate.year;

          return _DateItem(
            date: date,
            isSelected: isSelected,
            onTap: () => onDateSelected(date),
          );
        },
      ),
    );
  }
}

class _DateItem extends StatelessWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateItem({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: AppConstants.radiusL,
      child: Container(
        width: 60,
        margin: const EdgeInsets.symmetric(horizontal: AppConstants.padXS),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: AppConstants.radiusL,
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat.E().format(date), // Day of the week (e.g., 'Mon')
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppConstants.padXXS),
            Text(
              date.day.toString(),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
