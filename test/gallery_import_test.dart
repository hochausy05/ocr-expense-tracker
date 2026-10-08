import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_expense_tracker/screens/camera_screen.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('gallery_import_test_');
  });

  tearDown(() async {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  Future<void> openScan(
    WidgetTester tester, {
    required Future<XFile?> Function() pickImage,
    Future<CroppedFile?> Function(String imagePath)? cropImage,
    Future<String> Function(String imagePath)? recognizeText,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CameraScreen(
          onSaved: () {},
          pickImage: pickImage,
          cropImage: cropImage,
          recognizeText: recognizeText,
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('gallery action is available and cancellation stays on Scan', (
    tester,
  ) async {
    var pickCalls = 0;
    var cropCalls = 0;
    await openScan(
      tester,
      pickImage: () async {
        pickCalls++;
        return null;
      },
      cropImage: (_) async {
        cropCalls++;
        return null;
      },
    );

    expect(find.text('Chọn ảnh từ thư viện'), findsOneWidget);
    await tester.tap(find.text('Chọn ảnh từ thư viện'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(pickCalls, 1);
    expect(cropCalls, 0);
    expect(find.text('Quét hóa đơn'), findsOneWidget);
    expect(find.text('Chọn ảnh từ thư viện'), findsOneWidget);
  });

  testWidgets('selected image shares crop output with OCR and keeps fallback', (
    tester,
  ) async {
    final source = File('${directory.path}/receipt.png');
    final cropped = File('${directory.path}/cropped.png');
    await tester.runAsync(() async {
      await source.writeAsBytes([1, 2, 3]);
      await cropped.writeAsBytes([4, 5, 6]);
    });
    expect(source.existsSync(), isTrue);
    expect(XFile(source.path).name.endsWith('receipt.png'), isTrue);
    String? cropInput;
    String? ocrInput;
    var pickCalls = 0;

    await openScan(
      tester,
      pickImage: () async {
        pickCalls++;
        return XFile(source.path);
      },
      cropImage: (imagePath) async {
        cropInput = imagePath;
        return CroppedFile(cropped.path);
      },
      recognizeText: (imagePath) async {
        ocrInput = imagePath;
        return '';
      },
    );

    await tester.tap(find.text('Chọn ảnh từ thư viện'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(pickCalls, 1);
    expect(find.text('Chỉ hỗ trợ ảnh JPG, JPEG hoặc PNG.'), findsNothing);
    expect(cropInput, source.path);
    expect(ocrInput, cropped.path);
    expect(
      find.text(
        'Không nhận diện được chữ. Bạn có thể thử lại hoặc nhập thủ công.',
      ),
      findsOneWidget,
    );
    expect(find.text('Nhập thông tin thủ công'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
  });

  testWidgets('missing selected image returns to Scan without cropping', (
    tester,
  ) async {
    var cropCalls = 0;
    final missing = File('${directory.path}/missing.jpg');
    await openScan(
      tester,
      pickImage: () async => XFile(missing.path),
      cropImage: (_) async {
        cropCalls++;
        return null;
      },
    );

    await tester.tap(find.text('Chọn ảnh từ thư viện'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(cropCalls, 0);
    expect(find.text('Quét hóa đơn'), findsOneWidget);
    expect(
      find.text('Không thể đọc ảnh đã chọn. Hãy chọn ảnh khác.'),
      findsOneWidget,
    );
  });
}
