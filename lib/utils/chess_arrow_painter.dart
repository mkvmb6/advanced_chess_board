import 'dart:math';

import 'package:flutter/material.dart';

import '../models/chess_arrow.dart';

class ChessArrowPainter extends CustomPainter {
  final List<ChessArrow> arrows;

  ChessArrowPainter(this.arrows);

  @override
  void paint(Canvas canvas, Size size) {
    final squareSize = size.width / 8;
    final arrowWidth = squareSize * 0.3;
    final paint = Paint()
      ..strokeWidth = arrowWidth
      ..style = PaintingStyle.stroke;

    for (var arrow in arrows) {
      paint.color = arrow.color.withOpacity(0.5);
      final start = _getSquareCenter(arrow.startSquare, squareSize);
      final end = _getSquareCenter(arrow.endSquare, squareSize);
      canvas.drawLine(start, end, paint);
      _drawArrowHead(canvas, paint, start, end, arrowWidth);
    }
  }

  Offset _getSquareCenter(String square, double squareSize) {
    final col = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final row = 8 - int.parse(square[1]);
    return Offset((col + 0.5) * squareSize, (row + 0.5) * squareSize);
  }

  // Draw a wide arrowhead to match the arrow body
  void _drawArrowHead(
      Canvas canvas, Paint paint, Offset start, Offset end, double arrowWidth) {
    final arrowHeadSize =
        arrowWidth * 1.5; // Adjust size relative to arrow width
    final angle = atan2(end.dy - start.dy, end.dx - start.dx);
    final path = Path();

    // Adjust for arrowhead width by positioning the points proportionally
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowHeadSize * cos(angle - pi / 6),
      end.dy - arrowHeadSize * sin(angle - pi / 6),
    );
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - arrowHeadSize * cos(angle + pi / 6),
      end.dy - arrowHeadSize * sin(angle + pi / 6),
    );

    // Fill in the path with a wider stroke for a bold arrow effect
    final arrowHeadPaint = Paint()
      ..color = paint.color
      ..strokeWidth = arrowWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, arrowHeadPaint);
  }

  @override
  bool shouldRepaint(covariant ChessArrowPainter oldDelegate) => true;
}
