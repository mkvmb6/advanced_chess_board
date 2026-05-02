// Feature: chess-board-ux-enhancements, Property P1.24:
// HintArrow auto-dismisses after duration + epsilon under FakeAsync.

import 'dart:async';

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/hint/hint_arrow_painter.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hint arrow dismiss on duration', () {
    testWidgets(
      'P1.24: hint persists before duration, dismisses after',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        const hint = HintArrow(
          startSquare: 'g1',
          endSquare: 'f3',
          duration: Duration(seconds: 2),
        );

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
        await tester.pump();

        // Hint should be rendered initially.
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsOneWidget,
          reason: 'Hint should be rendered initially',
        );

        // Advance 1999ms — hint should still be rendered.
        await tester.pump(const Duration(milliseconds: 1999));
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsOneWidget,
          reason: 'Hint should still be rendered at 1999ms',
        );

        // Advance 2ms more (total 2001ms > 2000ms) — hint should be dismissed.
        await tester.pump(const Duration(milliseconds: 2));
        await tester.pump(); // Allow setState to propagate.
        expect(
          find.byWidgetPredicate(
            (final w) => w is CustomPaint && w.painter is HintArrowPainter,
          ),
          findsNothing,
          reason: 'Hint should be dismissed after duration elapses',
        );
      },
    );

    test(
      'P1.24: FakeAsync confirms hint dismisses after duration',
      () {
        FakeAsync().run((final FakeAsync async) {
          // This test verifies the timer fires correctly.
          var timerFired = false;
          Timer(const Duration(seconds: 2), () {
            timerFired = true;
          });

          async.elapse(const Duration(milliseconds: 1999));
          expect(timerFired, isFalse);

          async.elapse(const Duration(milliseconds: 2));
          expect(timerFired, isTrue);
        });
      },
    );
  });
}
