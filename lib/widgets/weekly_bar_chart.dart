import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

class WeeklyBarChart extends StatelessWidget {
  const WeeklyBarChart({required this.totals, super.key})
    : assert(totals.length == 7);

  final List<int> totals;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: List.generate(
        7,
        (index) => '${WeeklyBarPainter.dayLabels[index]}: ${totals[index]} VND',
      ).join(', '),
      child: SizedBox(
        height: 240,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(totals.join(',')),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, progress, child) => CustomPaint(
            painter: WeeklyBarPainter(
              totals: totals,
              progress: progress,
              barColor: colors.primary,
              labelColor: colors.onSurfaceVariant,
              gridColor: colors.outlineVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class WeeklyBarPainter extends CustomPainter {
  WeeklyBarPainter({
    required this.totals,
    required this.progress,
    required this.barColor,
    required this.labelColor,
    required this.gridColor,
  });

  static const dayLabels = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  final List<int> totals;
  final double progress;
  final Color barColor;
  final Color labelColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 50) return;
    final maximum = totals.fold<int>(0, math.max);
    final baseline = size.height - 28;
    final availableHeight = baseline - 26;
    final slot = size.width / 7;
    final barWidth = slot * 0.55;
    final paint = Paint()..color = gridColor;
    for (var line = 0; line <= 2; line++) {
      final y = baseline - availableHeight * line / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    final format = NumberFormat.compact(locale: 'vi_VN');
    for (var index = 0; index < 7; index++) {
      final amount = math.max(0, totals[index]);
      final height = maximum == 0
          ? 0.0
          : amount / maximum * availableHeight * progress.clamp(0.0, 1.0);
      final center = slot * (index + 0.5);
      paint.color = amount == 0 ? gridColor : barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            center - barWidth / 2,
            baseline - height,
            barWidth,
            math.max(height, amount == 0 ? 2.0 : 0.0),
          ),
          const Radius.circular(4),
        ),
        paint,
      );
      _label(
        canvas,
        format.format(amount),
        center,
        baseline - height - 21,
        slot - 2,
      );
      _label(canvas, dayLabels[index], center, baseline + 8, slot - 2);
    }
  }

  void _label(
    Canvas canvas,
    String text,
    double center,
    double y,
    double width,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 11),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.max(0, width));
    painter.paint(canvas, Offset(center - painter.width / 2, y));
    painter.dispose();
  }

  @override
  bool shouldRepaint(covariant WeeklyBarPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      barColor != oldDelegate.barColor ||
      labelColor != oldDelegate.labelColor ||
      gridColor != oldDelegate.gridColor ||
      !listEquals(totals, oldDelegate.totals);
}
