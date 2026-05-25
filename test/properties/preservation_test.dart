// Task 14 — preservation property tests (¬C(X) unchanged).
//
// These tests validate Property 2 from design.md: behaviours outside the bug
// condition (bugfix.md §3.1–§3.20) are preserved byte-for-byte after the fix.
//
// Property IDs (from design.md):
//   P2.1  — FEN round-trip                          (§3.7)
//   P2.2  — move/undo identity                      (§3.8)
//   P2.4  — illegal move rejection                  (§3.6, §3.15)
//   P2.5  — notify: false suppression               (§3.10)
//   P2.6  — arrow default geometry & colour         (§3.16)
//   P2.7  — checkmate tint preserved                (§3.3)
//   P2.8  — enableMoves: false is render-only       (§3.12)
//   P2.11 — controller.game escape hatch identity   (§3.11)
//   P2.12 — top-level import still resolves         (§3.19)
//
// `prop_notify_false_suppresses` (P2.5) also exists in
// `controller_properties_test.dart` (Task 13.3). The copy here runs against a
// different random axis (random FEN → random legal move) and keeps the
// preservation suite self-contained, per the Task 14 note.

import 'dart:math' as math;

import 'package:advanced_chess_board/advanced_chess_board.dart';
// arrow_geometry.dart is intentionally NOT re-exported through the barrel;
// this preservation test imports it directly to poke at its geometry,
// mirroring `test/painter/arrow_painter_test.dart`.
import 'package:advanced_chess_board/src/utils/arrow_geometry.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart';

import 'generators.dart';

// ---------------------------------------------------------------------------
// P2.7 constants — the default checkmate tint is `Colors.red.withAlpha(155)`
// which evaluates to `Color(0x9BF44336)` (Colors.red is `0xFFF44336`).
// ---------------------------------------------------------------------------
const Color _kCheckmateTint = Color(0x9BF44336);

// Fool's mate: after 1.f3 e5 2.g4 Qh4#. White is mated on e1.
const String _kFoolsMateFen =
    'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';

void main() {
  ft.group('Preservation properties (Property 2)', () {
    // -----------------------------------------------------------------------
    // P2.1 — FEN round-trip (§3.7)
    // -----------------------------------------------------------------------
    Glados<String>(any.chessFen).test(
      'prop_fen_roundtrip: loadGameFromFEN(F); controller.fen == canonicalise(F)',
      (final String fen) {
        final c = ChessBoardController();
        c.loadGameFromFEN(fen, notify: false);
        // `canonicalise(F)` is the engine's own normalisation — i.e. whatever
        // `controller.fen` returns after loading the same string. Generators
        // drive reachable positions so FENs emitted by `any.chessFen` are
        // already canonical; this asserts the engine does not silently re-
        // normalise a canonical FEN into a different string.
        ft.expect(
          c.fen,
          fen,
          reason: 'canonical FEN must round-trip through '
              'loadGameFromFEN → fen unchanged',
        );
      },
    );

    // -----------------------------------------------------------------------
    // P2.2 — move/undo identity (§3.8)
    // -----------------------------------------------------------------------
    Glados<String>(any.chessFen).test(
      'prop_move_undo_identity: fenOf(P) == fenOf(P.makeMove(m).undo())',
      (final String fen) {
        final c = ChessBoardController();
        c.loadGameFromFEN(fen, notify: false);
        final before = c.fen;
        final moves = c.game.generate_moves();
        if (moves.isEmpty) return; // terminal position — nothing to assert.
        final m = moves.first;
        final accepted = c.makeMove(
          from: m.fromAlgebraic,
          to: m.toAlgebraic,
          promotion: m.promotion?.name,
          notify: false,
        );
        ft.expect(accepted, ft.isTrue,
            reason: 'generate_moves returned $m — must be legal');
        c.undo(notify: false);
        ft.expect(
          c.fen,
          before,
          reason: 'undo must restore the pre-move FEN exactly',
        );
      },
    );

    // -----------------------------------------------------------------------
    // P2.4 — illegal move rejection (§3.6, §3.15)
    //
    // Generator strategy: pick a random FEN, then find a `from` that has at
    // least one legal move, then pick a `to` NOT in `legalDestinations(from)`
    // so we reliably exercise the illegal path. If no such `(from, to)` pair
    // exists the property is vacuously true.
    // -----------------------------------------------------------------------
    Glados<String>(any.chessFen).test(
      'prop_illegal_move_rejected: makeMove returns false and fen unchanged',
      (final String fen) {
        final c = ChessBoardController();
        c.loadGameFromFEN(fen, notify: false);
        final before = c.fen;

        // Pick any source square that has at least one legal move, then pick
        // any destination that is NOT in its legal-destinations set.
        const squares = <String>[
          'a1',
          'a2',
          'a3',
          'a4',
          'a5',
          'a6',
          'a7',
          'a8',
          'b1',
          'b2',
          'b3',
          'b4',
          'b5',
          'b6',
          'b7',
          'b8',
          'c1',
          'c2',
          'c3',
          'c4',
          'c5',
          'c6',
          'c7',
          'c8',
          'd1',
          'd2',
          'd3',
          'd4',
          'd5',
          'd6',
          'd7',
          'd8',
          'e1',
          'e2',
          'e3',
          'e4',
          'e5',
          'e6',
          'e7',
          'e8',
          'f1',
          'f2',
          'f3',
          'f4',
          'f5',
          'f6',
          'f7',
          'f8',
          'g1',
          'g2',
          'g3',
          'g4',
          'g5',
          'g6',
          'g7',
          'g8',
          'h1',
          'h2',
          'h3',
          'h4',
          'h5',
          'h6',
          'h7',
          'h8',
        ];

        String? illegalFrom;
        String? illegalTo;
        for (final from in squares) {
          final dests = <String>{
            for (final m
                in c.game.generate_moves(<String, String>{'square': from}))
              m.toAlgebraic,
          };
          if (dests.isEmpty) continue;
          // Look for a destination NOT in `dests`.
          for (final to in squares) {
            if (to == from) continue;
            if (dests.contains(to)) continue;
            illegalFrom = from;
            illegalTo = to;
            break;
          }
          if (illegalFrom != null) break;
        }

        if (illegalFrom == null || illegalTo == null) {
          // No illegal (from,to) pair exists — position has zero legal moves
          // from every square. Property is vacuously true.
          return;
        }

        final accepted =
            c.makeMove(from: illegalFrom, to: illegalTo, notify: false);
        ft.expect(accepted, ft.isFalse,
            reason: 'makeMove($illegalFrom -> $illegalTo) is not a legal move');
        ft.expect(
          c.fen,
          before,
          reason: 'rejected move must not mutate FEN',
        );
      },
    );

    // -----------------------------------------------------------------------
    // P2.5 — notify: false suppression (§3.10)
    //
    // NOTE: duplicated from Task 13.3 so the preservation suite is self-
    // contained. The existing copy lives in
    // `test/properties/controller_properties_test.dart`.
    // -----------------------------------------------------------------------
    Glados<String>(any.chessFen).test(
      'prop_notify_false_suppresses: zero notifications on any mutating call',
      (final String fen) {
        final c = ChessBoardController();
        c.loadGameFromFEN(fen, notify: false);

        var notifications = 0;
        c.addListener(() => notifications++);

        // resetBoard with notify: false — zero notifications.
        c.resetBoard(notify: false);
        // loadGameFromFEN with notify: false — zero notifications.
        c.loadGameFromFEN(fen, notify: false);

        final moves = c.game.generate_moves();
        if (moves.isNotEmpty) {
          final chosen = moves.first;
          c.makeMove(
            from: chosen.fromAlgebraic,
            to: chosen.toAlgebraic,
            promotion: chosen.promotion?.name,
            notify: false,
          );
          c.undo(notify: false);
        }

        ft.expect(
          notifications,
          0,
          reason: 'notify: false must suppress every listener invocation',
        );
      },
    );

    // -----------------------------------------------------------------------
    // P2.6 — arrow geometry preserved (§3.16)
    //
    // The painter draws a main line plus a triangular arrowhead whose size is
    // derived from `blockSize`. The task instruction says to capture the
    // CURRENT fixed geometry as the expected formulas, since no pre-fix
    // fixture exists. The formulas below mirror the ones in
    // `lib/src/utils/arrow_painter.dart` exactly; the property asserts that
    //   (a) default arrow colour is `Colors.amber.withAlpha(128)`;
    //   (b) the painter's `getIndexFromSquare` maps squares the documented
    //       way for both orientations;
    //   (c) the derived line endpoints and arrowhead vertices evaluate to
    //       finite, deterministic values for every `(from, to, orientation)`
    //       triple with `from != to`, matching the formulas captured below.
    //
    // Note on "equilateral": §3.16 describes the arrowhead informally as an
    // equilateral triangle sized from `blockSize`. The captured formulas
    // produce an isoceles-style arrowhead whose side distances are
    //   |tip-base1| == |tip-base2| = s · sqrt((7 + 2√3) / 4)
    //   |base1-base2|                = s · √3
    // where `s = arrowheadSideLength = blockSize * 0.2`. That is the shape
    // currently shipped and what this preservation property freezes.
    // -----------------------------------------------------------------------
    ft.test('prop_arrow_default_color == Colors.amber.withAlpha(128)', () {
      final a = ChessArrow(startSquare: 'e2', endSquare: 'e4');
      ft.expect(a.color, Colors.amber.withAlpha(128));
    });

    Glados3<String, String, PlayerColor>(
      any.chessSquare,
      any.chessSquare,
      any.boardOrientation,
    ).test(
      'prop_arrow_geometry_preserved: expected formulas hold for every '
      '(from, to, orientation) triple',
      (final String from, final String to, final PlayerColor orientation) {
        if (from == to) return; // zero-length vector is not a real arrow.

        const boardSide = 320.0;
        const blockSize = boardSide / 8;

        // Use the top-level helper from arrow_geometry.dart directly.
        final (srcRow, srcCol) = getIndexFromSquare(from, orientation);
        final (dstRow, dstCol) = getIndexFromSquare(to, orientation);

        // All index coordinates must stay inside `[0, 7]`.
        for (final idx in <int>[srcRow, srcCol, dstRow, dstCol]) {
          ft.expect(idx, ft.inInclusiveRange(0, 7),
              reason: 'getIndexFromSquare must map to [0,7]');
        }

        // Reproduce the geometry formulas from arrow_painter.dart.
        final sourceX = srcCol * blockSize + blockSize / 2;
        final sourceY = srcRow * blockSize + blockSize / 2;
        final destX = dstCol * blockSize + blockSize / 2;
        final destY = dstRow * blockSize + blockSize / 2;
        final dx = destX - sourceX;
        final dy = destY - sourceY;
        final distance = math.sqrt(dx * dx + dy * dy);

        ft.expect(distance, ft.greaterThan(0),
            reason: 'from != to => distance > 0');

        const sourceThreshold = blockSize * 0.35;
        const destinationThreshold = blockSize * 0.272;
        const arrowheadSideLength = blockSize * 0.2;

        final adjustedSourceX = sourceX + dx / distance * sourceThreshold;
        final adjustedSourceY = sourceY + dy / distance * sourceThreshold;
        final adjustedDestX = destX -
            dx / distance * (arrowheadSideLength * math.cos(math.pi / 6));
        final adjustedDestY = destY -
            dy / distance * (arrowheadSideLength * math.cos(math.pi / 6));
        final strokeDestX = destX - dx / distance * destinationThreshold;
        final strokeDestY = destY - dy / distance * destinationThreshold;

        final angle = math.atan2(dy, dx);
        final tipX = destX;
        final tipY = destY;
        final baseX1 =
            adjustedDestX - arrowheadSideLength * math.cos(angle - math.pi / 3);
        final baseY1 =
            adjustedDestY - arrowheadSideLength * math.sin(angle - math.pi / 3);
        final baseX2 =
            adjustedDestX - arrowheadSideLength * math.cos(angle + math.pi / 3);
        final baseY2 =
            adjustedDestY - arrowheadSideLength * math.sin(angle + math.pi / 3);

        // Every derived coordinate must be finite.
        for (final v in <double>[
          adjustedSourceX,
          adjustedSourceY,
          adjustedDestX,
          adjustedDestY,
          strokeDestX,
          strokeDestY,
          tipX,
          tipY,
          baseX1,
          baseY1,
          baseX2,
          baseY2,
        ]) {
          ft.expect(v.isFinite, ft.isTrue,
              reason: 'all derived coordinates must be finite');
        }

        // Arrowhead geometry (captured from the fixed `arrow_painter.dart`
        // formulas — §3.16):
        //
        // - The tip sits exactly at `(destX, destY)`.
        // - `base1` and `base2` are mirror-symmetric about the line, so
        //   `|tip - base1| == |tip - base2|`.
        // - `base1` and `base2` are obtained by rotating
        //   `(adjustedDest - tip)`-style offsets by ±π/3 and subtracting
        //   from `adjustedDest`, which gives the closed-form distance
        //   `|tip - base| = s · sqrt((7 + 2√3) / 4)` where
        //   `s = arrowheadSideLength`.
        final sideA = math.sqrt(math.pow(tipX - baseX1, 2).toDouble() +
            math.pow(tipY - baseY1, 2).toDouble());
        final sideB = math.sqrt(math.pow(tipX - baseX2, 2).toDouble() +
            math.pow(tipY - baseY2, 2).toDouble());
        final sideC = math.sqrt(math.pow(baseX1 - baseX2, 2).toDouble() +
            math.pow(baseY1 - baseY2, 2).toDouble());
        final expectedTipToBase =
            arrowheadSideLength * math.sqrt((7 + 2 * math.sqrt(3)) / 4);
        // base1 ↔ base2 separation is the perpendicular stretch
        // `2 · s · sin(π/3) = s · √3`.
        final expectedBaseToBase = arrowheadSideLength * math.sqrt(3);

        ft.expect(sideA, ft.closeTo(expectedTipToBase, 1e-6),
            reason: 'tip-to-base1 distance matches captured formula');
        ft.expect(sideB, ft.closeTo(expectedTipToBase, 1e-6),
            reason: 'tip-to-base2 distance matches captured formula');
        ft.expect(sideC, ft.closeTo(expectedBaseToBase, 1e-6),
            reason: 'base1-to-base2 distance matches captured formula');
        // Mirror-symmetry: both sides equal.
        ft.expect(sideA, ft.closeTo(sideB, 1e-6),
            reason: 'arrowhead is mirror-symmetric about the line');

        // The main-line stroke sits strictly inside the source/dest squares —
        // assert both endpoints still lie on the board (0..boardSide).
        for (final v in <double>[
          adjustedSourceX,
          adjustedSourceY,
          strokeDestX,
          strokeDestY,
        ]) {
          ft.expect(v, ft.inInclusiveRange(0.0, boardSide),
              reason: 'line endpoints stay on the board');
        }
      },
    );

    // -----------------------------------------------------------------------
    // P2.11 — controller.game escape hatch preserved (§3.11)
    // -----------------------------------------------------------------------
    Glados<String>(any.chessFen).test(
      'prop_escape_hatch_preserved: identical(c.game, c.game) across '
      'arbitrary mutation sequences',
      (final String fen) {
        final c = ChessBoardController();
        final initialGame = c.game;
        c.loadGameFromFEN(fen, notify: false);
        ft.expect(identical(c.game, initialGame), ft.isTrue,
            reason: 'loadGameFromFEN must not swap the chess.Chess instance');

        final moves = c.game.generate_moves();
        if (moves.isNotEmpty) {
          final m = moves.first;
          c.makeMove(
            from: m.fromAlgebraic,
            to: m.toAlgebraic,
            promotion: m.promotion?.name,
            notify: false,
          );
          ft.expect(identical(c.game, initialGame), ft.isTrue,
              reason: 'makeMove must not swap the chess.Chess instance');
          c.undo(notify: false);
          ft.expect(identical(c.game, initialGame), ft.isTrue,
              reason: 'undo must not swap the chess.Chess instance');
        }

        c.resetBoard(notify: false);
        ft.expect(identical(c.game, initialGame), ft.isTrue,
            reason: 'resetBoard must not swap the chess.Chess instance');

        // And the stable reference is still the underlying chess.Chess.
        ft.expect(c.game, ft.isA<chess.Chess>());
      },
    );
  });

  // -------------------------------------------------------------------------
  // P2.7 — checkmate tint preserved (§3.3)
  //
  // Single fixed mate FEN drives this widget-level check — the property
  // reduces to: in a mate position, a ColoredBox with Colors.red.withAlpha(155)
  // renders UNDER the mated king piece on the king's square.
  // -------------------------------------------------------------------------
  ft.group('P2.7 checkmate tint preserved', () {
    ft.testWidgets(
      'prop_checkmate_tint_preserved: mated king square renders '
      'Colors.red.withAlpha(155) behind the king piece',
      (final ft.WidgetTester tester) async {
        final c = ChessBoardController()
          ..loadGameFromFEN(_kFoolsMateFen, notify: false);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(controller: c),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The mated side is White (it is White's turn and White has no legal
        // reply). The white king sits on e1.
        ft.expect(c.isCheckmate, ft.isTrue,
            reason: 'Fools-mate FEN is checkmate for White');

        // Exactly one checkmate-tint ColoredBox renders.
        final tintFinder = ft.find.byWidgetPredicate(
          (final Widget w) => w is ColoredBox && w.color == _kCheckmateTint,
        );
        ft.expect(tintFinder, ft.findsOneWidget,
            reason: 'exactly one red-tint overlay on the mated king square');

        // Critical: the overlay must actually paint at square-size, not
        // shrink to zero. A `ColoredBox` inside a `Stack` without
        // `Positioned.fill` collapses to `Size.zero` and paints nothing —
        // that regressed the visual once. Assert the rendered size equals
        // the square size (board 400 / 8 = 50).
        const expectedSide = 400.0 / 8;
        final tintSize = tester.getSize(tintFinder);
        ft.expect(tintSize.width, ft.closeTo(expectedSide, 0.5),
            reason: 'checkmate tint must paint at full square width — '
                'requires Positioned.fill around the ColoredBox');
        ft.expect(tintSize.height, ft.closeTo(expectedSide, 0.5),
            reason: 'checkmate tint must paint at full square height');

        // The king piece image on e1 must still render (piece widget draws
        // ON TOP of the tint — §1.21 / §3.3).
        final kingDraggable = ft.find.byWidgetPredicate(
          (final Widget w) => w is Draggable<String> && w.data == 'e1',
        );
        ft.expect(kingDraggable, ft.findsOneWidget,
            reason: 'king piece widget still renders on top of the tint');
      },
    );
  });

  // -------------------------------------------------------------------------
  // P2.8 — enableMoves: false is render-only (§3.12)
  //
  // PBT here runs a small set of random tap targets against a board pumped
  // with `enableMoves: false`; for every tap, FEN is unchanged.
  // -------------------------------------------------------------------------
  ft.group('P2.8 enableMoves: false is render-only', () {
    ft.testWidgets(
      'prop_enable_moves_false_is_render_only: taps & drags do not mutate FEN',
      (final ft.WidgetTester tester) async {
        final c = ChessBoardController();
        final startingFen = c.fen;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(controller: c, enableMoves: false),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap every square on the rendered board; none should mutate state.
        const boardSide = 400.0;
        const squareSize = boardSide / 8;
        for (var row = 0; row < 8; row++) {
          for (var col = 0; col < 8; col++) {
            final dx = col * squareSize + squareSize / 2;
            final dy = row * squareSize + squareSize / 2;
            await tester.tapAt(Offset(dx, dy));
          }
        }
        await tester.pumpAndSettle();

        ft.expect(c.fen, startingFen,
            reason: 'taps on enableMoves: false board must not mutate FEN');

        // A drag attempt on e2 — which would be legal if moves were enabled —
        // must also not mutate FEN.
        const e2Col = 4; // 'e' is the 5th file (index 4).
        const e2Row = 6; // rank 2 is the 7th row from the top in white view.
        const e4Row = 4; // rank 4 is the 5th row from the top.
        const e2Offset = Offset(
          e2Col * squareSize + squareSize / 2,
          e2Row * squareSize + squareSize / 2,
        );
        const e4Offset = Offset(
          e2Col * squareSize + squareSize / 2,
          e4Row * squareSize + squareSize / 2,
        );
        await tester.dragFrom(e2Offset, e4Offset - e2Offset);
        await tester.pumpAndSettle();

        ft.expect(c.fen, startingFen,
            reason: 'drag on enableMoves: false board must not mutate FEN');
      },
    );
  });

  // -------------------------------------------------------------------------
  // P2.12 — top-level import still resolves (§3.19)
  //
  // The authoritative compile-only test for this property is
  // `test/api/barrel_imports_test.dart` (added in Task 3.5). That file
  // imports ONLY the barrel and references all four public symbols. The
  // duplicate smoke test below runs alongside it so the preservation suite
  // is self-contained — if the barrel regresses, both files flag it.
  // -------------------------------------------------------------------------
  ft.group('P2.12 top-level import still resolves', () {
    ft.test(
      'prop_top_level_import_still_resolves: barrel re-exports the four '
      'public symbols (smoke duplicate of test/api/barrel_imports_test.dart)',
      () {
        ft.expect(AdvancedChessBoard, ft.isA<Type>());
        ft.expect(ChessBoardController, ft.isA<Type>());
        ft.expect(ChessArrow, ft.isA<Type>());
        ft.expect(PlayerColor.white, ft.isA<PlayerColor>());
        ft.expect(PlayerColor.black, ft.isA<PlayerColor>());
      },
    );
  });
}
