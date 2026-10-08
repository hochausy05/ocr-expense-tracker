import 'package:flutter/material.dart';

import '../models/expense.dart';
import '../services/database_service.dart';
import '../widgets/expense_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({required this.onScan, super.key});

  final VoidCallback onScan;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Expense>> _expenses;

  @override
  void initState() {
    super.initState();
    _expenses = DatabaseService.instance.getExpenses();
  }

  Future<void> _reloadExpenses() async {
    setState(() {
      _expenses = DatabaseService.instance.getExpenses();
    });
    await _expenses;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiêu'),
        actions: [
          IconButton(
            onPressed: widget.onScan,
            tooltip: 'Quét hóa đơn',
            icon: const Icon(Icons.document_scanner_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<Expense>>(
        future: _expenses,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _MessageState(
              icon: Icons.error_outline,
              message: 'Không thể tải danh sách chi tiêu.',
            );
          }

          final expenses = snapshot.data ?? const <Expense>[];
          if (expenses.isEmpty) {
            return _EmptyExpensesState(onScan: widget.onScan);
          }

          return RefreshIndicator(
            onRefresh: _reloadExpenses,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: expenses.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Giao dịch gần đây',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }
                return ExpenseCard(expense: expenses[index - 1]);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: widget.onScan,
        icon: const Icon(Icons.add),
        label: const Text('Quét hóa đơn'),
      ),
    );
  }
}

class _EmptyExpensesState extends StatelessWidget {
  const _EmptyExpensesState({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có khoản chi nào',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Quét hóa đơn để bắt đầu lưu lại chi tiêu của bạn.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Quét hóa đơn'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
