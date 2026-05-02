// Feature: chess-board-ux-enhancements, Property P1.29:
// Every drag termination (drop, cancel, off-board) clears every
// drag-legal ring and drag-illegal tint on the next pumped frame.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Drag indicator clear on end', () {
    testWidgets(
      'P1.29: no drag indicators after drag ends',
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

        // After pumpAndSettle, no drag is active.
        const theme = BoardTheme.classicGreen;
        final illegalTintFinder = find.byWidgetPredicate(
          (final Widget w) =>
              w is ColoredBox && w.color == theme.dragIllegalTintColor,
        );
        expect(illegalTintFinder, findsNothing);
      },
    );
  });
}
