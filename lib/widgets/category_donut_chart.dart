import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../models/expense_statistics.dart';

const categoryColors = <Color>[
  Color(0xFF00897B),
  Color(0xFF3949AB),
  Color(0xFFEF6C00),
  Color(0xFF8E24AA),
  Color(0xFFD81B60),
];

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({required this.statistics, super.key});

  final ExpenseStatistics statistics;

  @override
  Widget build(BuildContext context) {
    final amounts = ExpenseCategory.values
        .map((category) => statistics.categoryTotals[category]!)
        .toList(growable: false);
    final format = NumberFormat.decimalPattern('vi_VN');
    return Column(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: AspectRatio(
              aspectRatio: 1,
              child: TweenAnimationBuilder<double>(
                key: ValueKey(amounts.join(',')),
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (context, progress, child) => CustomPaint(
                  painter: CategoryDonutPainter(
                    amounts: amounts,
                    progress: progress,
                    trackColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                  child: child,
                ),
                child: const Center(child: Text('Danh mục')),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final category in ExpenseCategory.values)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: categoryColors[category.index],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(category.label)),
                Flexible(
                  flex: 2,
                  child: Text(
                    '${format.format(amounts[category.index])} ₫ · '
                    '${statistics.percentage(category).toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class CategoryDonutPainter extends CustomPainter {
  CategoryDonutPainter({
    required this.amounts,
    required this.progress,
    required this.trackColor,
  });

  final List<int> amounts;
  final double progress;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final diameter = math.min(size.width, size.height);
    if (diameter <= 0) return;
    final stroke = diameter * 0.16;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (diameter - stroke) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawOval(rect, paint);
    final total = amounts.fold<int>(
      0,
      (sum, amount) => sum + math.max(0, amount),
    );
    if (total == 0) return;
    var start = -math.pi / 2;
    for (var index = 0; index < amounts.length; index++) {
      final sweep = math.max(0, amounts[index]) / total * math.pi * 2;
      paint.color = categoryColors[index % categoryColors.length];
      canvas.drawArc(
        rect,
        start,
        sweep * progress.clamp(0.0, 1.0),
        false,
        paint,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CategoryDonutPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      trackColor != oldDelegate.trackColor ||
      !listEquals(amounts, oldDelegate.amounts);
}
