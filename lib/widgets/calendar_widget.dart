import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// 日历组件 - 中文星期标题
class CalendarWidget extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, List<dynamic>>? events;

  const CalendarWidget({
    super.key,
    required this.selectedDate,
    required this.onDateSelected,
    this.events,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: TableCalendar(
        firstDay: DateTime(2024),
        lastDay: DateTime(2030),
        focusedDay: selectedDate,
        selectedDayPredicate: (day) => isSameDay(day, selectedDate),
        onDaySelected: (selected, focused) => onDateSelected(selected),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        daysOfWeekHeight: 36,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: theme.colorScheme.onSurface),
          rightChevronIcon: Icon(Icons.chevron_right, color: theme.colorScheme.onSurface),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          weekendStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.error.withValues(alpha: 0.7),
          ),
        ),
        // 中文星期标题（覆盖默认英文）
        calendarBuilders: CalendarBuilders(
          dowBuilder: (context, day) {
            const weekdays = ['一', '二', '三', '四', '五', '六', '日'];
            final index = day.weekday - 1;
            final isWeekend = day.weekday >= 6;
            return Center(
              child: Text(
                weekdays[index],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isWeekend
                      ? theme.colorScheme.error.withValues(alpha: 0.7)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyle(color: theme.colorScheme.error),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          selectedTextStyle: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
          todayTextStyle: TextStyle(
            color: theme.colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.w600,
          ),
          defaultTextStyle: TextStyle(color: theme.colorScheme.onSurface),
        ),
        locale: 'zh_CN',
      ),
    );
  }
}
