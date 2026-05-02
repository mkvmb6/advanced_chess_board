// Feature: chess-board-ux-enhancements, Property P1.23:
// After any successful tap/drag/programmatic move, no HintArrowPainter
// appears in the next pumped frame.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/hint/hint_arrow_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hint arrow dismiss on move', () {
    testWidgets(
      'P1.23: hint dismissed after programmatic move',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        const hint = HintArrow(startSquare: 'g1', endSquare: 'f3');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  hintArrow: hint,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Hint should be rendered.
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsOneWidget,
        );

        // Make a move programmatically.
        controller.makeMove(from: 'e2', to: 'e4');
        await tester.pumpAndSettle();

        // Hint should be dismissed.
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsNothing,
          reason: 'Hint should be dismissed after a successful move',
        );
      },
    );

    testWidgets(
      'P1.23: hint dismissed after tap move',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        const hint = HintArrow(startSquare: 'g1', endSquare: 'f3');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  hintArrow: hint,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Hint should be rendered.
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsOneWidget,
        );

        // Tap e2 then e4 to make a move.
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        const e2 = Offset(
          4 * squareSize + squareSize / 2,
          6 * squareSize + squareSize / 2,
        );
        const e4 = Offset(
          4 * squareSize + squareSize / 2,
          4 * squareSize + squareSize / 2,
        );

        await tester.tapAt(e2);
        await tester.pumpAndSettle();
        await tester.tapAt(e4);
        await tester.pumpAndSettle();

        // Hint should be dismissed.
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsNothing,
          reason: 'Hint should be dismissed after a tap move',
        );
      },
    );
  });
}
