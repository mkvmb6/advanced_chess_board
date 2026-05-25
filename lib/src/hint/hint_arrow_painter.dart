import 'dart:math';

import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/board_theme.dart';
import '../utils/arrow_geometry.dart';
import 'hint_arrow.dart';

/// Paints a single [HintArrow] with a visually distinct style from
/// [ArrowPainter]:
/// - Dashed shaft (blockSize*0.15 on / blockSize*0.10 off).
/// - Stroke-only outlined arrowhead (no fill).
/// - Thinner stroke width (blockSize*0.12 vs ArrowPainter's 0.16).
/// - Colour: [BoardTheme.hintArrowColor].
class HintArrowPainter extends CustomPainter {
  /// Creates a [HintArrowPainter].
  HintArrowPainter(this.arrow, this.theme, this.orientation);

  /// The hint arrow to paint.
  final HintArrow arrow;

  /// The board theme providing the hint arrow colour.
  final BoardTheme theme;

  /// Orientation of the board; controls the square → canvas mapping.
  final PlayerColor orientation;

  @override
  void paint(final Canvas canvas, final Size size) {
    final (sourceRow, sourceCol) =
        getIndexFromSquare(arrow.startSquare, orientation);
    final (destRow, destCol) = getIndexFromSquare(arrow.endSquare, orientation);
    final blockSize = size.width / 8;

    // Calculate centers of the source and destination squares.
    final sourceX = sourceCol * blockSize + blockSize / 2;
    final sourceY = sourceRow * blockSize + blockSize / 2;
    final destX = destCol * blockSize + blockSize / 2;
    final destY = destRow * blockSize + blockSize / 2;

    // Vector calculation between source and destination.
    final dx = destX - sourceX;
    final dy = destY - sourceY;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance < 1e-6) return; // zero-length arrow — nothing to paint.

    // Define lengths for offsets and arrowhead sides.
    final sourceThreshold = blockSize * 0.35;
    final destinationThreshold = blockSize * 0.272;
    final arrowheadSideLength = blockSize * 0.2;

    // Adjusted endpoints.
    final adjustedSourceX = sourceX + (dx / distance) * sourceThreshold;
    final adjustedSourceY = sourceY + (dy / distance) * sourceThreshold;
    final adjustedDestX =
        destX - (dx / distance) * (arrowheadSideLength * cos(pi / 6));
    final adjustedDestY =
        destY - (dy / distance) * (arrowheadSideLength * cos(pi / 6));
    final strokeDestX = destX - (dx / distance) * destinationThreshold;
    final strokeDestY = destY - (dy / distance) * destinationThreshold;

    final color = theme.hintArrowColor;

    // Draw dashed shaft.
    final shaftPaint = Paint()
      ..color = color
      ..strokeWidth = blockSize * 0.12
      ..strokeCap = StrokeCap.round;

    final dashLength = blockSize * 0.15;
    final gapLength = blockSize * 0.10;
    final totalLength = sqrt(
      pow(strokeDestX - adjustedSourceX, 2) +
          pow(strokeDestY - adjustedSourceY, 2),
    );
    final unitX = (strokeDestX - adjustedSourceX) / totalLength;
    final unitY = (strokeDestY - adjustedSourceY) / totalLength;

    var t = 0.0;
    while (t < totalLength) {
      final segEnd = min(t + dashLength, totalLength);
      canvas.drawLine(
        Offset(adjustedSourceX + unitX * t, adjustedSourceY + unitY * t),
        Offset(
          adjustedSourceX + unitX * segEnd,
          adjustedSourceY + unitY * segEnd,
        ),
        shaftPaint,
      );
      t += dashLength + gapLength;
    }

    // Draw stroke-only arrowhead.
    final angle = atan2(dy, dx);
    final tipX = destX;
    final tipY = destY;
    final baseX1 = adjustedDestX - arrowheadSideLength * cos(angle - pi / 3);
    final baseY1 = adjustedDestY - arrowheadSideLength * sin(angle - pi / 3);
    final baseX2 = adjustedDestX - arrowheadSideLength * cos(angle + pi / 3);
    final baseY2 = adjustedDestY - arrowheadSideLength * sin(angle + pi / 3);

    final trianglePath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(baseX1, baseY1)
      ..lineTo(baseX2, baseY2)
      ..close();

    final headPaint = Paint()
      ..color = color
      ..strokeWidth = blockSize * 0.06
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(trianglePath, headPaint);
  }

  @override
  bool shouldRepaint(covariant final HintArrowPainter old) {
    return old.arrow != arrow ||
        old.theme.hintArrowColor != theme.hintArrowColor ||
        old.orientation != orientation;
  }
}
