import 'package:intl/intl.dart';

/// Helper methods for formatting and reasoning about dates.
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat _fullDate = DateFormat('EEEE, d MMMM yyyy');
  static final DateFormat _shortDate = DateFormat('d MMM yyyy');
  static final DateFormat _dayMonth = DateFormat('d MMM');

  /// e.g. "Monday, 16 June 2026".
  static String fullDate(DateTime date) => _fullDate.format(date);

  /// e.g. "16 Jun 2026".
  static String shortDate(DateTime date) => _shortDate.format(date);

  /// e.g. "16 Jun".
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  /// A human friendly relative label for a due date.
  static String dueLabel(DateTime due) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(due.year, due.month, due.day);
    final int diff = target.difference(today).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff == -1) return 'Yesterday';
    if (diff < 0) return '${diff.abs()} days overdue';
    if (diff <= 7) return 'In $diff days';
    return shortDate(due);
  }

  /// Whether [due] is before today (and therefore overdue).
  static bool isOverdue(DateTime due) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime target = DateTime(due.year, due.month, due.day);
    return target.isBefore(today);
  }

  /// A time-of-day aware greeting.
  static String greeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}
