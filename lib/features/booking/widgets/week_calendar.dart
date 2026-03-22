// lib/features/booking/widgets/week_calendar.dart
import 'package:flutter/material.dart';

class WeekCalendar extends StatelessWidget {
  const WeekCalendar({
    super.key,
    required this.weekDays,
    required this.selectedDate,
    required this.monthLabel,
    required this.onDayTap,
    required this.onPreviousWeek,
    required this.onNextWeek,
  });

  final List<DateTime> weekDays;
  final DateTime selectedDate;
  final String monthLabel;
  final ValueChanged<DateTime> onDayTap;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;

  static const _kGreen = Color(0xFF1C894E);

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  String _shortDay(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD6F0E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPreviousWeek,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                monthLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNextWeek,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: weekDays
                .map((d) => Expanded(child: _DayCell(
              date: d,
              isSelected: _isSameDay(d, selectedDate),
              isToday: _isToday(d),
              shortDay: _shortDay(d),
              onTap: onDayTap,
            )))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.shortDay,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final String shortDay;
  final ValueChanged<DateTime> onTap;

  static const _kGreen = Color(0xFF1C894E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(date),
      child: Column(
        children: [
          Text(
            shortDay,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? _kGreen : Colors.black87,
              fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isSelected ? _kGreen : Colors.transparent,
              shape: BoxShape.circle,
              border: isToday && !isSelected
                  ? Border.all(color: _kGreen, width: 1.5)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}