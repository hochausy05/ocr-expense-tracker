import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/models/expense.dart';
import 'package:ocr_expense_tracker/screens/statistics_screen.dart';
import 'package:ocr_expense_tracker/widgets/category_donut_chart.dart';
import 'package:ocr_expense_tracker/widgets/weekly_bar_chart.dart';

Future<void> finishLoading(WidgetTester tester) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) break;
  }
  expect(find.byType(CircularProgressIndicator), findsNothing);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'loading, database error and retry are distinct from empty data',
    (tester) async {
      final pending = Completer<List<Expense>>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: StatisticsScreen(
            loadExpenses: () =>
                ++calls == 1 ? pending.future : Future.value([]),
            now: () => DateTime(2026, 10, 8),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byTooltip('Làm mới'));
      expect(calls, 1);
      pending.completeError(StateError('SQLite read failed'));
      await tester.pumpAndSettle();
      expect(find.text('Không thể tải thống kê. Hãy thử lại.'), findsOneWidget);
      expect(find.byType(CategoryDonutChart), findsNothing);
      await tester.tap(find.text('Thử lại'));
      await finishLoading(tester);
      expect(calls, 2);
      expect(
        find.text(
          'Chưa có khoản chi nào. Quét và lưu hóa đơn để xem thống kê.',
        ),
        findsOneWidget,
      );
      expect(find.byType(CategoryDonutChart), findsOneWidget);
    },
  );

  testWidgets(
    'fresh loads reflect changed expenses and keep old spending out of this week',
    (tester) async {
      var calls = 0;
      final records = <Expense>[
        Expense(
          merchant: 'Old',
          amount: 100000,
          transactionDate: DateTime(2026, 9, 1),
          category: ExpenseCategory.study,
          createdAt: DateTime(2026, 10, 8),
        ),
      ];
      Widget screen() => MaterialApp(
        home: StatisticsScreen(
          loadExpenses: () async {
            calls++;
            return List.of(records);
          },
          now: () => DateTime(2026, 10, 8),
        ),
      );
      await tester.pumpWidget(screen());
      await finishLoading(tester);
      expect(
        tester
            .widget<CategoryDonutChart>(find.byType(CategoryDonutChart))
            .statistics
            .total,
        100000,
      );
      await tester.scrollUntilVisible(find.byType(WeeklyBarChart), 300);
      expect(
        tester.widget<WeeklyBarChart>(find.byType(WeeklyBarChart)).totals,
        List.filled(7, 0),
      );
      expect(find.text('Chưa có chi tiêu trong tuần này.'), findsOneWidget);
      await tester.pumpWidget(screen());
      await tester.pump();
      expect(calls, 1);

      records.add(
        Expense(
          merchant: 'New',
          amount: 42000,
          transactionDate: DateTime(2026, 10, 8),
          category: ExpenseCategory.food,
          createdAt: DateTime(2026, 10, 8),
        ),
      );
      await tester.tap(find.byTooltip('Làm mới'));
      await finishLoading(tester);
      expect(calls, 2);
      expect(
        tester
            .widget<CategoryDonutChart>(find.byType(CategoryDonutChart))
            .statistics
            .total,
        142000,
      );
      await tester.scrollUntilVisible(find.byType(WeeklyBarChart), 300);
      expect(
        tester.widget<WeeklyBarChart>(find.byType(WeeklyBarChart)).totals,
        [0, 0, 0, 42000, 0, 0, 0],
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(screen());
      await finishLoading(tester);
      expect(calls, 3);
    },
  );
}
