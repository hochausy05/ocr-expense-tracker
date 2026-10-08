import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/models/expense.dart';
import 'package:ocr_expense_tracker/models/parsed_receipt.dart';

void main() {
  group('Expense', () {
    test('round-trips SQLite fields and fixed category', () {
      final expense = Expense(
        id: 12,
        merchant: 'Coffee Shop',
        amount: 150000,
        transactionDate: DateTime.utc(2026, 10, 7),
        category: ExpenseCategory.food,
        receiptImagePath: '/app/receipts/receipt_1.jpg',
        createdAt: DateTime.utc(2026, 10, 7, 8, 30),
      );

      final restored = Expense.fromMap(expense.toMap());

      expect(restored.id, expense.id);
      expect(restored.merchant, expense.merchant);
      expect(restored.amount, expense.amount);
      expect(
        restored.transactionDate.isAtSameMomentAs(expense.transactionDate),
        isTrue,
      );
      expect(restored.category, expense.category);
      expect(restored.receiptImagePath, expense.receiptImagePath);
      expect(restored.createdAt.isAtSameMomentAs(expense.createdAt), isTrue);
    });

    test('new expense map leaves generated id out', () {
      final expense = Expense(
        merchant: 'Market',
        amount: 50000,
        transactionDate: DateTime.utc(2026, 10, 7),
        category: ExpenseCategory.food,
        createdAt: DateTime.utc(2026, 10, 7),
      );

      expect(expense.toMap().containsKey('id'), isFalse);
      expect(ExpenseCategory.values.map((category) => category.label), [
        'Food',
        'Study',
        'Travel',
        'Gear',
        'Entertainment',
      ]);
    });

    test('preserves a local transaction calendar date from SQLite', () {
      final original = Expense(
        merchant: 'Market',
        amount: 50000,
        transactionDate: DateTime(2026, 10, 8),
        category: ExpenseCategory.food,
        createdAt: DateTime(2026, 10, 8),
      );

      final restored = Expense.fromMap(original.toMap());
      expect(restored.transactionDate.year, 2026);
      expect(restored.transactionDate.month, 10);
      expect(restored.transactionDate.day, 8);
    });
  });

  test('ParsedReceipt fields are optional until OCR is implemented', () {
    const parsed = ParsedReceipt();

    expect(parsed.merchant, isNull);
    expect(parsed.date, isNull);
    expect(parsed.total, isNull);
    expect(parsed.rawText, isNull);
  });
}
