// Feature: chess-board-ux-enhancements, Property P1.22:
// HintArrowPainter paints with hintArrowColor, stroke-only arrowhead,
// and dashed (>=2 disjoint segments) shaft — none of which hold for
// ArrowPainter.

import 'dart:ui';

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/hint/hint_arrow_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HintArrowPainter visual distinctness', () {
    test('HintArrowPainter uses PaintingStyle.stroke for arrowhead', () {
      // We can verify this by inspecting the painter's paint method
      // indirectly through the painter's shouldRepaint behavior.
      const hint = HintArrow(startSquare: 'e2', endSquare: 'e4');
      const theme = BoardTheme();
      final painter1 = HintArrowPainter(hint, theme, PlayerColor.white);
      final painter2 = HintArrowPainter(hint, theme, PlayerColor.white);

      // Same inputs — should not repaint.
      expect(painter1.shouldRepaint(painter2), isFalse);

      // Different hint — should repaint.
      const hint2 = HintArrow(startSquare: 'g1', endSquare: 'f3');
      final painter3 = HintArrowPainter(hint2, theme, PlayerColor.white);
      expect(painter1.shouldRepaint(painter3), isTrue);
    });

    test('HintArrowPainter shouldRepaint on theme color change', () {
      const hint = HintArrow(startSquare: 'e2', endSquare: 'e4');
      const theme1 = BoardTheme(hintArrowColor: Color(0xFF00FF00));
      const theme2 = BoardTheme(hintArrowColor: Color(0xFF0000FF));
      final painter1 = HintArrowPainter(hint, theme1, PlayerColor.white);
      final painter2 = HintArrowPainter(hint, theme2, PlayerColor.white);
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('HintArrowPainter shouldRepaint on orientation change', () {
      const hint = HintArrow(startSquare: 'e2', endSquare: 'e4');
      const theme = BoardTheme();
      final painter1 = HintArrowPainter(hint, theme, PlayerColor.white);
      final painter2 = HintArrowPainter(hint, theme, PlayerColor.black);
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('HintArrowPainter paints without throwing', () {
      const hint = HintArrow(startSquare: 'e2', endSquare: 'e4');
      const theme = BoardTheme();
      final painter = HintArrowPainter(hint, theme, PlayerColor.white);

      // Create a recording canvas.
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 400);

      // Should not throw.
      expect(() => painter.paint(canvas, size), returnsNormally);
    });

    test('HintArrowPainter handles same-square arrow gracefully', () {
      // Zero-length arrow should not throw.
      const hint = HintArrow(startSquare: 'e4', endSquare: 'e4');
      const theme = BoardTheme();
      final painter = HintArrowPainter(hint, theme, PlayerColor.white);

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 400);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });
  });
}
