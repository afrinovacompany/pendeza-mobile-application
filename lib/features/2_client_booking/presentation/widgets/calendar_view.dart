import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pendeza/app/config/theme/app_colors.dart';
import 'package:pendeza/app/config/theme/app_constants.dart';
import 'package:pendeza/app/config/theme/app_text_styles.dart';
import 'package:pendeza/shared/widgets/client_ui.dart';

/// Horizontally scrollable strip of the next 30 days.
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
  static const double _itemWidth = 62;
  static const double _itemGap = 10;

  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // Auto-scroll to selected date
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final daysDifference =
          widget.selectedDate.difference(widget.firstDate).inDays;
      if (daysDifference > 0) {
        _scrollController.animateTo(
          (daysDifference * (_itemWidth + _itemGap)).clamp(
            0.0,
            _scrollController.position.maxScrollExtent,
          ),
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

  bool _sameDay(DateTime a, DateTime b) =>
      a.day == b.day && a.month == b.month && a.year == b.year;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.1,
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: ClientTheme.gutter,
            vertical: 8,
          ),
          itemCount: 30,
          itemBuilder: (context, index) {
            final date = widget.firstDate.add(Duration(days: index));
            return Padding(
              padding: EdgeInsets.only(right: index == 29 ? 0 : _itemGap),
              child: _DayItem(
                date: date,
                width: _itemWidth,
                isSelected: _sameDay(date, widget.selectedDate),
                isToday: _sameDay(date, now),
                onTap: () => widget.onDateSelected(date),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _DayItem extends StatelessWidget {
  final DateTime date;
  final double width;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  const _DayItem({
    required this.date,
    required this.width,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = ClientTheme.isDark(context);
    final cs = Theme.of(context).colorScheme;
    final accent = isDark ? cs.primary : AppColors.primaryDark;
    final radius = BorderRadius.circular(20);

    final topLabel =
        isToday ? 'client.dashboard.today'.tr() : DateFormat.E().format(date);
    final topColor =
        isSelected
            ? Colors.white.withValues(alpha: 0.9)
            : (isToday ? accent : ClientTheme.textSecondary(context));
    final numberColor =
        isSelected ? Colors.white : ClientTheme.textPrimary(context);

    return Semantics(
      button: true,
      selected: isSelected,
      label: DateFormat.MMMMEEEEd().format(date),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: width,
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          color: isSelected ? null : ClientTheme.card(context),
          borderRadius: radius,
          border: Border.all(
            color:
                isSelected
                    ? Colors.transparent
                    : (isToday
                        ? AppColors.primary.withValues(alpha: 0.55)
                        : ClientTheme.border(context)),
            width: isToday && !isSelected ? 1.5 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      spreadRadius: -4,
                    ),
                  ]
                  : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    topLabel,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: AppTextStyles.fontFamily,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: topColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date.day.toString(),
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: numberColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat.MMM().format(date),
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 10.5,
                    color:
                        isSelected
                            ? Colors.white.withValues(alpha: 0.8)
                            : ClientTheme.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
