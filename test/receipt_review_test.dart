import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/models/expense.dart';
import 'package:ocr_expense_tracker/models/parsed_receipt.dart';
import 'package:ocr_expense_tracker/screens/receipt_review_screen.dart';

void main() {
  late Directory directory;
  late File source;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('receipt_review_test_');
    source = File('${directory.path}/crop.jpg');
  });

  tearDown(() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<void> openReview(
    WidgetTester tester, {
    required Future<String> Function(File) storeImage,
    required Future<int> Function(Expense) insertExpense,
    void Function(bool?)? onResult,
  }) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (context) => ReceiptReviewScreen(
                        imagePath: source.path,
                        parsedReceipt: const ParsedReceipt(),
                        storeImage: storeImage,
                        insertExpense: insertExpense,
                      ),
                    ),
                  );
                  onResult?.call(result);
                },
                child: const Text('Open review'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open review'));
    await tester.pumpAndSettle();
  }

  Future<void> fillForm(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Corner Store');
    await tester.enterText(fields.at(1), '08/10/2026');
    await tester.enterText(fields.at(2), '42000');
    await tester.tap(find.widgetWithText(ChoiceChip, 'Study'));
    await tester.ensureVisible(find.text('Lưu khoản chi'));
  }

  testWidgets('saves validated review once and returns success', (
    tester,
  ) async {
    final gate = Completer<int>();
    Expense? inserted;
    var insertCount = 0;
    bool? result;
    final destination = '${directory.path}/stored.jpg';
    await tester.runAsync(() => File(destination).writeAsBytes([1, 2, 3]));
    await openReview(
      tester,
      storeImage: (_) async => destination,
      insertExpense: (expense) {
        inserted = expense;
        insertCount++;
        return gate.future;
      },
      onResult: (value) => result = value,
    );
    await fillForm(tester);
    await tester.tap(find.text('Lưu khoản chi'));
    await tester.tap(find.text('Lưu khoản chi'));
    await tester.pump();
    expect(insertCount, 1);
    expect(find.text('Đang lưu khoản chi…'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Lưu khoản chi'),
          )
          .onPressed,
      isNull,
    );
    gate.complete(7);
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(insertCount, 1);
    expect(inserted!.merchant, 'Corner Store');
    expect(inserted!.amount, 42000);
    expect(inserted!.transactionDate.day, 8);
    expect(inserted!.category, ExpenseCategory.study);
    expect(inserted!.receiptImagePath, destination);
    expect(File(destination).existsSync(), isTrue);
  });

  testWidgets('invalid fields and retake do not save', (tester) async {
    var insertCount = 0;
    bool? result;
    await openReview(
      tester,
      storeImage: (_) async => throw StateError('Should not store'),
      insertExpense: (_) async {
        insertCount++;
        return 1;
      },
      onResult: (value) => result = value,
    );
    await tester.ensureVisible(find.text('Lưu khoản chi'));
    await tester.tap(find.text('Lưu khoản chi'));
    await tester.pump();
    expect(find.text('Nhập tên cửa hàng.'), findsOneWidget);
    expect(insertCount, 0);
    await tester.tap(find.text('Chụp lại'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(insertCount, 0);
  });

  testWidgets('failed insert removes copied image and keeps review open', (
    tester,
  ) async {
    final destination = '${directory.path}/stored.jpg';
    await tester.runAsync(() => File(destination).writeAsBytes([1, 2, 3]));
    await openReview(
      tester,
      storeImage: (_) async => destination,
      insertExpense: (_) async => throw StateError('Database unavailable'),
    );
    await fillForm(tester);
    await tester.tap(find.text('Lưu khoản chi'));
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Không thể lưu khoản chi. Hãy thử lại.'), findsOneWidget);
    expect(find.byType(ReceiptReviewScreen), findsOneWidget);
    expect(File(destination).existsSync(), isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('failed image storage does not insert', (tester) async {
    var insertCount = 0;
    await openReview(
      tester,
      storeImage: (_) async => throw const FileSystemException('Copy failed'),
      insertExpense: (_) async {
        insertCount++;
        return 1;
      },
    );
    await fillForm(tester);
    await tester.tap(find.text('Lưu khoản chi'));
    await tester.pumpAndSettle();
    expect(insertCount, 0);
    expect(find.text('Không thể lưu khoản chi. Hãy thử lại.'), findsOneWidget);
  });
}
