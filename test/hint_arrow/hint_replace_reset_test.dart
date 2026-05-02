// Feature: chess-board-ux-enhancements, Property P1.25:
// Replacing hintArrow before the previous dismissed resets the timer.
// b persists past a's dismiss time, and dismisses b.duration after
// b was set.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/hint/hint_arrow_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hint arrow replace resets timer', () {
    testWidgets(
      'P1.25: replacing hint resets the timer',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        const hintA = HintArrow(
          startSquare: 'g1',
          endSquare: 'f3',
          duration: Duration(seconds: 2),
        );
        const hintB = HintArrow(
          startSquare: 'e2',
          endSquare: 'e4',
          duration: Duration(seconds: 2),
        );

        // Pump with hint A.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  hintArrow: hintA,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Advance 1000ms — hint A still active.
        await tester.pump(const Duration(milliseconds: 1000));
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsOneWidget,
          reason: 'Hint A should still be active at 1000ms',
        );

        // Replace with hint B.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  hintArrow: hintB,
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Advance 1000ms more (total 2000ms from A's start, 1000ms from B's start).
        // A would have dismissed at 2000ms, but B's timer was reset.
        await tester.pump(const Duration(milliseconds: 1000));
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsOneWidget,
          reason: 'Hint B should still be active (timer was reset)',
        );

        // Advance 1100ms more (total 2100ms from B's start > 2000ms).
        await tester.pump(const Duration(milliseconds: 1100));
        await tester.pump(); // Allow setState to propagate.
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsNothing,
          reason: 'Hint B should be dismissed after its duration elapses',
        );
      },
    );
  });
}
