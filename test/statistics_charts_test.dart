import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/models/expense.dart';
import 'package:ocr_expense_tracker/models/expense_statistics.dart';
import 'package:ocr_expense_tracker/widgets/category_donut_chart.dart';
import 'package:ocr_expense_tracker/widgets/weekly_bar_chart.dart';

void main() {
  for (final amount in [0, 9000000000001]) {
    testWidgets(
      'charts paint and animate at narrow width with amount $amount',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1100);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final stats = ExpenseStatistics.fromExpenses([
          if (amount > 0)
            Expense(
              merchant: 'Store',
              amount: amount,
              transactionDate: DateTime(2026, 10, 8),
              category: ExpenseCategory.food,
              createdAt: DateTime(2026, 10, 8),
            ),
        ], now: DateTime(2026, 10, 8));
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CategoryDonutChart(statistics: stats),
                    WeeklyBarChart(totals: stats.weeklyTotals),
                  ],
                ),
              ),
            ),
          ),
        );
        CategoryDonutPainter donut() =>
            tester
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (widget) =>
                            widget is CustomPaint &&
                            widget.painter is CategoryDonutPainter,
                      ),
                    )
                    .painter!
                as CategoryDonutPainter;
        WeeklyBarPainter bars() =>
            tester
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (widget) =>
                            widget is CustomPaint &&
                            widget.painter is WeeklyBarPainter,
                      ),
                    )
                    .painter!
                as WeeklyBarPainter;
        expect(donut().progress, 0);
        expect(bars().progress, 0);
        await tester.pump(const Duration(milliseconds: 350));
        expect(donut().progress, inExclusiveRange(0, 1));
        expect(bars().progress, inExclusiveRange(0, 1));
        await tester.pumpAndSettle();
        expect(donut().progress, 1);
        expect(bars().progress, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  }
}
