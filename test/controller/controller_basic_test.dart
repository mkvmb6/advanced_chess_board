// Task 13.2 — unit tests for the ChessBoardController public contract.
// Covers §2.1, §2.2, §2.3, §2.13, §2.14, §3.6–§3.11, §3.20.
// Validates: P1.5, P2.3, P2.4, P2.5.
// Requirements: 2.29.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// The canonical starting-position FEN exposed by `chess.DEFAULT_POSITION`.
const String _startingFen =
    'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

void main() {
  group('ChessBoardController — basic contract', () {
    test('starting FEN equals chess.DEFAULT_POSITION', () {
      final c = ChessBoardController();
      expect(c.fen, _startingFen);
      expect(c.fen, chess.Chess.DEFAULT_POSITION);
      expect(c.playerColor, PlayerColor.white);
      expect(c.isInCheck, isFalse);
      expect(c.isCheckmate, isFalse);
      expect(c.isStalemate, isFalse);
      expect(c.isDraw, isFalse);
      expect(c.isGameOver, isFalse);
      expect(c.moveCount, 0);
      expect(c.history, isEmpty);
    });

    test('makeMove(e2, e4) returns true and advances FEN', () {
      final c = ChessBoardController();
      final fenBefore = c.fen;
      expect(c.makeMove(from: 'e2', to: 'e4'), isTrue);
      expect(c.fen, isNot(fenBefore));
      expect(c.fen, contains(' b '), reason: 'black to move after e2-e4');
      expect(c.playerColor, PlayerColor.black);
      expect(c.moveCount, 1);
      expect(c.history, hasLength(1));
    });

    test('makeMove(e2, e5) returns false and does not mutate FEN', () {
      final c = ChessBoardController();
      final fenBefore = c.fen;
      expect(c.makeMove(from: 'e2', to: 'e5'), isFalse);
      expect(c.fen, fenBefore);
      expect(c.moveCount, 0);
      expect(c.history, isEmpty);
    });

    test('undo reverses the last move', () {
      final c = ChessBoardController();
      final fenBefore = c.fen;
      c.makeMove(from: 'e2', to: 'e4');
      c.undo();
      expect(c.fen, fenBefore);
      expect(c.moveCount, 0);
    });

    test('undo on empty history is a no-op', () {
      final c = ChessBoardController();
      final fenBefore = c.fen;
      expect(c.undo, returnsNormally);
      expect(c.fen, fenBefore);
      expect(c.moveCount, 0);
      expect(c.history, isEmpty);
      // Repeat — still a no-op.
      c
        ..undo()
        ..undo();
      expect(c.fen, fenBefore);
      expect(c.moveCount, 0);
    });

    test('resetBoard restores the starting position and is idempotent', () {
      final c = ChessBoardController()
        ..makeMove(from: 'e2', to: 'e4')
        ..makeMove(from: 'e7', to: 'e5');
      c.resetBoard();
      final fenAfterFirstReset = c.fen;
      expect(fenAfterFirstReset, _startingFen);
      expect(c.moveCount, 0);

      // Idempotence: calling resetBoard again from the reset state yields
      // the same state.
      c
        ..resetBoard()
        ..resetBoard();
      expect(c.fen, fenAfterFirstReset);
      expect(c.moveCount, 0);
      expect(c.history, isEmpty);
      expect(c.playerColor, PlayerColor.white);
    });

    test('loadGameFromFEN(valid) succeeds', () {
      final c = ChessBoardController();
      const fen = 'r3k3/8/8/8/8/8/8/R3K3 w - - 0 1';
      c.loadGameFromFEN(fen);
      expect(c.fen, fen);
    });

    test(
      'loadGameFromFEN(malformed) is safely handled — state unchanged, no throw',
      () {
        // Observed contract for chess: ^0.8.1 — `_game.load(...)` with a
        // malformed FEN prints a validation message to stdout and returns
        // without mutating the underlying position. It does NOT throw.
        //
        // Encode that observed behaviour here so any future change (e.g. the
        // engine starting to throw) is caught as a breaking contract shift.
        final c = ChessBoardController();
        final fenBefore = c.fen;

        expect(
          () => c.loadGameFromFEN('not-a-valid-fen'),
          returnsNormally,
          reason: 'Malformed FEN must be handled without throwing.',
        );
        expect(c.fen, fenBefore,
            reason: 'Malformed FEN must not mutate state.');

        expect(() => c.loadGameFromFEN(''), returnsNormally);
        expect(c.fen, fenBefore);

        expect(
          () => c.loadGameFromFEN('foo bar baz qux quux corge'),
          returnsNormally,
        );
        expect(c.fen, fenBefore);
      },
    );

    test('notify: false suppresses listener calls', () {
      final c = ChessBoardController();
      var notifications = 0;
      c.addListener(() => notifications++);

      c.makeMove(from: 'e2', to: 'e4', notify: false);
      expect(notifications, 0);

      c.undo(notify: false);
      expect(notifications, 0);

      c.resetBoard(notify: false);
      expect(notifications, 0);

      c.loadGameFromFEN(
        'r3k3/8/8/8/8/8/8/R3K3 w - - 0 1',
        notify: false,
      );
      expect(notifications, 0);
    });

    test('notify: true (default) fires listeners on every mutation', () {
      final c = ChessBoardController();
      var notifications = 0;
      c.addListener(() => notifications++);

      // Default notify flag is true.
      c.makeMove(from: 'e2', to: 'e4');
      expect(notifications, 1);

      c.undo();
      expect(notifications, 2);

      c.resetBoard();
      expect(notifications, 3);

      c.loadGameFromFEN('r3k3/8/8/8/8/8/8/R3K3 w - - 0 1');
      expect(notifications, 4);

      // Explicit notify: true behaves identically to the default.
      c.makeMove(from: 'a1', to: 'a2', notify: true);
      expect(notifications, 5);
    });

    test('makeMove with notify: true but illegal move does NOT notify', () {
      // An illegal move is rejected, so there's nothing to broadcast even if
      // `notify: true` is set.
      final c = ChessBoardController();
      var notifications = 0;
      c.addListener(() => notifications++);

      expect(c.makeMove(from: 'e2', to: 'e5'), isFalse);
      expect(notifications, 0);
    });

    test('isCheckmate is true in Fool\'s Mate (getter, not method)', () {
      final c = ChessBoardController()
        ..makeMove(from: 'f2', to: 'f3')
        ..makeMove(from: 'e7', to: 'e5')
        ..makeMove(from: 'g2', to: 'g4')
        ..makeMove(from: 'd8', to: 'h4');
      expect(c.isCheckmate, isTrue);
      expect(c.isGameOver, isTrue);
    });

    test('game getter returns the underlying chess.Chess instance', () {
      final c = ChessBoardController();
      expect(identical(c.game, c.game), isTrue);
      expect(c.game, isA<chess.Chess>());
    });

    test('history returns an unmodifiable list', () {
      final c = ChessBoardController()..makeMove(from: 'e2', to: 'e4');
      final h = c.history;
      expect(h, hasLength(1));
      expect(() => h.add(h.first), throwsUnsupportedError);
    });
  });

  group('ChessBoardController — dispose ordering contract', () {
    // Lifted from Task 1's exploration_dispose_ordering_test (per Task 13.2
    // option "keep it in controller/"). After the Task 4 fix, super.dispose()
    // runs LAST and addListener is no longer shadowed, so the inherited
    // ChangeNotifier post-dispose assertion reports disposal cleanly.
    test('dispose is idempotent and post-dispose addListener throws', () {
      final controller = ChessBoardController()..addListener(() {});

      expect(controller.dispose, returnsNormally);

      FlutterError? caught;
      try {
        controller.addListener(() {});
      } on FlutterError catch (e) {
        caught = e;
      }
      expect(
        caught,
        isNotNull,
        reason: 'Post-dispose addListener must raise a FlutterError '
            '("used after disposed") — confirms super.dispose() ran last and '
            'addListener is no longer shadowed.',
      );
      expect(caught!.toString(), contains('disposed'));
    });
  });
}
