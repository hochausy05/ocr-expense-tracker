import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/models/expense.dart';
import 'package:ocr_expense_tracker/models/expense_statistics.dart';

Expense expense(
  DateTime date,
  int amount, [
  ExpenseCategory category = ExpenseCategory.food,
]) => Expense(
  merchant: 'Test store',
  amount: amount,
  transactionDate: date,
  category: category,
  createdAt: DateTime(2030, 1, 1),
);

void main() {
  test('all-time category totals, percentages and unused categories', () {
    final stats = ExpenseStatistics.fromExpenses([
      expense(DateTime(2025, 1, 1), 100000),
      expense(DateTime(2026, 10, 8), 50000),
      expense(DateTime(2026, 10, 9), 50000, ExpenseCategory.study),
    ], now: DateTime(2026, 10, 8));
    expect(stats.total, 200000);
    expect(stats.categoryTotals[ExpenseCategory.food], 150000);
    expect(stats.categoryTotals[ExpenseCategory.study], 50000);
    expect(stats.percentage(ExpenseCategory.food), 75);
    expect(stats.percentage(ExpenseCategory.study), 25);
    for (final category in [
      ExpenseCategory.travel,
      ExpenseCategory.gear,
      ExpenseCategory.entertainment,
    ]) {
      expect(stats.categoryTotals[category], 0);
      expect(stats.percentage(category), 0);
    }
  });

  test(
    'Monday through Sunday uses transaction dates and combines each day',
    () {
      final stats = ExpenseStatistics.fromExpenses([
        for (var day = 5; day <= 11; day++)
          expense(DateTime(2026, 10, day, 23, 59), day * 1000),
        expense(DateTime(2026, 10, 5), 2000),
        expense(DateTime(2026, 10, 4, 23, 59), 999999),
        expense(DateTime(2026, 10, 12), 999999),
      ], now: DateTime(2026, 10, 11, 23, 59));
      expect(stats.weekStart, DateTime(2026, 10, 5));
      expect(stats.weekEnd, DateTime(2026, 10, 11));
      expect(stats.weeklyTotals, [7000, 6000, 7000, 8000, 9000, 10000, 11000]);
      expect(stats.weeklyTotal, 58000);
    },
  );

  test('week crossing month boundary includes zero days', () {
    final stats = ExpenseStatistics.fromExpenses([
      expense(DateTime(2026, 9, 28), 100),
      expense(DateTime(2026, 10, 4), 200),
    ], now: DateTime(2026, 10, 1));
    expect(stats.weekStart, DateTime(2026, 9, 28));
    expect(stats.weekEnd, DateTime(2026, 10, 4));
    expect(stats.weeklyTotals, [100, 0, 0, 0, 0, 0, 200]);
  });

  test('week crossing year boundary excludes adjacent weeks', () {
    final stats = ExpenseStatistics.fromExpenses([
      expense(DateTime(2025, 12, 28), 999),
      expense(DateTime(2025, 12, 29), 100),
      expense(DateTime(2026, 1, 1), 200),
      expense(DateTime(2026, 1, 4), 300),
      expense(DateTime(2026, 1, 5), 999),
    ], now: DateTime(2026, 1, 1));
    expect(stats.weekStart, DateTime(2025, 12, 29));
    expect(stats.weekEnd, DateTime(2026, 1, 4));
    expect(stats.weeklyTotals, [100, 0, 0, 200, 0, 0, 300]);
  });

  test('UTC stored timestamps are grouped by the equivalent local date', () {
    final monday = DateTime(2026, 10, 5, 0, 5);
    final stats = ExpenseStatistics.fromExpenses([
      expense(monday.toUtc(), 100),
    ], now: DateTime(2026, 10, 8).toUtc());
    expect(stats.weeklyTotals, [100, 0, 0, 0, 0, 0, 0]);
  });

  test('empty collection has finite zero percentages and seven zero days', () {
    final stats = ExpenseStatistics.fromExpenses(
      [],
      now: DateTime(2026, 10, 8),
    );
    expect(stats.total, 0);
    expect(stats.weeklyTotal, 0);
    expect(stats.weeklyTotals, List.filled(7, 0));
    for (final category in ExpenseCategory.values) {
      expect(stats.percentage(category), 0);
    }
  });

  test('large integer VND totals keep their exact values', () {
    const amount = 9000000000001;
    final stats = ExpenseStatistics.fromExpenses([
      expense(DateTime(2026, 10, 8), amount),
      expense(DateTime(2026, 10, 8), amount),
      expense(DateTime(2026, 10, 9), amount, ExpenseCategory.gear),
    ], now: DateTime(2026, 10, 8));
    expect(stats.total, amount * 3);
    expect(stats.weeklyTotals[3], amount * 2);
    expect(stats.percentage(ExpenseCategory.food), closeTo(200 / 3, 0.000001));
  });
}
