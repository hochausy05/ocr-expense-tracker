class ParsedReceipt {
  const ParsedReceipt({this.merchant, this.date, this.total, this.rawText});

  final String? merchant;
  final DateTime? date;
  final int? total;
  final String? rawText;
}
