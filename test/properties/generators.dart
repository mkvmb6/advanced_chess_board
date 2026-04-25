// Random generators for property-based tests. Uses `glados`.
//
// Exposes (per design.md §8 / tasks.md 13.3):
//   - `any.chessFen`         — seeded random FEN (0..40 random legal moves).
//   - `any.chessSquare`      — algebraic squares a1..h8.
//   - `any.chessArrow`       — random `(from, to, color)` arrows.
//   - `any.boardOrientation` — `PlayerColor.white | PlayerColor.black`.
//   - `any.squareSize`       — double in [24, 256].

import 'dart:math' as math;

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:glados/glados.dart';

/// Small palette used by `any.chessArrow`. Keeps counterexamples readable.
const List<Color> _arrowColorPalette = <Color>[
  Color(0x80FFC107), // amber, 50% alpha (package default)
  Color(0x80F44336), // red
  Color(0x802196F3), // blue
  Color(0x804CAF50), // green
  Color(0x809C27B0), // purple
];

const List<String> _files = <String>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
const List<int> _ranks = <int>[1, 2, 3, 4, 5, 6, 7, 8];

/// PBT generators for `advanced_chess_board` exposed on the `any` namespace.
extension ChessGenerators on Any {
  /// Random reachable FEN produced by playing 0..40 random legal moves from
  /// the standard starting position.
  ///
  /// Uses the PBT `Random` instance so counterexamples are reproducible.
  Generator<String> get chessFen => (final math.Random random, final int size) {
        final rng = math.Random(random.nextInt(1 << 31));
        final game = chess.Chess();
        final plies = rng.nextInt(41); // 0..40 inclusive
        for (var i = 0; i < plies; i++) {
          final moves = game.generate_moves();
          if (moves.isEmpty) break;
          game.make_move(moves[rng.nextInt(moves.length)]);
        }
        return Shrinkable<String>(
          game.fen,
          () => const <Shrinkable<String>>[],
        );
      };

  /// Algebraic squares `a1..h8`.
  Generator<String> get chessSquare => any.choose(<String>[
        for (final String file in _files)
          for (final int rank in _ranks) '$file$rank',
      ]);

  /// Random `ChessArrow` with `(from, to, color)` drawn from a small palette.
  Generator<ChessArrow> get chessArrow =>
      (final math.Random random, final int size) {
        final from = any.chessSquare(random, size);
        final to = any.chessSquare(random, size);
        final color = any.choose(_arrowColorPalette)(random, size);
        final arrow = ChessArrow(
          startSquare: from.value,
          endSquare: to.value,
          color: color.value,
        );
        return Shrinkable<ChessArrow>(
          arrow,
          () => const <Shrinkable<ChessArrow>>[],
        );
      };

  /// `PlayerColor.white | PlayerColor.black`.
  Generator<PlayerColor> get boardOrientation =>
      any.choose(PlayerColor.values);

  /// Alias for [boardOrientation] kept for back-compat with existing tests.
  Generator<PlayerColor> get playerColor => boardOrientation;

  /// Square size in logical pixels, clamped to the realistic range `[24, 256]`.
  Generator<double> get squareSize => any.doubleInRange(24, 256);
}
