// Feature: chess-board-ux-enhancements, Property P2.9:
// The 8×8 playing grid is built as a Column of 8 Rows of 8 SizedBox
// children — no GridView, no Scrollable — in every coordinates mode.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Preservation P2.9: Column-of-Rows grid preserved', () {
    for (final mode in CoordinateLabels.values) {
      testWidgets(
        'P2.9: no GridView or Scrollable in $mode mode',
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
                    coordinates: mode,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // No GridView.
          expect(
            find.byType(GridView),
            findsNothing,
            reason: 'No GridView should be used in $mode mode',
          );

          // No Scrollable.
          expect(
            find.byType(Scrollable),
            findsNothing,
            reason: 'No Scrollable should be used in $mode mode',
          );

          // At least 8 Row widgets (for the playing grid).
          expect(
            find.byType(Row).evaluate().length,
            greaterThanOrEqualTo(8),
            reason: 'At least 8 Row widgets for the playing grid',
          );
        },
      );
    }
  });
}
