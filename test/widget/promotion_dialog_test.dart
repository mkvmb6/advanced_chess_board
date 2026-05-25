// Task 13.4 — widget tests for the dynamic promotion dialog size.
// Covers §2.24. Validates P1.13.
//
// For each `squareSize ∈ {28, 64, 96, 128}` we pump a board with a width
// `squareSize * 8`, trigger a pawn promotion via the UI tap path, and assert
// that the promotion dialog pieces render at the same `squareSize` (± 0.5).

import 'package:advanced_chess_board/advanced_chess_board.dart';
// ignore: implementation_imports
import 'package:advanced_chess_board/src/widgets/chess_square.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Promotion dialog', () {
    for (final double squareSize in <double>[28, 64, 96, 128]) {
      testWidgets('P1.13 §2.24: dialog pieces sized to squareSize=$squareSize',
          (final tester) async {
        final c = ChessBoardController();
        final boardSize = squareSize * 8;

        // Give the test surface enough room for the board AND the AlertDialog
        // overlay (which centres itself on the Navigator).
        tester.view.physicalSize = Size(boardSize * 3, boardSize * 3);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: AdvancedChessBoard(controller: c),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Promotion position: white pawn on e7, black king tucked on h8 so
        // e8 is empty and the pawn can promote to e8.
        c.loadGameFromFEN('7k/4P3/8/8/8/8/8/4K3 w - - 0 1');
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // Tap the e7 pawn to select it (opens legal-destination highlights).
        final pawnFinder = find.byWidgetPredicate(
          (final w) => w is Draggable<String> && w.data == 'e7',
        );
        expect(pawnFinder, findsOneWidget,
            reason: 'e7 pawn Draggable must exist before promotion');
        await tester.tap(pawnFinder, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Tap e8 to commit the move. Since e8 is empty, _handleTap('e8')
        // reaches _makeMove('e7','e8') which shows the promotion dialog.
        final e8SquareFinder = find.byWidgetPredicate(
          (final w) => w is ChessSquare && w.square == 'e8',
        );
        expect(e8SquareFinder, findsOneWidget);
        await tester.tapAt(tester.getCenter(e8SquareFinder));
        // Let the dialog route build + settle.
        await tester.pumpAndSettle();

        // The AlertDialog should now be shown.
        final dialogFinder = find.byType(AlertDialog);
        expect(
          dialogFinder,
          findsOneWidget,
          reason: 'Promotion dialog must open when a pawn reaches the 8th rank '
              'via a tap sequence.',
        );

        // Each ChessPieceWidget inside the dialog wraps its image in a
        // SizedBox(width: squareSize, height: squareSize). Fetch those
        // SizedBox widgets scoped to the dialog.
        final sizedBoxesInDialog = find.descendant(
          of: dialogFinder,
          matching: find.byWidgetPredicate(
            (final w) =>
                w is SizedBox &&
                w.width != null &&
                (w.width! - squareSize).abs() < 0.5 &&
                w.height != null &&
                (w.height! - squareSize).abs() < 0.5,
          ),
        );

        expect(
          sizedBoxesInDialog,
          findsWidgets,
          reason: 'Promotion dialog must contain SizedBox widgets sized to '
              'squareSize=$squareSize (±0.5). Unfixed code hard-coded 60.',
        );

        // Close the dialog by tapping the first candidate (queen) so
        // subsequent tests don't leak pending timers.
        final firstPieceTap = find.descendant(
          of: dialogFinder,
          matching: find.byType(GestureDetector),
        );
        if (firstPieceTap.evaluate().isNotEmpty) {
          await tester.tap(firstPieceTap.first, warnIfMissed: false);
          await tester.pumpAndSettle();
        }
      });
    }
  });
}
