import 'package:equatable/equatable.dart';

/// Value object representing a date range
class DateRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const DateRange({
    required this.start,
    required this.end,
  });

  /// Check if a date falls within this range (inclusive)
  bool contains(DateTime date) {
    return (date.isAfter(start) || date.isAtSameMomentAs(start)) &&
        (date.isBefore(end) || date.isAtSameMomentAs(end));
  }

  /// Get the duration of this date range
  Duration get duration => end.difference(start);

  /// Get the number of days in this range
  int get days => duration.inDays + 1; // +1 to include both start and end days

  /// Create a date range for the current month
  factory DateRange.currentMonth() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return DateRange(start: start, end: end);
  }

  /// Create a date range for a specific month
  factory DateRange.month(int year, int month) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return DateRange(start: start, end: end);
  }

  /// Create a date range for the current year
  factory DateRange.currentYear() {
    final now = DateTime.now();
    final start = DateTime(now.year, 1, 1);
    final end = DateTime(now.year, 12, 31, 23, 59, 59);
    return DateRange(start: start, end: end);
  }

  /// Create a date range for the last N days
  factory DateRange.lastDays(int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days - 1));
    return DateRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }

  @override
  List<Object?> get props => [start, end];

  @override
  String toString() {
    return 'DateRange(${start.toIso8601String()} - ${end.toIso8601String()})';
  }
}
