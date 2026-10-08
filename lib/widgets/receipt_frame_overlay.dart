import 'dart:math' as math;

import 'package:flutter/material.dart';

class ReceiptFrameOverlay extends StatelessWidget {
  const ReceiptFrameOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: const _ReceiptFramePainter(),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ReceiptFramePainter extends CustomPainter {
  const _ReceiptFramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = size.width * 0.82;
    final frameHeight = math.min(size.height * 0.62, frameWidth * 1.35);
    final frame = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: frameWidth,
        height: frameHeight,
      ),
      const Radius.circular(16),
    );

    final shadePath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRRect(frame);
    canvas.drawPath(
      shadePath,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    canvas.drawRRect(
      frame,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final rect = frame.outerRect;
    final cornerLength = math.min(rect.width, rect.height) * 0.12;
    final corners = Path()
      ..moveTo(rect.left, rect.top + cornerLength)
      ..lineTo(rect.left, rect.top)
      ..lineTo(rect.left + cornerLength, rect.top)
      ..moveTo(rect.right - cornerLength, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.top + cornerLength)
      ..moveTo(rect.left, rect.bottom - cornerLength)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left + cornerLength, rect.bottom)
      ..moveTo(rect.right - cornerLength, rect.bottom)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.right, rect.bottom - cornerLength);
    canvas.drawPath(
      corners,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ReceiptFramePainter oldDelegate) => false;
}
