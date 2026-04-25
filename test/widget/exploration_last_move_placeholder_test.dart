// Exploration test — bugfix.md §1.19.
//
// PROPERTY: prop_no_empty_container_placeholders (design.md P1.9).
// Validates: Requirements 1.19
//
// EXPECTED TO FAIL ON UNFIXED CODE — failure confirms the bug condition.
//
// Bug: `_buildLastMoveHighlight` returns a bare `Container()` for every square
// that is NOT part of the last move. That's 62 empty Containers per frame
// after a move has been played — dead layout participants.
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   After makeMove(e2, e4):
//
//   - yellow highlight containers (color == yellow.withAlpha(128)):
//       expected: 2 (e2 from-square, e4 to-square)
//       observed: 2  (the two genuine yellow tints)
//
//   - empty `Container()` placeholders inside the board subtree
//     (matched by `w is Container && w.color == null && w.decoration == null
//      && w.child == null`):
//       expected: 0
//       observed: 62  (one per off-last-move square — the buggy fall-through
//                      returns `Container()` instead of `SizedBox.shrink()`).
// -----------------------------------------------------------------------------

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§1.19 empty Container placeholders from _buildLastMoveHighlight', () {
    testWidgets('no empty Container() placeholders after a move',
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
      await tester.pumpAndSettle();

      controller.makeMove(from: 'e2', to: 'e4');
      await tester.pumpAndSettle();

      // Find all Container widgets that are "empty" (no color, no decoration,
      // no child, no padding, no constraints). These are the placeholders
      // emitted by the buggy `_buildLastMoveHighlight` fall-through.
      final emptyContainerFinder = find.byWidgetPredicate((final w) {
        if (w is! Container) return false;
        return w.color == null &&
            w.decoration == null &&
            w.child == null &&
            w.padding == null &&
            w.constraints == null &&
            w.alignment == null &&
            w.margin == null &&
            w.transform == null &&
            w.foregroundDecoration == null;
      });

      expect(
        emptyContainerFinder,
        findsNothing,
        reason:
            'Off-last-move squares should use SizedBox.shrink() or omit the '
            'overlay entirely. Unfixed code emits an empty Container() per '
            'off-last-move square.',
      );
    });
  });
}
