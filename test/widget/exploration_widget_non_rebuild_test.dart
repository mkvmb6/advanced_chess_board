// Exploration test — bugfix.md §1.8.
//
// PROPERTY: prop_widget_rebuilds_on_controller_mutation (design.md P1.6).
// Validates: Requirements 1.8
//
// EXPECTED TO FAIL ON UNFIXED CODE — failure confirms the bug condition.
//
// Bug: `_AdvancedChessBoardState.initState` binds `game = widget.controller.game`
// but never subscribes via `addListener`. Consumers must register their own
// `setState` listener externally or the widget appears frozen.
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   1. Pump `AdvancedChessBoard(controller: c)` (no external addListener).
//   2. FEN at frame 0: rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1
//      => `find.byType(Draggable<String>)` with data "e2" is present.
//   3. c.makeMove(from: 'e2', to: 'e4') -> true; c.game.fen advances.
//   4. tester.pumpAndSettle();
//   5. Draggable<String> with data "e2" is STILL present; no Draggable
//      with data "e4" exists.
//
//   => the widget tree never rebuilt. Pawn image still on e2.
// -----------------------------------------------------------------------------

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§1.8 widget auto-rebuild on controller mutation', () {
    testWidgets('board reflects makeMove without external addListener',
        (final tester) async {
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

      // Find the Draggable for the e2 pawn before the move.
      final e2BeforeFinder = find.byWidgetPredicate(
        (final w) => w is Draggable<String> && w.data == 'e2',
      );
      expect(e2BeforeFinder, findsOneWidget,
          reason: 'pawn draggable for e2 exists before the move');

      // Mutate the controller — no external setState.
      final accepted = controller.makeMove(from: 'e2', to: 'e4');
      expect(accepted, isTrue);

      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // After the move, the pawn's draggable should be on e4, not e2.
      final e2AfterFinder = find.byWidgetPredicate(
        (final w) => w is Draggable<String> && w.data == 'e2',
      );
      final e4AfterFinder = find.byWidgetPredicate(
        (final w) => w is Draggable<String> && w.data == 'e4',
      );

      expect(
        e2AfterFinder,
        findsNothing,
        reason: 'After makeMove(e2->e4) the Draggable<String> with data "e2" '
            'must be gone. Unfixed code keeps it because the widget never '
            'rebuilt.',
      );
      expect(
        e4AfterFinder,
        findsOneWidget,
        reason: 'After makeMove(e2->e4) a new Draggable<String> with data "e4" '
            'must exist. Unfixed code has none because the widget never '
            'rebuilt.',
      );
    });
  });
}
