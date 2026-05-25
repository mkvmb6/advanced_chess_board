// Feature: chess-board-ux-enhancements, Property P1.16:
// For any reachable position and any legal move, classifySoundEvent
// returns the highest-priority event per
// gameEnd > promote > castle > check > capture > move.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/sound/move_classifier.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart';

import '../properties/generators.dart';

/// Oracle: independent implementation of the priority order.
SoundEvent _oracle({
  required final chess.Move verboseMove,
  required final bool isGameOverAfter,
  required final bool isInCheckAfter,
}) {
  final flags = verboseMove.flags;
  if (isGameOverAfter) return SoundEvent.gameEnd;
  if ((flags & chess.Chess.BITS_PROMOTION) != 0) return SoundEvent.promote;
  if ((flags & chess.Chess.BITS_KSIDE_CASTLE) != 0 ||
      (flags & chess.Chess.BITS_QSIDE_CASTLE) != 0) {
    return SoundEvent.castle;
  }
  if (isInCheckAfter) return SoundEvent.check;
  if ((flags & chess.Chess.BITS_CAPTURE) != 0 ||
      (flags & chess.Chess.BITS_EP_CAPTURE) != 0) {
    return SoundEvent.capture;
  }
  return SoundEvent.move;
}

void main() {
  ft.group('Sound classifier priority', () {
    Glados<(chess.Chess, chess.Move)>(any.legalMoveFromRandomPosition).test(
      'prop_classifier_matches_oracle_for_any_legal_move',
      (final (chess.Chess, chess.Move) pair) {
        final (game, move) = pair;
        final moves = game.generate_moves();
        if (moves.isEmpty) return; // terminal position — skip

        // Make the move on a clone.
        final clone = chess.Chess.fromFEN(game.fen);
        clone.make_move(move);

        final isGameOver = clone.game_over;
        final isInCheck = clone.in_check;

        final classified = classifySoundEvent(
          verboseMove: move,
          isGameOverAfter: isGameOver,
          isInCheckAfter: isInCheck,
        );
        final expected = _oracle(
          verboseMove: move,
          isGameOverAfter: isGameOver,
          isInCheckAfter: isInCheck,
        );

        ft.expect(
          classified,
          ft.equals(expected),
          reason:
              'classifySoundEvent must match oracle for move ${move.fromAlgebraic}->${move.toAlgebraic}',
        );
      },
    );
  });
}
