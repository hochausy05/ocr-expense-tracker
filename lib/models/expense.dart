enum ExpenseCategory {
  food('Food'),
  study('Study'),
  travel('Travel'),
  gear('Gear'),
  entertainment('Entertainment');

  const ExpenseCategory(this.label);

  final String label;

  static ExpenseCategory fromStorageValue(String value) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.label == value,
      orElse: () => throw FormatException('Unknown expense category: $value'),
    );
  }
}

class Expense {
  const Expense({
    this.id,
    required this.merchant,
    required this.amount,
    required this.transactionDate,
    required this.category,
    this.receiptImagePath,
    required this.createdAt,
  });

  final int? id;
  final String merchant;
  final int amount;
  final DateTime transactionDate;
  final ExpenseCategory category;
  final String? receiptImagePath;
  final DateTime createdAt;

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'merchant': merchant,
      'amount': amount,
      'transaction_date': transactionDate.toUtc().toIso8601String(),
      'category': category.label,
      'receipt_image_path': receiptImagePath,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: (map['id'] as num?)?.toInt(),
      merchant: map['merchant'] as String,
      amount: (map['amount'] as num).toInt(),
      transactionDate: DateTime.parse(map['transaction_date'] as String)
          .toLocal(),
      category: ExpenseCategory.fromStorageValue(map['category'] as String),
      receiptImagePath: map['receipt_image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
