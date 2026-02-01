import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';

/// Enhanced horizontally scrollable date picker with animations
class HorizontalDayPicker extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime firstDate;

  HorizontalDayPicker({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
  }) : firstDate = DateTime.now();

  @override
  State<HorizontalDayPicker> createState() => _HorizontalDayPickerState();
}

class _HorizontalDayPickerState extends State<HorizontalDayPicker> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Auto-scroll to selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final daysDifference = widget.selectedDate.difference(widget.firstDate).inDays;
      if (daysDifference > 0) {
        _scrollController.animateTo(
          daysDifference * 76.0, // 60 width + 16 margin
          duration: AppConstants.durationMedium,
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.padL),
        itemCount: 30,
        itemBuilder: (context, index) {
          final date = widget.firstDate.add(Duration(days: index));
          final isSelected = date.day == widget.selectedDate.day &&
              date.month == widget.selectedDate.month &&
              date.year == widget.selectedDate.year;
          final isToday = date.day == DateTime.now().day &&
              date.month == DateTime.now().month &&
              date.year == DateTime.now().year;

          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 200 + (index * 30)),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: child,
                ),
              );
            },
            child: _EnhancedDateItem(
              date: date,
              isSelected: isSelected,
              isToday: isToday,
              onTap: () => widget.onDateSelected(date),
            ),
          );
        },
      ),
    );
  }
}

class _EnhancedDateItem extends StatefulWidget {
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _EnhancedDateItem({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  State<_EnhancedDateItem> createState() => _EnhancedDateItemState();
}

class _EnhancedDateItemState extends State<_EnhancedDateItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: AppConstants.durationFast,
      value: widget.isSelected ? 1.0 : 0.0,
    );
  }

  @override
  void didUpdateWidget(_EnhancedDateItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedBuilder(
        animation: _scaleController,
        builder: (context, child) {
          return Transform.scale(
            scale: _isPressed
                ? 0.92
                : 1.0 + (_scaleController.value * 0.05),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: AppConstants.durationFast,
          width: 60,
          margin: const EdgeInsets.symmetric(horizontal: AppConstants.padXS),
          decoration: BoxDecoration(
            gradient: widget.isSelected
                ? LinearGradient(
              colors: [colorScheme.primary, colorScheme.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: widget.isSelected
                ? null
                : widget.isToday
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: AppConstants.radiusL,
            border: Border.all(
              color: widget.isSelected
                  ? colorScheme.primary
                  : widget.isToday
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : theme.dividerColor.withValues(alpha: 0.3),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: widget.isSelected
                ? [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat.E().format(widget.date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: widget.isSelected
                      ? Colors.white
                      : widget.isToday
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight:
                  widget.isToday ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: AppConstants.padXXS),
              Text(
                widget.date.day.toString(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.isSelected
                      ? Colors.white
                      : widget.isToday
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
              if (widget.isToday && !widget.isSelected) ...[
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
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