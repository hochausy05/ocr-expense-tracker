import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';

class ExpenseCard extends StatelessWidget {
  const ExpenseCard({required this.expense, super.key});

  final Expense expense;

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.decimalPattern('vi_VN').format(expense.amount);
    final date = DateFormat('dd/MM/yyyy').format(expense.transactionDate);
    final imagePath = expense.receiptImagePath;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: imagePath == null || imagePath.trim().isEmpty
            ? const _ReceiptPlaceholder()
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const _ReceiptPlaceholder(),
                ),
              ),
        title: Text(
          expense.merchant,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('$date · ${expense.category.label}'),
        ),
        trailing: Text(
          '$amount ₫',
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ReceiptPlaceholder extends StatelessWidget {
  const _ReceiptPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.receipt_long_outlined),
    );
  }
}
