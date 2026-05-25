// Feature: chess-board-ux-enhancements, Property P1.21:
// HintArrowPainter's CustomPaint child index > ArrowPainter's child
// index in the ListenableBuilder's Stack.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/hint/hint_arrow_painter.dart';
import 'package:advanced_chess_board/src/utils/arrow_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HintArrowPainter layer order', () {
    testWidgets(
      'P1.21: HintArrowPainter CustomPaint is above ArrowPainter CustomPaint',
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
                  arrows: <ChessArrow>[
                    ChessArrow(startSquare: 'e2', endSquare: 'e4'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find all CustomPaint widgets.
        final customPaints = tester
            .widgetList<CustomPaint>(
              find.byType(CustomPaint),
            )
            .toList();

        // Find the ArrowPainter and HintArrowPainter CustomPaints.
        int arrowPainterIndex = -1;
        int hintPainterIndex = -1;

        for (var i = 0; i < customPaints.length; i++) {
          if (customPaints[i].painter is ArrowPainter) {
            arrowPainterIndex = i;
          }
          if (customPaints[i].painter is HintArrowPainter) {
            hintPainterIndex = i;
          }
        }

        expect(
          arrowPainterIndex,
          greaterThanOrEqualTo(0),
          reason: 'ArrowPainter CustomPaint must be present',
        );
        expect(
          hintPainterIndex,
          greaterThanOrEqualTo(0),
          reason: 'HintArrowPainter CustomPaint must be present',
        );
        expect(
          hintPainterIndex,
          greaterThan(arrowPainterIndex),
          reason:
              'HintArrowPainter must be above ArrowPainter in the widget tree',
        );
      },
    );

    testWidgets(
      'no HintArrowPainter when hintArrow is null',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(controller: controller),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final hintPainterFinder = find.byWidgetPredicate(
          (final w) => w is CustomPaint && w.painter is HintArrowPainter,
        );
        expect(hintPainterFinder, findsNothing);
      },
    );
  });
}
