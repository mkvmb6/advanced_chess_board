// Feature: chess-board-ux-enhancements, Property P1.32:
// enableMoves: false gates drag-legal ring AND drag-illegal tint off
// unconditionally.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Drag indicator disabled when enableMoves is false', () {
    testWidgets(
      'P1.32: no drag indicators when enableMoves is false',
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

        // Verify Draggable has maxSimultaneousDrags == 0.
        final draggables = tester.widgetList<Draggable<String>>(
          find.byType(Draggable<String>),
        );
        for (final draggable in draggables) {
          expect(
            draggable.maxSimultaneousDrags,
            equals(0),
            reason: 'enableMoves:false should set maxSimultaneousDrags to 0',
          );
        }

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
      'P1.32: enableMoves:true allows drags',
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
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify Draggable has maxSimultaneousDrags == null (unlimited).
        final draggables = tester.widgetList<Draggable<String>>(
          find.byType(Draggable<String>),
        );
        for (final draggable in draggables) {
          expect(
            draggable.maxSimultaneousDrags,
            isNull,
            reason: 'enableMoves:true should allow unlimited drags',
          );
        }
      },
    );
  });
}
