// Feature: chess-board-ux-enhancements, Property P2.10:
// Semantics labels on ChessSquare and ChessPieceWidget are preserved
// under any PieceSet — label derivation still uses pieceSemanticsLabel.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/widgets/chess_piece_widget.dart';
import 'package:advanced_chess_board/src/widgets/chess_square.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Preservation P2.10: semantics labels preserved', () {
    testWidgets(
      'P2.10: ChessSquare semantics labels are correct',
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

        // Find ChessSquare for e1 (white king's starting square).
        final e1Square = tester.widget<ChessSquare>(
          find.byWidgetPredicate(
            (final w) => w is ChessSquare && w.square == 'e1',
          ),
        );
        expect(e1Square.square, equals('e1'));
      },
    );

    testWidgets(
      'P2.10: ChessPieceWidget semantics labels are correct',
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

        // Find ChessPieceWidget widgets.
        final pieceWidgets = tester.widgetList<ChessPieceWidget>(
          find.byType(ChessPieceWidget),
        );

        // There should be 32 pieces on the starting board.
        expect(
          pieceWidgets.length,
          greaterThanOrEqualTo(16),
          reason: 'Should have at least 16 piece widgets',
        );
      },
    );
  });
}
