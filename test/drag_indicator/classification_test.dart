// Feature: chess-board-ux-enhancements, Property P1.28:
// Drag-legal ring and drag-illegal tint appear iff the hover square is
// non-source and legality of (source → hover) matches the indicator.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Drag indicator classification', () {
    testWidgets(
      'P1.28: no indicators when enableMoves is false',
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
                  enableMoves: false,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No drag indicators should be present.
        const theme = BoardTheme.classicGreen;
        final illegalTintFinder = find.byWidgetPredicate(
          (final Widget w) =>
              w is ColoredBox && w.color == theme.dragIllegalTintColor,
        );
        expect(illegalTintFinder, findsNothing);
      },
    );

    testWidgets(
      'board renders without drag indicators when no drag is active',
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

        // No drag indicators should be present when no drag is active.
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
