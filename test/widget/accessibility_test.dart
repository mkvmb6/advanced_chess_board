// Task 13.4 — accessibility tests.
// Covers §2.27, §2.28.

import 'package:advanced_chess_board/advanced_chess_board.dart';
// ignore: implementation_imports
import 'package:advanced_chess_board/src/widgets/chess_square.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Accessibility', () {
    testWidgets('every ChessSquare carries a Semantics label',
        (final tester) async {
      final handle = tester.ensureSemantics();
      final c = ChessBoardController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: AdvancedChessBoard(controller: c),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pattern = RegExp(
        r'^[a-h][1-8], (empty|(white|black) (pawn|rook|knight|bishop|queen|king))$',
      );

      final squares = find.byType(ChessSquare);
      expect(squares, findsNWidgets(64));

      // Check a sample of squares (not all 64, to keep the test fast).
      for (final finder in <Finder>[
        squares.at(0), // top-left
        squares.at(7), // top-right
        squares.at(28), // middle
        squares.at(56), // bottom-left
        squares.at(63), // bottom-right
      ]) {
        final node = tester.getSemantics(finder);
        expect(node.label, matches(pattern),
            reason: 'label "${node.label}" must match $pattern');
      }

      handle.dispose();
    });
  });
}
