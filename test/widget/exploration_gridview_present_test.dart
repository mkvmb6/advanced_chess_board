// Exploration test — bugfix.md §1.22.
//
// PROPERTY: prop_no_scrollable_in_board_tree (design.md P1.11).
// Validates: Requirements 1.22
//
// EXPECTED TO FAIL ON UNFIXED CODE — failure confirms the bug condition.
//
// Bug: `_buildChessBoard` uses `GridView.builder(...)` with a
// `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8)` for a known-
// fixed 8x8 grid. This introduces a Scrollable viewport and slower layout
// than a `Column` of `Row`s.
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   After pumping an AdvancedChessBoard:
//     find.byType(GridView).evaluate().length
//       expected: 0
//       observed: 1
//
//     find.byType(Scrollable).evaluate().length
//       expected: 0 (or at most the Material/ScrollConfiguration chrome)
//       observed: >= 1 (from the GridView viewport)
// -----------------------------------------------------------------------------

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§1.22 no GridView in board subtree', () {
    testWidgets('board subtree contains no GridView', (final tester) async {
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

      // Scope the search to the AdvancedChessBoard subtree.
      final gridViewFinder = find.descendant(
        of: find.byType(AdvancedChessBoard),
        matching: find.byType(GridView),
      );

      expect(
        gridViewFinder,
        findsNothing,
        reason: 'The 8x8 board layout must not use GridView. Unfixed code uses '
            'GridView.builder which introduces a Scrollable viewport.',
      );
    });
  });
}
