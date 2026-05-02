// Feature: chess-board-ux-enhancements, Property P2.1:
// 3.0.0 chess-rule correctness (moves, promotion, illegal rejection)
// is preserved under any 3.1.0 parameter combination.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart';

import 'generators.dart';

void main() {
  ft.group('Preservation P2.1: chess rules preserved under 3.1.0 params', () {
    Glados<String>(any.chessFen).test(
      'prop_chess_rules_preserved: FEN advances correctly with 3.1.0 params',
      (final String fen) async {
        final controllerA = ChessBoardController();
        final controllerB = ChessBoardController();
        controllerA.loadGameFromFEN(fen, notify: false);
        controllerB.loadGameFromFEN(fen, notify: false);

        final moves = controllerA.game.generate_moves();
        if (moves.isEmpty) return; // terminal position

        final move = moves.first;
        final promotion = move.promotion?.name;

        // Make the same move on both controllers.
        controllerA.makeMove(
          from: move.fromAlgebraic,
          to: move.toAlgebraic,
          promotion: promotion,
          notify: false,
        );
        controllerB.makeMove(
          from: move.fromAlgebraic,
          to: move.toAlgebraic,
          promotion: promotion,
          notify: false,
        );

        ft.expect(
          controllerA.fen,
          ft.equals(controllerB.fen),
          reason: 'FEN must be identical after same move on both controllers',
        );
        ft.expect(
          controllerA.playerColor,
          ft.equals(controllerB.playerColor),
        );
      },
    );

    ft.testWidgets(
      'P2.1: illegal moves rejected under 3.1.0 params',
      (final ft.WidgetTester tester) async {
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
                  coordinates: CoordinateLabels.outside,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final fenBefore = controller.fen;

        // Attempt an illegal move.
        final accepted = controller.makeMove(
          from: 'e2',
          to: 'e5', // illegal — pawn can't jump 3 squares
          notify: false,
        );

        ft.expect(accepted, ft.isFalse);
        ft.expect(controller.fen, ft.equals(fenBefore));
      },
    );

    ft.testWidgets(
      'P2.1: legal moves accepted under 3.1.0 params',
      (final ft.WidgetTester tester) async {
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  boardTheme: BoardTheme.blue,
                  pieceSet: PieceSet.chessDotCom,
                  coordinates: CoordinateLabels.inside,
                  soundPack: const SilentSoundPack(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final accepted = controller.makeMove(from: 'e2', to: 'e4');
        ft.expect(accepted, ft.isTrue);
        ft.expect(
          controller.fen,
          ft.isNot(ft.equals(chess.Chess().fen)),
        );
      },
    );
  });
}
