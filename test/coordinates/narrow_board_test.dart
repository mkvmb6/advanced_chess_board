// Feature: chess-board-ux-enhancements, Property P1.15:
// Outside mode does not overflow for boxWidth in [16, 144];
// label fontSize >= kMinLabelFontSize.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/constants/global_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Narrow board outside mode no overflow', () {
    for (final double width in <double>[16, 32, 64, 80, 100, 120, 144]) {
      testWidgets(
        'P1.15: outside mode at width=$width does not overflow',
        (final WidgetTester tester) async {
          final controller = ChessBoardController();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: width,
                  height: width,
                  child: AdvancedChessBoard(
                    controller: controller,
                    coordinates: CoordinateLabels.outside,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // No overflow errors.
          expect(
            tester.takeException(),
            isNull,
            reason: 'No overflow at width=$width',
          );

          // All coordinate labels should have fontSize >= kMinLabelFontSize.
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
                reason: 'Label "${label.data}" at width=$width should have '
                    'fontSize >= kMinLabelFontSize',
              );
            }
          }
        },
      );
    }
  });
}
