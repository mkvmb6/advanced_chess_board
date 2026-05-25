// Task 13.4 — widget tests for board layout structure.
// Covers §2.22, §2.27.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Board layout', () {
    testWidgets('no GridView in the board subtree', (final tester) async {
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

      expect(
        find.descendant(
          of: find.byType(AdvancedChessBoard),
          matching: find.byType(GridView),
        ),
        findsNothing,
      );
    });

    testWidgets('board subtree has 8 Rows (one per rank)',
        (final tester) async {
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

      // The board itself emits 8 Rows nested under its Column.
      final rows = find.descendant(
        of: find.byType(AdvancedChessBoard),
        matching: find.byType(Row),
      );
      expect(rows, findsNWidgets(8));
    });
  });
}
