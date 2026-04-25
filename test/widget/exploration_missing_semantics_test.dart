// Exploration test — bugfix.md §1.27.
//
// PROPERTY: prop_square_has_semantics_label (design.md P1.16).
// Validates: Requirements 1.27
//
// EXPECTED TO FAIL ON UNFIXED CODE — failure confirms the bug condition.
//
// Bug: Neither `ChessSquare` nor `ChessPieceWidget` wraps itself in
// `Semantics`, so screen readers hear nothing useful when traversing the
// board. The fix wraps every square in a `Semantics(label: "<sq>, <piece>")`
// node.
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   tester.getSemantics(find.byType(ChessSquare).first) ->
//     SemanticsNode(rect: ..., label: "")
//
//   The node exists only because the default Semantics tree wraps every
//   RenderObject; it carries no label, no `button` trait, no descriptive
//   content. Regex `/^[a-h][1-8], (empty|(white|black) (pawn|...|king))$/`
//   has no match.
// -----------------------------------------------------------------------------

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/widgets/chess_square.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§1.27 semantics labels on ChessSquare', () {
    testWidgets('first ChessSquare has a descriptive Semantics label',
        (final tester) async {
      final handle = tester.ensureSemantics();
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

      final squareFinder = find.byType(ChessSquare).first;

      // Expect getSemantics to either return a node with a matching label, or
      // (on unfixed code) a node whose label is empty — we assert the former.
      SemanticsNode? node;
      try {
        node = tester.getSemantics(squareFinder);
      } catch (_) {
        node = null;
      }

      final pattern = RegExp(
        r'^[a-h][1-8], (empty|(white|black) (pawn|rook|knight|bishop|queen|king))$',
      );

      expect(
        node,
        isNotNull,
        reason: 'ChessSquare must expose a Semantics node.',
      );
      expect(
        node!.label,
        matches(pattern),
        reason:
            'ChessSquare Semantics label must match `<square>, <piece|empty>` '
            'e.g. "a1, white rook" or "e4, empty". Unfixed code emits an '
            'empty label because there is no Semantics wrapper.',
      );

      handle.dispose();
    });
  });
}
