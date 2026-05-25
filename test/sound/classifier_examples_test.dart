// Feature: chess-board-ux-enhancements, Property P1.16 (fallback):
// Hand-written example cases that pin the six branches individually.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/sound/move_classifier.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Sound classifier examples', () {
    test('quiet pawn push => SoundEvent.move', () {
      final game = chess.Chess();
      // e2-e4 from starting position.
      final moves = game.generate_moves();
      final e2e4 = moves.firstWhere(
        (final m) => m.fromAlgebraic == 'e2' && m.toAlgebraic == 'e4',
      );
      game.make_move(e2e4);
      final event = classifySoundEvent(
        verboseMove: e2e4,
        isGameOverAfter: game.game_over,
        isInCheckAfter: game.in_check,
      );
      expect(event, equals(SoundEvent.move));
    });

    test('capture => SoundEvent.capture', () {
      // White pawn captures black pawn: e4xd5.
      final game = chess.Chess.fromFEN(
        'rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 2',
      );
      final moves = game.generate_moves();
      final capture = moves.firstWhere(
        (final m) => m.fromAlgebraic == 'e4' && m.toAlgebraic == 'd5',
      );
      game.make_move(capture);
      final event = classifySoundEvent(
        verboseMove: capture,
        isGameOverAfter: game.game_over,
        isInCheckAfter: game.in_check,
      );
      expect(event, equals(SoundEvent.capture));
    });

    test('kingside castle => SoundEvent.castle', () {
      // White castles kingside.
      final game = chess.Chess.fromFEN(
        'r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1',
      );
      final moves = game.generate_moves();
      final castle = moves.firstWhere(
        (final m) => m.fromAlgebraic == 'e1' && m.toAlgebraic == 'g1',
      );
      game.make_move(castle);
      final event = classifySoundEvent(
        verboseMove: castle,
        isGameOverAfter: game.game_over,
        isInCheckAfter: game.in_check,
      );
      expect(event, equals(SoundEvent.castle));
    });

    test('promotion => SoundEvent.promote', () {
      // White pawn promotes to queen.
      final game = chess.Chess.fromFEN(
        '8/P7/8/8/8/8/8/4k2K w - - 0 1',
      );
      final moves = game.generate_moves();
      final promote = moves.firstWhere(
        (final m) =>
            m.fromAlgebraic == 'a7' &&
            m.toAlgebraic == 'a8' &&
            m.promotion == chess.PieceType.QUEEN,
      );
      game.make_move(promote);
      final event = classifySoundEvent(
        verboseMove: promote,
        isGameOverAfter: game.game_over,
        isInCheckAfter: game.in_check,
      );
      expect(event, equals(SoundEvent.promote));
    });

    test("Fool's mate => SoundEvent.gameEnd", () {
      // Fool's mate: 1.f3 e5 2.g4 Qh4#
      final game = chess.Chess();
      final moves1 = game.generate_moves();
      game.make_move(
        moves1.firstWhere(
          (final m) => m.fromAlgebraic == 'f2' && m.toAlgebraic == 'f3',
        ),
      );
      final moves2 = game.generate_moves();
      game.make_move(
        moves2.firstWhere(
          (final m) => m.fromAlgebraic == 'e7' && m.toAlgebraic == 'e5',
        ),
      );
      final moves3 = game.generate_moves();
      game.make_move(
        moves3.firstWhere(
          (final m) => m.fromAlgebraic == 'g2' && m.toAlgebraic == 'g4',
        ),
      );
      final moves4 = game.generate_moves();
      final mateMove = moves4.firstWhere(
        (final m) => m.fromAlgebraic == 'd8' && m.toAlgebraic == 'h4',
      );
      game.make_move(mateMove);

      expect(game.in_checkmate, isTrue);
      final event = classifySoundEvent(
        verboseMove: mateMove,
        isGameOverAfter: game.game_over,
        isInCheckAfter: game.in_check,
      );
      expect(event, equals(SoundEvent.gameEnd));
    });
  });
}
