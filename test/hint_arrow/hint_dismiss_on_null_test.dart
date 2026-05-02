// Feature: chess-board-ux-enhancements, Property P1.26:
// Setting hintArrow to null dismisses the active hint on the next frame.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/hint/hint_arrow_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hint arrow dismiss on null', () {
    testWidgets(
      'P1.26: setting hintArrow to null dismisses the hint',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        const hint = HintArrow(startSquare: 'g1', endSquare: 'f3');

        // Pump with hint.
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
          reason: 'Hint should be rendered initially',
        );

        // Rebuild with null hint.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Hint should be dismissed.
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsNothing,
          reason: 'Hint should be dismissed when hintArrow is set to null',
        );
      },
    );
  });
}
