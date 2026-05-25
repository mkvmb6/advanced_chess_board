// Exploration test — bugfix.md §1.17, §1.18.
//
// PROPERTY: prop_no_rebuild_on_noop_tap (design.md P1.8).
// Validates: Requirements 1.17, 1.18
//
// EXPECTED TO FAIL ON UNFIXED CODE — failure confirms the bug condition.
//
// Bugs per `bugfix.md`:
//   §1.17 — enableMoves: false AND tap any square → `_handleTap` calls
//           setState even though it early-returned.
//   §1.18 — tap empty square with `selectedSquare == null` → `_handleTap`
//           calls setState even though nothing visible changes.
//
// NOTE on §1.17: inspecting the current unfixed `_handleTap`:
//
//     Future<void> _handleTap(String square) async {
//       if (!widget.enableMoves) { return; }      // <- already early-returns
//       if (selectedSquare == null || …) {
//         _setSelectedSquareAndFindLegalMoves(square);
//       } else if (selectedSquare == square) {
//         selectedSquare = null; legalMoves = {};
//       } else {
//         if (_isMoveValid(selectedSquare!, square)) {
//           await _makeMove(selectedSquare!, square);
//         }
//         selectedSquare = null; legalMoves = {};
//       }
//       setState(() {});                           // <- always setState
//     }
//
// The `enableMoves: false` early-return IS already present in the unfixed
// code, so §1.17 as literally written does not fire there. Scenario A below
// (enableMoves: false) therefore PASSES on unfixed code — we keep it as a
// preservation assertion documenting that the early-return is honoured.
//
// Scenario B (§1.18) IS the real bug condition: tapping an empty square
// with no selection calls `_setSelectedSquareAndFindLegalMoves` which
// silently sets `selectedSquare = <tappedEmptySquare>` and `legalMoves = {}`
// — no visible change — then still schedules a rebuild. Scenario B FAILS on
// unfixed code.
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   Scenario A (enableMoves: false): PASSES.
//     pre-tap  hasScheduledFrame == false
//     post-tap hasScheduledFrame == false   (early-return honoured)
//
//   Scenario B (empty-square tap, selectedSquare == null): FAILS.
//     pre-tap  hasScheduledFrame == false
//     post-tap hasScheduledFrame == true    <- bug: setState schedules a
//                                              rebuild even though the only
//                                              state change is an invisible
//                                              `selectedSquare` update.
//
//   Test assertion "hasScheduledFrame == false" in Scenario B fails with
//     Expected: false
//     Actual: <true>
// -----------------------------------------------------------------------------

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§1.17 / §1.18 redundant setState on no-op tap', () {
    testWidgets(
        'Scenario A (§1.17): enableMoves: false tap does not schedule a '
        'frame', (final tester) async {
      // Documented as PASSING on unfixed code — the early-return is already
      // in place. We include the test so regressions that remove the
      // early-return are caught.
      final controller = ChessBoardController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: AdvancedChessBoard(
                controller: controller,
                enableMoves: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.binding.hasScheduledFrame, isFalse,
          reason: 'pre-tap: no frame pending');

      await tester.tapAt(const Offset(200, 200));

      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'Tap with enableMoves: false must not schedule a rebuild. '
            '(Already honoured by unfixed code via early-return; the bug '
            'report §1.17 is imprecise about this but §2.17 preserves the '
            'behaviour.)',
      );
    });

    testWidgets(
        'Scenario B (§1.18): empty-square tap with no selection does not '
        'schedule a frame', (final tester) async {
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
      expect(tester.binding.hasScheduledFrame, isFalse,
          reason: 'pre-tap: no frame pending');

      // Tap the centre of the board — on a 400x400 board in starting
      // position that lands on d4/e4/d5/e5 (all empty mid-board squares).
      await tester.tapAt(const Offset(200, 200));

      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'Tap on an empty square with selectedSquare == null must not '
            'schedule a rebuild. Unfixed code calls setState at the end of '
            '_handleTap regardless, scheduling a useless rebuild frame.',
      );
    });
  });
}
