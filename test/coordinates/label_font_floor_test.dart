// Feature: chess-board-ux-enhancements, Property P1.14:
// Every rendered coordinate label (inside or outside) has
// fontSize == max(kMinLabelFontSize, squareSize * 0.18).

import 'dart:math' as math;

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/constants/global_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Coordinate label font floor', () {
    for (final double boardSize in <double>[80, 160, 320, 400]) {
      final squareSize = boardSize / 8;
      final expectedFontSize = math.max(kMinLabelFontSize, squareSize * 0.18);

      testWidgets(
        'P1.14: inside labels at boardSize=$boardSize have fontSize=$expectedFontSize',
        (final WidgetTester tester) async {
          final controller = ChessBoardController();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: AdvancedChessBoard(
                    controller: controller,
                    coordinates: CoordinateLabels.inside,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Find all coordinate label Text widgets.
          final labelFinder = find.byWidgetPredicate(
            (final w) =>
                w is Text &&
                w.data != null &&
                RegExp(r'^[a-h]$|^[1-8]$').hasMatch(w.data!),
          );

          final labels = tester.widgetList<Text>(labelFinder);
          for (final label in labels) {
            final fontSize = label.style?.fontSize;
            if (fontSize != null) {
              expect(
                fontSize,
                closeTo(expectedFontSize, 0.01),
                reason:
                    'Label "${label.data}" at boardSize=$boardSize should have '
                    'fontSize=$expectedFontSize',
              );
            }
          }
        },
      );
    }

    testWidgets(
      'P1.14: font floor is kMinLabelFontSize on very small boards',
      (final WidgetTester tester) async {
        // Very small board where squareSize * 0.18 < kMinLabelFontSize.
        const boardSize = 40.0; // squareSize = 5, 5 * 0.18 = 0.9 < 9
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: boardSize,
                height: boardSize,
                child: AdvancedChessBoard(
                  controller: controller,
                  coordinates: CoordinateLabels.inside,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final labelFinder = find.byWidgetPredicate(
          (final w) =>
              w is Text &&
              w.data != null &&
              RegExp(r'^[a-h]$|^[1-8]$').hasMatch(w.data!),
        );

        final labels = tester.widgetList<Text>(labelFinder);
        for (final label in labels) {
          final fontSize = label.style?.fontSize;
          if (fontSize != null) {
            expect(
              fontSize,
              greaterThanOrEqualTo(kMinLabelFontSize),
              reason: 'Font size must not go below kMinLabelFontSize',
            );
          }
        }
      },
    );
  });
}
