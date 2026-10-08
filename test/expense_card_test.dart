import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/models/expense.dart';
import 'package:ocr_expense_tracker/widgets/expense_card.dart';

void main() {
  testWidgets('history card shows saved fields and tolerates missing image', (
    tester,
  ) async {
    final expense = Expense(
      merchant: 'Corner Store',
      amount: 150000,
      transactionDate: DateTime(2026, 10, 8),
      category: ExpenseCategory.food,
      receiptImagePath: '/missing/receipt.jpg',
      createdAt: DateTime(2026, 10, 8),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ExpenseCard(expense: expense)),
      ),
    );
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('Corner Store'), findsOneWidget);
    expect(find.text('150.000 ₫'), findsOneWidget);
    expect(find.text('08/10/2026 · Food'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  });
}
