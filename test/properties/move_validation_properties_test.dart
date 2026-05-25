// Task 13.3 — property-based tests for move-destination validation.
// Covers §2.6.
//
// Property IDs (from design.md):
//   P1.4 — verbose-moves destination oracle.
//
// For any random reachable position and any `(from, to)` pair, the controller's
// move acceptance must equal
// `game.generate_moves({'square': from}).any((m) => m.toAlgebraic == to)`
// — modulo the fact that promoting moves require a `promotion` argument. The
// test handles promotion by supplying `'q'` when the verbose move set contains
// a promoting destination.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart' hide group, test, expect;

import 'generators.dart';

void main() {
  ft.group('Move validation — property-based', () {
    Glados3<String, String, String>(
      any.chessFen,
      any.chessSquare,
      any.chessSquare,
    ).test(
      'prop_verbose_moves_is_destination_oracle: '
      'makeMove accepts iff verbose-moves contain the target',
      (final String fen, final String from, final String to) {
        final c = ChessBoardController();
        c.loadGameFromFEN(fen, notify: false);

        final verbose = c.game
            .generate_moves(<String, String>{'square': from})
            .cast<chess.Move>()
            .where((final chess.Move m) => m.toAlgebraic == to)
            .toList();

        // Oracle: does any verbose legal move from `from` land on `to`?
        final oracle = verbose.isNotEmpty;

        // If any of the verbose matches is a promotion, `makeMove` without a
        // promotion argument will reject — so supply 'q' to mirror oracle
        // semantics.
        final needsPromotion =
            verbose.any((final chess.Move m) => m.promotion != null);

        final fenBefore = c.fen;
        final accepted = c.makeMove(
          from: from,
          to: to,
          promotion: needsPromotion ? 'q' : null,
          notify: false,
        );

        if (oracle) {
          ft.expect(
            accepted,
            ft.isTrue,
            reason: 'makeMove($from->$to'
                '${needsPromotion ? ' =q' : ''}) must be accepted '
                'when a verbose move has toAlgebraic == $to '
                '(fen=$fen)',
          );
        } else {
          ft.expect(
            accepted,
            ft.isFalse,
            reason:
                'makeMove($from->$to) must be rejected when no verbose move '
                'has toAlgebraic == $to (fen=$fen)',
          );
          ft.expect(
            c.fen,
            fenBefore,
            reason: 'rejected moves must leave FEN unchanged',
          );
        }
      },
    );
  });
}
