// Task 13.3 — property-based tests for ChessBoardController.
// Covers §2.1, §2.2, §2.13, §3.10.
//
// Property IDs (from design.md):
//   P1.1 — multi-listener fan-out
//   P1.5 — getter oracle parity
//   P2.5 — notify: false suppresses

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart' hide group, test, expect;

import 'generators.dart';

void main() {
  ft.group('ChessBoardController — property-based', () {
    // P1.1 — multi-listener fan-out (§2.1, §2.2).
    // Listener count drawn from [1, 10].
    Glados<int>(any.intInRange(1, 11)).test(
      'prop_multi_listener_fanout: all listeners fire exactly once',
      (final int n) {
        final c = ChessBoardController();
        final counters = List<int>.filled(n, 0);
        for (var i = 0; i < n; i++) {
          c.addListener(() => counters[i]++);
        }

        final accepted = c.makeMove(from: 'e2', to: 'e4');
        ft.expect(accepted, ft.isTrue, reason: 'e2-e4 is a legal opening move');

        for (var i = 0; i < n; i++) {
          ft.expect(
            counters[i],
            1,
            reason: 'listener #$i of $n must fire exactly once',
          );
        }
      },
    );

    // P1.5 — controller getters agree with the underlying chess game for any
    // reachable position (§2.13).
    Glados<String>(any.chessFen).test(
      'prop_controller_getters_match_game: every getter agrees with game',
      (final String fen) {
        final c = ChessBoardController();
        c.loadGameFromFEN(fen, notify: false);

        ft.expect(c.isInCheck, c.game.in_check);
        ft.expect(c.isCheckmate, c.game.in_checkmate);
        ft.expect(c.isStalemate, c.game.in_stalemate);
        ft.expect(c.isDraw, c.game.in_draw);
        ft.expect(c.isGameOver, c.game.game_over);
        ft.expect(c.moveCount, c.game.history.length);
        ft.expect(c.history.length, c.game.history.length);
        ft.expect(c.pgn, c.game.pgn());
        ft.expect(c.fen, c.game.fen);
        ft.expect(
          c.playerColor,
          c.game.turn == chess.Color.WHITE
              ? PlayerColor.white
              : PlayerColor.black,
        );
      },
    );

    // P2.5 — `notify: false` suppresses listener invocations (§3.10).
    // For any random reachable FEN (source of a random legal move), invoking
    // the first legal move with `notify: false` fires zero listener calls.
    Glados<String>(any.chessFen).test(
      'prop_notify_false_suppresses: zero notifications on any legal move',
      (final String fen) {
        final c = ChessBoardController();
        c.loadGameFromFEN(fen, notify: false);

        // Pick the first legal move available from the generated position.
        final legal = c.game.generate_moves();
        if (legal.isEmpty) {
          // Terminal position (mate/stalemate) — nothing to assert beyond the
          // controller accepting no-op undo with notify: false.
          var stray = 0;
          c.addListener(() => stray++);
          c.undo(notify: false);
          c.resetBoard(notify: false);
          c.loadGameFromFEN(fen, notify: false);
          ft.expect(stray, 0);
          return;
        }

        final chosen = legal.first;
        final from = chosen.fromAlgebraic;
        final to = chosen.toAlgebraic;
        // Promoting moves require a `promotion` argument — supply one so the
        // move is actually made and the notify: false path is exercised.
        final promotion = chosen.promotion?.name;

        var notifications = 0;
        c.addListener(() => notifications++);

        final accepted = c.makeMove(
          from: from,
          to: to,
          promotion: promotion,
          notify: false,
        );
        ft.expect(accepted, ft.isTrue,
            reason: 'move $from->$to came from generate_moves — must be legal');
        ft.expect(
          notifications,
          0,
          reason: 'notify: false must suppress listener invocations',
        );
      },
    );
  });
}
