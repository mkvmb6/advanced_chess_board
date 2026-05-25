// Random generators for property-based tests. Uses `glados`.
//
// Exposes (per design.md §8 / tasks.md 13.3):
//   - `any.chessFen`         — seeded random FEN (0..40 random legal moves).
//   - `any.chessSquare`      — algebraic squares a1..h8.
//   - `any.chessArrow`       — random `(from, to, color)` arrows.
//   - `any.boardOrientation` — `PlayerColor.white | PlayerColor.black`.
//   - `any.squareSize`       — double in [24, 256].
//   - `any.boardTheme`       — random BoardTheme (11 random Colors).
//   - `any.pieceSet`         — PieceSet.chessDotCom or fromAssetMap.
//   - `any.coordinateLabels` — any CoordinateLabels value.
//   - `any.soundEvent`       — any SoundEvent value.
//   - `any.hintArrow`        — random HintArrow with optional duration.
//   - `any.legalMoveFromRandomPosition` — (chess.Chess, chess.Move) pair.

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

/// A static 12-entry map of AssetImages for PieceSet PBTs.
/// Kept constant per test run so equality comparisons work.
final Map<({PlayerColor color, chess.PieceType type}), ImageProvider>
    _staticPieceMap = () {
  final map = <({PlayerColor color, chess.PieceType type}), ImageProvider>{};
  for (final color in PlayerColor.values) {
    for (final type in const <chess.PieceType>[
      chess.PieceType.PAWN,
      chess.PieceType.KNIGHT,
      chess.PieceType.BISHOP,
      chess.PieceType.ROOK,
      chess.PieceType.QUEEN,
      chess.PieceType.KING,
    ]) {
      // Use AssetImage from the package - these are always valid.
      map[(color: color, type: type)] = const AssetImage(
        'assets/pieces/wp.png',
        package: 'advanced_chess_board',
      );
    }
  }
  return map;
}();

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
  Generator<PlayerColor> get boardOrientation => any.choose(PlayerColor.values);

  /// Alias for [boardOrientation] kept for back-compat with existing tests.
  Generator<PlayerColor> get playerColor => boardOrientation;

  /// Square size in logical pixels, clamped to the realistic range `[24, 256]`.
  Generator<double> get squareSize => any.doubleInRange(24, 256);

  /// Random [BoardTheme] constructed from 11 random [Color]s.
  ///
  /// The five presets are included in the generated pool with small
  /// probability so the "default" path is exercised alongside randomised
  /// themes.
  Generator<BoardTheme> get boardTheme =>
      (final math.Random random, final int size) {
        // 20% chance of returning a preset.
        if (random.nextInt(5) == 0) {
          final presets = <BoardTheme>[
            BoardTheme.classicGreen,
            BoardTheme.brown,
            BoardTheme.blue,
            BoardTheme.purple,
            BoardTheme.monochrome,
          ];
          final preset = presets[random.nextInt(presets.length)];
          return Shrinkable<BoardTheme>(
            preset,
            () => const <Shrinkable<BoardTheme>>[],
          );
        }
        Color randomColor() => Color(random.nextInt(0xFFFFFFFF) | 0xFF000000);
        final theme = BoardTheme(
          lightSquareColor: randomColor(),
          darkSquareColor: randomColor(),
          selectionColor: randomColor(),
          lastMoveHighlightColor: randomColor(),
          legalDestinationColor: randomColor(),
          coordinateLabelColor: random.nextBool() ? randomColor() : null,
          kingCheckmateColor: randomColor(),
          kingCheckColor: random.nextBool() ? randomColor() : null,
          hintArrowColor: randomColor(),
          dragLegalRingColor: randomColor(),
          dragIllegalTintColor: randomColor(),
        );
        return Shrinkable<BoardTheme>(
          theme,
          () => const <Shrinkable<BoardTheme>>[],
        );
      };

  /// Random [PieceSet]: either [PieceSet.chessDotCom] or a
  /// [PieceSet.fromAssetMap] built against a static 12-entry map of
  /// transparent [MemoryImage]s.
  Generator<PieceSet> get pieceSet =>
      (final math.Random random, final int size) {
        final set = random.nextBool()
            ? PieceSet.chessDotCom
            : PieceSet.fromAssetMap(_staticPieceMap);
        return Shrinkable<PieceSet>(
          set,
          () => const <Shrinkable<PieceSet>>[],
        );
      };

  /// Any [CoordinateLabels] value.
  Generator<CoordinateLabels> get coordinateLabels =>
      any.choose(CoordinateLabels.values);

  /// Any [SoundEvent] value.
  Generator<SoundEvent> get soundEvent => any.choose(SoundEvent.values);

  /// Random [HintArrow] with random squares and optional duration.
  Generator<HintArrow> get hintArrow =>
      (final math.Random random, final int size) {
        final from = any.chessSquare(random, size);
        final to = any.chessSquare(random, size);
        final hasDuration = random.nextBool();
        final duration = hasDuration
            ? Duration(milliseconds: 100 + random.nextInt(4901))
            : null;
        final arrow = HintArrow(
          startSquare: from.value,
          endSquare: to.value,
          duration: duration,
        );
        return Shrinkable<HintArrow>(
          arrow,
          () => const <Shrinkable<HintArrow>>[],
        );
      };

  /// A random reachable [chess.Chess] position paired with a random legal
  /// move from that position.
  ///
  /// Returns a `(chess.Chess, chess.Move)` record. Used by the sound
  /// classifier PBT (Task 7.7).
  Generator<(chess.Chess, chess.Move)> get legalMoveFromRandomPosition =>
      (final math.Random random, final int size) {
        final rng = math.Random(random.nextInt(1 << 31));
        final game = chess.Chess();
        final plies = rng.nextInt(41);
        for (var i = 0; i < plies; i++) {
          final moves = game.generate_moves();
          if (moves.isEmpty) break;
          game.make_move(moves[rng.nextInt(moves.length)]);
        }
        final moves = game.generate_moves();
        if (moves.isEmpty) {
          // Terminal position — return the game with no move; tests should skip.
          // We need to return something, so we restart from the initial position.
          final freshGame = chess.Chess();
          final freshMoves = freshGame.generate_moves();
          final move = freshMoves[rng.nextInt(freshMoves.length)];
          return Shrinkable<(chess.Chess, chess.Move)>(
            (freshGame, move),
            () => const <Shrinkable<(chess.Chess, chess.Move)>>[],
          );
        }
        final move = moves[rng.nextInt(moves.length)];
        return Shrinkable<(chess.Chess, chess.Move)>(
          (game, move),
          () => const <Shrinkable<(chess.Chess, chess.Move)>>[],
        );
      };
}
