import '../models/parsed_receipt.dart';

class ReceiptParser {
  static final _datePattern = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{4})\b');
  static final _dateLikePattern = RegExp(
    r'\b\d{1,2}\s*[/-]\s*\d{1,2}\s*[/-]\s*\d{4}\b',
  );
  static final _amountPattern = RegExp(
    r'(?<!\d)(\d{1,3}(?:[.,\s\u00a0]\d{3})+|\d{4,}|\d{2,3})\s*(VND|VNĐ|Đ|đ|DONG)?(?!\d)',
    caseSensitive: false,
  );
  static final _standaloneAmountPattern = RegExp(
    r'^(?:\d{1,3}(?:[.,\s\u00a0]\d{3})+|\d{4,}|\d{2,3})\s*(?:VND|VNĐ|Đ|đ|DONG)?$',
    caseSensitive: false,
  );
  static final _longNumberPattern = RegExp(r'\d{8,}');

  static const _highPriorityTotalKeywords = [
    'grand total',
    'amount due',
    'total due',
    'tong cong',
    'tong thanh toan',
    'thanh toan',
    'phai tra',
    'tien phai tra',
  ];
  static const _totalKeywords = ['total', 'tong', 'tong tien'];
  static const _excludedKeywords = [
    'subtotal',
    'sub total',
    'discount',
    'giam gia',
    'khuyen mai',
    'tiet kiem',
    'tax',
    'vat',
    'ma so thue',
    'phone',
    'hotline',
    'address',
    'dia chi',
  ];

  ParsedReceipt parse(String rawText) {
    final lines = rawText.split(RegExp(r'\r?\n'));
    return ParsedReceipt(
      merchant: _parseMerchant(lines),
      date: _parseDate(rawText),
      total: _parseTotal(lines),
      rawText: rawText,
    );
  }

  String? _parseMerchant(List<String> lines) {
    for (final line in lines.take(8)) {
      final candidate = line.trim();
      if (candidate.length < 2 || candidate.length > 64) continue;

      final normalized = _normalize(candidate);
      if (_hasStaffContext(normalized)) return null;
      if (!_containsLetters(normalized) ||
          _datePattern.hasMatch(candidate) ||
          _amountPattern.hasMatch(candidate) ||
          _hasExcludedContext(normalized) ||
          _longNumberPattern.hasMatch(candidate) ||
          _isReceiptMetadataLine(normalized)) {
        continue;
      }

      if (_isGenericReceiptLine(normalized) || _looksLikeAddress(normalized)) {
        continue;
      }

      return candidate;
    }
    return null;
  }

  DateTime? _parseDate(String text) {
    for (final match in _datePattern.allMatches(text)) {
      final day = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      if (year < 1) continue;

      final date = DateTime(year, month, day);
      if (date.year == year && date.month == month && date.day == day) {
        return date;
      }
    }
    return null;
  }

  int? _parseTotal(List<String> lines) {
    final prioritized = <_TotalCandidate>[];
    final currencyAmounts = <int>[];

    for (var index = 0; index < lines.length; index++) {
      final line = lines[index].trim();
      final normalized = _normalize(line);
      final keywordScore = _totalKeywordScore(normalized);

      if (_isExcludedTotalLine(
        line,
        normalized,
        allowLongNumber: keywordScore > 0,
      )) {
        continue;
      }

      final amounts = _findAmounts(line);
      if (amounts.isNotEmpty && amounts.any((amount) => amount.hasCurrency)) {
        currencyAmounts.addAll(
          amounts
              .where((amount) => amount.hasCurrency)
              .map((amount) => amount.value),
        );
      }

      if (keywordScore == 0) continue;

      if (amounts.isNotEmpty) {
        final amount = _chooseAmount(amounts);
        if (amount != null) {
          prioritized.add(
            _TotalCandidate(
              score: keywordScore * 10000 + 2000,
              lineIndex: index,
              amount: amount,
            ),
          );
        }
        continue;
      }

      final windowEnd = index + 25 < lines.length ? index + 25 : lines.length;
      final hasCurrencyContext = lines
          .skip(index + 1)
          .take(windowEnd - index - 1)
          .any(
            (candidateLine) => _hasCurrencyContext(_normalize(candidateLine)),
          );
      final hasPaymentContext = lines
          .skip(index)
          .take(windowEnd - index)
          .any(
            (candidateLine) => _hasPaymentContext(_normalize(candidateLine)),
          );
      final tailStart = windowEnd - 6 > index + 1 ? windowEnd - 6 : index + 1;

      for (
        var candidateIndex = index + 1;
        candidateIndex < windowEnd;
        candidateIndex++
      ) {
        final candidateLine = lines[candidateIndex].trim();
        final normalizedCandidate = _normalize(candidateLine);
        if (_isExcludedTotalLine(candidateLine, normalizedCandidate) ||
            !_isPlausibleSeparatedAmountLine(
              lines,
              candidateIndex,
              normalizedCandidate,
            )) {
          continue;
        }

        final candidates = _findAmounts(candidateLine);
        for (final amount in candidates) {
          final repeatedInTail =
              _countAmountInRange(lines, tailStart, windowEnd, amount.value) >=
              2;
          final distance = candidateIndex - index;
          final corroborated =
              amount.hasCurrency ||
              hasCurrencyContext ||
              (hasPaymentContext && candidateIndex >= index + 1) ||
              repeatedInTail;
          if (distance > 3 && !corroborated) continue;

          final contextScore = _separatedAmountScore(
            distance: distance,
            amount: amount,
            hasCurrencyContext: hasCurrencyContext,
            hasPaymentContext: hasPaymentContext,
            isInTail: candidateIndex >= tailStart,
            repeatedInTail: repeatedInTail,
          );
          if (contextScore < 40) continue;

          prioritized.add(
            _TotalCandidate(
              score: keywordScore * 10000 + contextScore,
              lineIndex: candidateIndex,
              amount: amount.value,
            ),
          );
        }
      }
    }

    if (prioritized.isNotEmpty) {
      prioritized.sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        return byScore != 0 ? byScore : b.lineIndex.compareTo(a.lineIndex);
      });
      return prioritized.first.amount;
    }

    // A currency-marked amount is safe as a fallback only when the receipt
    // contains exactly one eligible amount; otherwise a line item may win.
    if (currencyAmounts.length == 1) return currencyAmounts.single;
    return null;
  }

  int _totalKeywordScore(String normalizedLine) {
    for (final keyword in _highPriorityTotalKeywords) {
      if (_containsKeyword(normalizedLine, keyword)) return 3;
    }
    for (final keyword in _totalKeywords) {
      if (_containsKeyword(normalizedLine, keyword)) return 2;
    }
    if (RegExp(r'(^|[^a-z0-9])t\s*\.?\s*cong(?=$|[^a-z0-9])')
        .hasMatch(normalizedLine)) {
      return 3;
    }
    return 0;
  }

  bool _isExcludedTotalLine(
    String line,
    String normalized, {
    bool allowLongNumber = false,
  }) {
    if (_hasExcludedContext(normalized) || _dateLikePattern.hasMatch(line)) {
      return true;
    }
    return _longNumberPattern.hasMatch(line) &&
        !allowLongNumber &&
        !_standaloneAmountPattern.hasMatch(line);
  }

  bool _isPlausibleSeparatedAmountLine(
    List<String> lines,
    int index,
    String normalized,
  ) {
    if (_isQuantityLine(lines, index)) return false;
    return _standaloneAmountPattern.hasMatch(lines[index].trim()) ||
        (_hasPaymentContext(normalized) &&
            _findAmounts(lines[index]).isNotEmpty);
  }

  bool _isQuantityLine(List<String> lines, int index) {
    final line = lines[index].trim();
    if (RegExp(r'\b\d+\s*[x×]\s*', caseSensitive: false).hasMatch(line)) {
      return true;
    }
    if (index == 0) return false;
    return RegExp(
      r'^\d+\s*[x×]$',
      caseSensitive: false,
    ).hasMatch(lines[index - 1].trim());
  }

  bool _hasCurrencyContext(String normalizedLine) {
    return _containsKeyword(normalizedLine, 'vnd') ||
        _containsKeyword(normalizedLine, 'dong');
  }

  bool _hasPaymentContext(String normalizedLine) {
    const keywords = ['khach tra', 'thanh toan', 'amount due', 'paid'];
    return keywords.any((keyword) => _containsKeyword(normalizedLine, keyword));
  }

  int _countAmountInRange(List<String> lines, int start, int end, int value) {
    var count = 0;
    for (var index = start; index < end; index++) {
      final line = lines[index].trim();
      final normalized = _normalize(line);
      if (_isExcludedTotalLine(line, normalized) ||
          !_isPlausibleSeparatedAmountLine(lines, index, normalized)) {
        continue;
      }
      if (_findAmounts(line).any((amount) => amount.value == value)) count++;
    }
    return count;
  }

  int _separatedAmountScore({
    required int distance,
    required _AmountCandidate amount,
    required bool hasCurrencyContext,
    required bool hasPaymentContext,
    required bool isInTail,
    required bool repeatedInTail,
  }) {
    final proximity = distance >= 24 ? 0 : 24 - distance;
    var score = 20 + proximity;
    if (amount.hasCurrency) score += 20;
    if (hasCurrencyContext) score += 8;
    if (hasPaymentContext) score += 25;
    if (isInTail) score += 15;
    if (repeatedInTail) score += 25;
    return score;
  }

  List<_AmountCandidate> _findAmounts(String line) {
    final amounts = <_AmountCandidate>[];
    for (final match in _amountPattern.allMatches(line)) {
      final digits = match.group(1)!.replaceAll(RegExp(r'[.,\s\u00a0]'), '');
      final value = int.tryParse(digits);
      if (value == null || value <= 0) continue;
      amounts.add(_AmountCandidate(value, hasCurrency: match.group(2) != null));
    }
    return amounts;
  }

  int? _chooseAmount(List<_AmountCandidate> amounts) {
    final withCurrency = amounts.where((amount) => amount.hasCurrency);
    final candidates = withCurrency.isNotEmpty ? withCurrency : amounts;
    return candidates.isEmpty ? null : candidates.last.value;
  }

  bool _hasExcludedContext(String line) {
    return _excludedKeywords.any((keyword) => _containsKeyword(line, keyword));
  }

  bool _isGenericReceiptLine(String line) {
    const labels = [
      'receipt',
      'invoice',
      'phieu tinh tien',
      'hoa don',
      'hoa don ban hang',
      'customer copy',
      'cashier copy',
      'bill no',
      'order no',
    ];
    return labels.any((label) => line == label || line.startsWith('$label '));
  }

  bool _isReceiptMetadataLine(String line) {
    return RegExp(r'^lien\s*\d+$').hasMatch(line) ||
        RegExp(r'^soh?\.?don\b').hasMatch(line) ||
        const ['ban', 'phuc vu'].any((label) => line == label) ||
        line.startsWith('gio vao') ||
        line.startsWith('gio ra');
  }

  bool _hasStaffContext(String normalizedLine) {
    const keywords = ['nhan vien', 'staff', 'employee'];
    return keywords.any((keyword) => _containsKeyword(normalizedLine, keyword));
  }

  bool _looksLikeAddress(String line) {
    const addressTerms = [
      'duong',
      'street',
      'road',
      'district',
      'quan ',
      'phuong ',
      'ward ',
      'dia chi',
      'address',
    ];
    return addressTerms.any((term) => _containsKeyword(line, term.trim()));
  }

  bool _containsLetters(String line) => RegExp(r'[a-z]').hasMatch(line);

  bool _containsKeyword(String line, String keyword) {
    final expression = keyword.split(' ').map(RegExp.escape).join(r'\s+');
    return RegExp(r'(^|[^a-z0-9])' + expression + r'(?=$|[^a-z0-9])')
        .hasMatch(line);
  }

  String _normalize(String value) {
    var normalized = value.toLowerCase();
    const replacements = {
      'a': 'áàảãạăắằẳẵặâấầẩẫậ',
      'e': 'éèẻẽẹêếềểễệ',
      'i': 'íìỉĩị',
      'o': 'óòỏõọôốồổỗộơớờởỡợ',
      'u': 'úùủũụưứừửữự',
      'y': 'ýỳỷỹỵ',
      'd': 'đ',
    };
    for (final entry in replacements.entries) {
      for (final character in entry.value.runes) {
        normalized = normalized.replaceAll(
          String.fromCharCode(character),
          entry.key,
        );
      }
    }
    return normalized.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _AmountCandidate {
  const _AmountCandidate(this.value, {required this.hasCurrency});

  final int value;
  final bool hasCurrency;
}

class _TotalCandidate {
  const _TotalCandidate({
    required this.score,
    required this.lineIndex,
    required this.amount,
  });

  final int score;
  final int lineIndex;
  final int amount;
}
