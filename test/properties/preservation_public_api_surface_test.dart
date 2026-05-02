// Feature: chess-board-ux-enhancements, Property P2.11:
// The 3.0.0 public API surface (parameter names, types, defaults;
// controller getter set) is preserved in 3.1.0.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Preservation P2.11: 3.0.0 public API surface preserved', () {
    test('AdvancedChessBoard 3.0.0 parameters still exist', () {
      final controller = ChessBoardController();
      // This test verifies that all 3.0.0 parameters still compile.
      final board = AdvancedChessBoard(
        controller: controller,
        lightSquareColor: const Color(0xFFEBECD0),
        darkSquareColor: const Color(0xFF739552),
        initialFEN: null,
        boardOrientation: PlayerColor.white,
        enableMoves: true,
        highlightLastMove: true,
        arrows: const <ChessArrow>[],
        kingBackgroundColorOnCheckmate: null,
        moveAnimationDuration: const Duration(milliseconds: 150),
      );
      expect(board, isA<AdvancedChessBoard>());
    });

    test('ChessBoardController 3.0.0 getters still exist', () {
      final c = ChessBoardController();
      // Verify all 3.0.0 getters compile and return expected types.
      expect(c.fen, isA<String>());
      expect(c.playerColor, isA<PlayerColor>());
      expect(c.isInCheck, isA<bool>());
      expect(c.isCheckmate, isA<bool>());
      expect(c.isStalemate, isA<bool>());
      expect(c.isDraw, isA<bool>());
      expect(c.isGameOver, isA<bool>());
      expect(c.history, isA<List<dynamic>>());
      expect(c.pgn, isA<String>());
      expect(c.moveCount, isA<int>());
      expect(c.game, isNotNull);
    });

    test('PlayerColor values still exist', () {
      expect(PlayerColor.white, isA<PlayerColor>());
      expect(PlayerColor.black, isA<PlayerColor>());
    });

    test('ChessArrow still constructible', () {
      final arrow = ChessArrow(startSquare: 'e2', endSquare: 'e4');
      expect(arrow, isA<ChessArrow>());
    });
  });
}
