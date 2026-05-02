// Feature: chess-board-ux-enhancements, Property P2.4:
// Last-move highlight, selection overlay, tap-to-deselect, and the
// HighlightOverlay dot/ring style are preserved under 3.1.0.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/widgets/highlight_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Preservation P2.4: highlights preserved under 3.1.0', () {
    testWidgets(
      'P2.4: last-move highlight uses _effectiveTheme.lastMoveHighlightColor',
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
                  boardTheme: BoardTheme.classicGreen,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Make a move.
        controller.makeMove(from: 'e2', to: 'e4');
        await tester.pumpAndSettle();

        // The last-move highlight color should be present.
        final highlightFinder = find.byWidgetPredicate(
          (final w) =>
              w is ColoredBox &&
              w.color == BoardTheme.classicGreen.lastMoveHighlightColor,
        );
        expect(
          highlightFinder,
          findsWidgets,
          reason: 'Last-move highlight should be rendered',
        );
      },
    );

    testWidgets(
      'P2.4: HighlightOverlay rendered on legal destinations',
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

        // Tap e2 to select.
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        const e2 = Offset(
          4 * squareSize + squareSize / 2,
          6 * squareSize + squareSize / 2,
        );
        await tester.tapAt(e2);
        await tester.pumpAndSettle();

        // HighlightOverlay should be rendered on legal destinations.
        expect(
          find.byType(HighlightOverlay),
          findsWidgets,
          reason: 'HighlightOverlay should be rendered on legal destinations',
        );
      },
    );
  });
}
