import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/app.dart';

void main() {
  testWidgets('main destinations navigate between screens', (tester) async {
    await tester.pumpWidget(const ExpenseTrackerApp());

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Chi tiêu')),
      findsOneWidget,
    );
    await tester.tap(find.text('Quét'));
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Quét hóa đơn'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Thống kê'));
    await tester.pump();
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Thống kê')),
      findsOneWidget,
    );
  });
}
