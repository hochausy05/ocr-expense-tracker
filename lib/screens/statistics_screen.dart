import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/expense_statistics.dart';
import '../services/database_service.dart';
import '../widgets/category_donut_chart.dart';
import '../widgets/weekly_bar_chart.dart';

ExpenseStatistics _aggregateExpenses((List<Expense>, DateTime) input) =>
    ExpenseStatistics.fromExpenses(input.$1, now: input.$2);

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({this.loadExpenses, this.now, super.key});

  final Future<List<Expense>> Function()? loadExpenses;
  final DateTime Function()? now;

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with WidgetsBindingObserver {
  late Future<ExpenseStatistics> _statistics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _statistics = _load();
  }

  Future<ExpenseStatistics> _load() async {
    _isLoading = true;
    try {
      final expenses =
          await (widget.loadExpenses ?? DatabaseService.instance.getExpenses)();
      final now = (widget.now ?? DateTime.now)();
      // Keep aggregation off the rendering isolate on Android.
      return await compute(_aggregateExpenses, (expenses, now));
    } finally {
      _isLoading = false;
    }
  }

  Future<void> _reload() async {
    if (_isLoading) return;
    final loading = _load();
    setState(() {
      _statistics = loading;
    });
    try {
      await loading;
    } catch (_) {
      // FutureBuilder renders the error and provides a retry action.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'Làm mới',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<ExpenseStatistics>(
        future: _statistics,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    const Text('Không thể tải thống kê. Hãy thử lại.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _reload,
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }
          final statistics = snapshot.requireData;
          final money = NumberFormat.decimalPattern('vi_VN');
          final date = DateFormat('dd/MM/yyyy');
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tổng chi tiêu · Tất cả giao dịch'),
                        const SizedBox(height: 8),
                        Text(
                          '${money.format(statistics.total)} ₫',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                if (statistics.total == 0)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Chưa có khoản chi nào. Quét và lưu hóa đơn để xem thống kê.',
                    ),
                  ),
                const SizedBox(height: 12),
                _Section(
                  title: 'Chi tiêu theo danh mục',
                  child: CategoryDonutChart(statistics: statistics),
                ),
                const SizedBox(height: 16),
                _Section(
                  title: 'Chi tiêu tuần này',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${date.format(statistics.weekStart)} – ${date.format(statistics.weekEnd)}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${money.format(statistics.weeklyTotal)} ₫',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      WeeklyBarChart(totals: statistics.weeklyTotals),
                      if (statistics.weeklyTotal == 0)
                        const Text('Chưa có chi tiêu trong tuần này.'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}
