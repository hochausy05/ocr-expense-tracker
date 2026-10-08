import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/services/receipt_parser.dart';

void main() {
  final parser = ReceiptParser();

  test(
    'parses comma-separated VND and prefers total over subtotal/discount',
    () {
      final receipt = parser.parse('''
COFFEE LAND
Date: 08/10/2026
Subtotal: 180,000
Discount: -30,000
TOTAL: 150,000 VND
''');

      expect(receipt.merchant, 'COFFEE LAND');
      expect(receipt.total, 150000);
    },
  );

  test('parses dot-separated Vietnamese totals and plain VND suffix', () {
    expect(parser.parse('Shop A\nGRAND TOTAL: 150.000 đ').total, 150000);
    expect(parser.parse('Shop B\nTỔNG CỘNG: 150.000').total, 150000);
    expect(parser.parse('Shop C\nTHANH TOÁN: 150000đ').total, 150000);
    expect(parser.parse('Shop D\nTOTAL: 400,000,000').total, 400000000);
    expect(parser.parse('Shop E\nTHANH TOÁN: 150.000đ').total, 150000);
    expect(parser.parse('Shop F\nTOTAL: 400000000').total, 400000000);
  });

  test('does not use a generic receipt title or staff name as merchant', () {
    final receipt = parser.parse('''
PHIẾU TÍNH TIÊN
Liên1
SỐH.ĐƠN 1
BÀN
NHÂN VIÊN:
BUI HANG NGA
''');

    expect(receipt.merchant, isNull);
  });

  test('parses the real receipt OCR with a separated T.CỘNG total', () {
    final receipt = parser.parse('''
PHIẾU TÍNH TIÊN
Liên1
SỐH.ĐƠN 1
BÀN
NHÂN VIÊN:
Phục vụi
Gio Vao i
Gio Ra i
LOUIS13
4 x
SHISHA
20 x
HOA QUA
3 x
2 %
VOI VOI CANADA
T.CỘNG
20/10/2014 1:03:09A
00001-2010201401
VND:
3A
3 x 10,000,000
COCACOLA
BUI HANG NGA
KHÁCH TRẢ
20/10 /2014 1:00118 A
20/10/2014 40306 A
90,000,000
1,000, 000
100,000
2,000, 000
360,000,000
2,000, 000
30,000,000
2,000,000
6,000,000
400,000,000
CAM ƠN QUY KHACH
HEN GAP LAl
400,000,000
400,000,000
''');

    expect(receipt.merchant, isNull);
    expect(receipt.date, DateTime(2014, 10, 20));
    expect(receipt.total, 400000000);
  });

  test('supports separated total amount for T.CỘNG abbreviation variants', () {
    const suffix = '''
20/10/2014 1:03:09A
00001-2010201401
VND:
3 x 10,000,000
KHÁCH TRẢ
90,000,000
360,000,000
400,000,000
CAM ƠN QUÝ KHÁCH
400,000,000
400,000,000
''';

    for (final label in ['T.CỘNG', 'T. CỘNG', 'T CỘNG']) {
      expect(parser.parse('$label\n$suffix').total, 400000000, reason: label);
    }
  });

  test(
    'does not mistake dates, IDs, phone numbers, or quantities for totals',
    () {
      final receipt = parser.parse('''
T.CỘNG
20/10/2014 1:03:09A
00001-2010201401
Phone: 0901234567
3 x 999,999,999
Subtotal: 900,000,000
''');

      expect(receipt.date, DateTime(2014, 10, 20));
      expect(receipt.total, isNull);
      expect(parser.parse('999,999,999').total, isNull);
    },
  );

  test('parses a valid DD/MM/YYYY date', () {
    final receipt = parser.parse('Shop\nDate: 29/02/2024\nTOTAL: 10,000');

    expect(receipt.date, DateTime(2024, 2, 29));
  });

  test('rejects impossible dates and unsupported date-only guesses', () {
    final invalid = parser.parse('Shop\nDate: 31/02/2025\nTOTAL: 10,000');
    final missing = parser.parse('Shop\nTOTAL: 10,000');

    expect(invalid.date, isNull);
    expect(missing.date, isNull);
  });

  test('returns null when no reliable merchant or total is present', () {
    final receipt = parser.parse('''
RECEIPT
Hotline: 0909000000
MST: 1234567890123
Date: 08-10-2026
Subtotal: 120,000
Discount: 20,000
''');

    expect(receipt.merchant, isNull);
    expect(receipt.total, isNull);
    expect(receipt.rawText, contains('Subtotal'));
  });

  test('filters noisy phone, address, and tax lines around a total', () {
    final receipt = parser.parse('''
Fresh Mart
12 Nguyen Hue, District 1
Phone: 0901234567
Tax ID: 0312345678
Date: 08-10-2026
Milk 45,000
Discount: 5,000
THANH TOÁN: 40.000 đ
''');

    expect(receipt.merchant, 'Fresh Mart');
    expect(receipt.date, DateTime(2026, 10, 8));
    expect(receipt.total, 40000);
  });

  test(
    'does not guess among unrelated currency amounts without a total label',
    () {
      final receipt = parser.parse('''
Mini Mart
Bread 20,000 VND
Milk 35,000 VND
''');

      expect(receipt.total, isNull);
    },
  );
}
