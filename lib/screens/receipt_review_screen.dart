import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/parsed_receipt.dart';
import '../services/database_service.dart';
import '../services/image_storage_service.dart';

class ReceiptReviewScreen extends StatefulWidget {
  const ReceiptReviewScreen({
    required this.imagePath,
    required this.parsedReceipt,
    this.ocrError,
    this.storeImage,
    this.insertExpense,
    super.key,
  });

  final String imagePath;
  final ParsedReceipt parsedReceipt;
  final String? ocrError;
  final Future<String> Function(File)? storeImage;
  final Future<int> Function(Expense)? insertExpense;

  @override
  State<ReceiptReviewScreen> createState() => _ReceiptReviewScreenState();
}

class _ReceiptReviewScreenState extends State<ReceiptReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantController;
  late final TextEditingController _dateController;
  late final TextEditingController _amountController;
  ExpenseCategory? _category;
  bool _showCategoryError = false;
  bool _isSaving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(
      text: widget.parsedReceipt.merchant ?? '',
    );
    _dateController = TextEditingController(
      text: widget.parsedReceipt.date == null
          ? ''
          : DateFormat('dd/MM/yyyy').format(widget.parsedReceipt.date!),
    );
    _amountController = TextEditingController(
      text: widget.parsedReceipt.total?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _dateController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final formIsValid = _formKey.currentState?.validate() ?? false;
    final category = _category;
    setState(() => _showCategoryError = category == null);
    if (!formIsValid || category == null) return;

    final date = DateFormat('dd/MM/yyyy')
        .parseStrict(_dateController.text.trim());
    final amount = int.parse(_amountController.text.trim());
    final merchant = _merchantController.text.trim();
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    String? storedPath;
    var inserted = false;
    try {
      storedPath =
          await (widget.storeImage ??
              const ImageStorageService().storeReceiptImage)(
            File(widget.imagePath),
          );
      final expense = Expense(
        merchant: merchant,
        amount: amount,
        transactionDate: date,
        category: category,
        receiptImagePath: storedPath,
        createdAt: DateTime.now(),
      );
      final id =
          await (widget.insertExpense ??
              DatabaseService.instance.insertExpense)(expense);
      if (id <= 0) throw StateError('Expense insertion failed.');
      inserted = true;
      if (mounted) {
        setState(() => _isSaving = false);
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!inserted && storedPath != null) {
        try {
          await File(storedPath).delete();
        } on FileSystemException {
          // Keep the original error visible; the copied file may already be gone.
        }
      }
      if (mounted) {
        setState(() => _saveError = 'Không thể lưu khoản chi. Hãy thử lại.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final parsed = widget.parsedReceipt;
    final hasIncompleteFields =
        parsed.merchant == null || parsed.date == null || parsed.total == null;
    final message =
        widget.ocrError ??
        (hasIncompleteFields
            ? 'Một số thông tin chưa nhận diện được. Bạn có thể nhập hoặc sửa bên dưới.'
            : null);

    return PopScope(
      canPop: !_isSaving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kiểm tra hóa đơn'),
          leading: IconButton(
            tooltip: 'Hủy và chụp lại',
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _ReceiptPreview(imagePath: widget.imagePath),
              if (message != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline),
                      const SizedBox(width: 10),
                      Expanded(child: Text(message)),
                    ],
                  ),
                ),
              ],
              if (parsed.rawText?.trim().isNotEmpty ?? false)
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Văn bản nhận dạng'),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: SelectableText(parsed.rawText!),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _merchantController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Cửa hàng',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Nhập tên cửa hàng.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _dateController,
                enabled: !_isSaving,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Ngày giao dịch',
                  hintText: 'DD/MM/YYYY',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                validator: _validateDate,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Tổng tiền (VND)',
                  suffixText: '₫',
                  border: OutlineInputBorder(),
                ),
                validator: _validateAmount,
              ),
              const SizedBox(height: 20),
              Text('Danh mục', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((category) {
                  return ChoiceChip(
                    label: Text(category.label),
                    selected: _category == category,
                    onSelected: _isSaving
                        ? null
                        : (selected) {
                            setState(() {
                              _category = selected ? category : null;
                              _showCategoryError = false;
                            });
                          },
                  );
                }).toList(),
              ),
              if (_showCategoryError) ...[
                const SizedBox(height: 6),
                Text(
                  'Chọn một danh mục.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _saveError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_isSaving) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const Text('Đang lưu khoản chi…'),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Chụp lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.check),
                      label: const Text('Lưu khoản chi'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateDate(String? value) {
    if (value == null || value.trim().isEmpty) return 'Nhập ngày giao dịch.';
    try {
      DateFormat('dd/MM/yyyy').parseStrict(value.trim());
      return null;
    } on FormatException {
      return 'Ngày không hợp lệ. Dùng định dạng DD/MM/YYYY.';
    }
  }

  String? _validateAmount(String? value) {
    final amount = int.tryParse(value?.trim() ?? '');
    if (amount == null || amount <= 0) {
      return 'Nhập số tiền VND lớn hơn 0.';
    }
    return null;
  }
}

class _ReceiptPreview extends StatelessWidget {
  const _ReceiptPreview({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 220,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.broken_image_outlined, size: 40),
              SizedBox(height: 8),
              Text('Không thể hiển thị ảnh hóa đơn.'),
            ],
          ),
        ),
      ),
    );
  }
}
