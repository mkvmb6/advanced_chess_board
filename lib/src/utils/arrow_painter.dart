import 'dart:math';

import 'package:flutter/material.dart';

import '../models/chess_arrow.dart';
import '../models/enums.dart';
import 'arrow_geometry.dart';

/// Paints [ChessArrow] annotations over the chess board.
///
/// Each arrow is drawn as a main line plus an equilateral-triangle arrowhead
/// whose size is derived from the board square size. The painter is
/// orientation-aware: when the board flips, arrows flip with it.
class ArrowPainter extends CustomPainter {
  /// Creates an [ArrowPainter] that draws [arrows] for the given
  /// [boardOrientation].
  ArrowPainter(this.arrows, this.boardOrientation);

  /// Arrows to draw on top of the board.
  final List<ChessArrow> arrows;

  /// Orientation of the board. Used to map algebraic squares to canvas
  /// coordinates.
  final PlayerColor boardOrientation;

  @override
  void paint(final Canvas canvas, final Size size) {
    for (final arrow in arrows) {
      final (sourceRow, sourceCol) =
          getIndexFromSquare(arrow.startSquare, boardOrientation);
      final (destRow, destCol) =
          getIndexFromSquare(arrow.endSquare, boardOrientation);
      final blockSize = size.width / 8;

      // Calculate centers of the source and destination squares.
      final sourceX = sourceCol * blockSize + (blockSize / 2);
      final sourceY = sourceRow * blockSize + (blockSize / 2);
      final destX = destCol * blockSize + (blockSize / 2);
      final destY = destRow * blockSize + (blockSize / 2);

      // Vector calculation between source and destination.
      final dx = destX - sourceX;
      final dy = destY - sourceY;
      final distance = sqrt(dx * dx + dy * dy);

      // Define lengths for offsets and arrowhead sides.
      final sourceThreshold = blockSize * 0.35;
      final destinationThreshold = blockSize * 0.272;
      final arrowheadSideLength = blockSize * 0.2;

      // Main line's adjusted endpoint (just before the arrowhead base).
      final adjustedSourceX = sourceX + (dx / distance) * sourceThreshold;
      final adjustedSourceY = sourceY + (dy / distance) * sourceThreshold;
      final adjustedDestX =
          destX - (dx / distance) * (arrowheadSideLength * cos(pi / 6));
      final adjustedDestY =
          destY - (dy / distance) * (arrowheadSideLength * cos(pi / 6));
      final strokeDestX = destX - (dx / distance) * destinationThreshold;
      final strokeDestY = destY - (dy / distance) * destinationThreshold;

      // Draw the main arrow line.
      final paint = Paint()
        ..color = arrow.color!
        ..strokeWidth = blockSize * 0.16;
      canvas.drawLine(
        Offset(adjustedSourceX, adjustedSourceY),
        Offset(strokeDestX, strokeDestY),
        paint,
      );

      // Equilateral triangle arrowhead: tip at destination, two base points
      // at the adjusted endpoint.
      final angle = atan2(dy, dx);
      final tipX = destX;
      final tipY = destY;
      final baseX1 = adjustedDestX - arrowheadSideLength * cos(angle - pi / 3);
      final baseY1 = adjustedDestY - arrowheadSideLength * sin(angle - pi / 3);
      final baseX2 = adjustedDestX - arrowheadSideLength * cos(angle + pi / 3);
      final baseY2 = adjustedDestY - arrowheadSideLength * sin(angle + pi / 3);

      final arrowheadPath = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(baseX1, baseY1)
        ..lineTo(baseX2, baseY2)
        ..close();

      final arrowheadPaint = Paint()..color = arrow.color!;
      canvas.drawPath(arrowheadPath, arrowheadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ArrowPainter old) {
    if (old.boardOrientation != boardOrientation) {
      return true;
    }
    if (old.arrows.length != arrows.length) {
      return true;
    }
    for (var i = 0; i < arrows.length; i++) {
      if (arrows[i] != old.arrows[i]) {
        return true;
      }
    }
    return false;
  }
}
