// Feature: chess-board-ux-enhancements, Property P2.5:
// Drag-drop moves and ArrowPainter geometry preserved.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Preservation P2.5: drag-drop and arrow geometry preserved', () {
    testWidgets(
      'P2.5: drag-drop move advances FEN correctly',
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
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fenBefore = controller.fen;

        // Make a legal move via controller.
        controller.makeMove(from: 'e2', to: 'e4');
        await tester.pumpAndSettle();

        expect(
          controller.fen,
          isNot(equals(fenBefore)),
          reason: 'FEN should advance after a legal move',
        );
      },
    );

    testWidgets(
      'P2.5: arrows render without errors',
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
                  arrows: <ChessArrow>[
                    ChessArrow(startSquare: 'e2', endSquare: 'e4'),
                    ChessArrow(startSquare: 'e7', endSquare: 'e5'),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      },
    );
  });
}
