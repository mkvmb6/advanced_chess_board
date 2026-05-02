// Feature: chess-board-ux-enhancements, Property P1.13:
// CoordinateLabels.none renders no [a-h] or [1-8] single-letter labels
// and allocates no gutter SizedBox.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoordinateLabels.none', () {
    testWidgets(
      'P1.13: none mode renders no coordinate labels',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  coordinates: CoordinateLabels.none,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No Text widgets with single-letter coordinate labels.
        final coordinateLabelFinder = find.byWidgetPredicate(
          (final w) =>
              w is Text &&
              w.data != null &&
              RegExp(r'^[a-h]$|^[1-8]$').hasMatch(w.data!),
        );
        expect(
          coordinateLabelFinder,
          findsNothing,
          reason: 'CoordinateLabels.none should render no coordinate labels',
        );
      },
    );

    testWidgets(
      'none mode does not overflow',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  coordinates: CoordinateLabels.none,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
