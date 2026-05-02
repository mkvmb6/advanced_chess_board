// Feature: chess-board-ux-enhancements, Property P2.7:
// Tap/programmatic moves still animate via MoveAnimationLayer under any
// 3.1.0 parameter combination; drag-drop moves still skip animation;
// Duration.zero disables the animation.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/widgets/move_animation_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Preservation P2.7: move animation preserved', () {
    testWidgets(
      'P2.7: MoveAnimationLayer appears during tap move',
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
                  boardTheme: BoardTheme.brown,
                  moveAnimationDuration: const Duration(milliseconds: 150),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap e2 then e4.
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        const e2 = Offset(
          4 * squareSize + squareSize / 2,
          6 * squareSize + squareSize / 2,
        );
        const e4 = Offset(
          4 * squareSize + squareSize / 2,
          4 * squareSize + squareSize / 2,
        );

        await tester.tapAt(e2);
        await tester.pumpAndSettle();
        await tester.tapAt(e4);
        await tester.pump(); // Don't settle — check during animation.

        // MoveAnimationLayer should be present during animation.
        expect(
          find.byType(MoveAnimationLayer),
          findsOneWidget,
          reason: 'MoveAnimationLayer should be present during animation',
        );

        await tester.pumpAndSettle();

        // After animation completes, MoveAnimationLayer should be gone.
        expect(
          find.byType(MoveAnimationLayer),
          findsNothing,
          reason: 'MoveAnimationLayer should be gone after animation',
        );
      },
    );

    testWidgets(
      'P2.7: Duration.zero disables animation',
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
                  moveAnimationDuration: Duration.zero,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Make a move.
        controller.makeMove(from: 'e2', to: 'e4');
        await tester.pump();

        // No MoveAnimationLayer should appear.
        expect(
          find.byType(MoveAnimationLayer),
          findsNothing,
          reason: 'Duration.zero should disable animation',
        );
      },
    );
  });
}
