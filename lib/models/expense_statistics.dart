import 'expense.dart';

class ExpenseStatistics {
  ExpenseStatistics._(this.categoryTotals, this.weeklyTotals, this.weekStart);

  final Map<ExpenseCategory, int> categoryTotals;
  final List<int> weeklyTotals;
  final DateTime weekStart;

  int get total => categoryTotals.values.fold(0, (sum, value) => sum + value);
  int get weeklyTotal => weeklyTotals.fold(0, (sum, value) => sum + value);
  DateTime get weekEnd =>
      DateTime(weekStart.year, weekStart.month, weekStart.day + 6);

  double percentage(ExpenseCategory category) =>
      total == 0 ? 0 : categoryTotals[category]! / total * 100;

  factory ExpenseStatistics.fromExpenses(
    Iterable<Expense> expenses, {
    required DateTime now,
  }) {
    final localNow = now.toLocal();
    final start = DateTime(
      localNow.year,
      localNow.month,
      localNow.day - (localNow.weekday - DateTime.monday),
    );
    final nextWeek = DateTime(start.year, start.month, start.day + 7);
    final categories = {
      for (final category in ExpenseCategory.values) category: 0,
    };
    final days = List<int>.filled(7, 0);

    for (final expense in expenses) {
      categories[expense.category] =
          categories[expense.category]! + expense.amount;
      final localDate = expense.transactionDate.toLocal();
      final day = DateTime(localDate.year, localDate.month, localDate.day);
      if (!day.isBefore(start) && day.isBefore(nextWeek)) {
        // Weekday indexing avoids elapsed-hour differences across DST changes.
        days[day.weekday - DateTime.monday] += expense.amount;
      }
    }
    return ExpenseStatistics._(
      Map.unmodifiable(categories),
      List.unmodifiable(days),
      start,
    );
  }
}
