// Task 13.4 — widget tests for tap / drag interaction edge cases.
// Covers §2.17–§2.20. Validates P1.8, P1.9, P1.10.
//
// - §2.17/§2.18 (P1.8): no-op taps do not schedule a rebuild.
// - §2.19 (P1.9):       off-last-move squares do NOT emit a yellow overlay
//                        (i.e. no stray Container/ColoredBox with the
//                        last-move tint outside of the from/to squares).
// - §2.20 (P1.10):      when the selected square equals a last-move square,
//                        exactly ONE yellow overlay renders (selection takes
//                        priority, the last-move tint is suppressed).

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Yellow alpha used by the board for overlays.
// Selection overlay uses alpha 0x9B (155), last-move uses 0x80 (128), both
// over the same yellow (Colors.yellow -> 0xFFEB3B).
const Color _kSelectionYellow = Color(0x9BFFEB3B);
const Color _kLastMoveYellow = Color(0x80FFEB3B);

Widget _boardHarness(final ChessBoardController c, {final bool enable = true}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 400,
        child: AdvancedChessBoard(
          controller: c,
          enableMoves: enable,
        ),
      ),
    ),
  );
}

int _countOverlays(final WidgetTester tester, final Color color) {
  return find
      .byWidgetPredicate(
        (final w) => w is ColoredBox && w.color == color,
      )
      .evaluate()
      .length;
}

void main() {
  group('Tap & drag interactions', () {
    testWidgets('P1.8 §2.17: tap with enableMoves: false schedules no frame',
        (final tester) async {
      final c = ChessBoardController();
      await tester.pumpWidget(_boardHarness(c, enable: false));
      await tester.pumpAndSettle();

      expect(tester.binding.hasScheduledFrame, isFalse,
          reason: 'pre-tap: no frame pending');

      await tester.tapAt(const Offset(200, 200));

      expect(tester.binding.hasScheduledFrame, isFalse,
          reason: 'Tap with enableMoves: false must not schedule a rebuild — '
              '_handleTap must early-return before any setState call.');
    });

    testWidgets(
        'P1.8 §2.18: tap empty square with no selection schedules no frame',
        (final tester) async {
      final c = ChessBoardController();
      await tester.pumpWidget(_boardHarness(c));
      await tester.pumpAndSettle();

      expect(tester.binding.hasScheduledFrame, isFalse,
          reason: 'pre-tap: no frame pending');

      // Centre of a 400x400 board lands on one of d4/e4/d5/e5 — all empty
      // squares from the starting position.
      await tester.tapAt(const Offset(200, 200));

      expect(tester.binding.hasScheduledFrame, isFalse,
          reason: 'Tap on empty square with selectedSquare == null must not '
              'schedule a rebuild — _handleTap must early-return.');
    });

    testWidgets(
        'P1.9 §2.19: after e2-e4, exactly two last-move yellow overlays',
        (final tester) async {
      final c = ChessBoardController();
      await tester.pumpWidget(_boardHarness(c));
      await tester.pumpAndSettle();

      expect(_countOverlays(tester, _kLastMoveYellow), 0,
          reason: 'no last-move yellow at game start');

      c.makeMove(from: 'e2', to: 'e4');
      // Pump long enough for the move animation (150ms default) to complete.
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(
        _countOverlays(tester, _kLastMoveYellow),
        2,
        reason:
            'After e2-e4, exactly two yellow last-move overlays must render '
            '(one for e2, one for e4). Off-last-move squares must use '
            'SizedBox.shrink — not emit a stray ColoredBox / Container.',
      );
    });

    testWidgets(
        'P1.10 §2.20: selecting a last-move square draws exactly ONE yellow '
        'overlay (selection takes priority)', (final tester) async {
      final c = ChessBoardController();
      await tester.pumpWidget(_boardHarness(c));
      await tester.pumpAndSettle();

      // Play e2-e4 so e4 is a last-move square.
      c.makeMove(from: 'e2', to: 'e4');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Baseline: two last-move overlays, zero selection overlays.
      expect(_countOverlays(tester, _kLastMoveYellow), 2);
      expect(_countOverlays(tester, _kSelectionYellow), 0);

      // Now tap the e4 pawn to select it. e4 is both the selected square AND
      // a last-move square. The expected behaviour: selection overlay renders
      // on e4, last-move overlay is suppressed for e4; the e2 last-move
      // overlay still renders. Net: 1 selection yellow + 1 last-move yellow.
      final e4DraggableFinder = find.byWidgetPredicate(
        (final w) => w is Draggable<String> && w.data == 'e4',
      );
      expect(e4DraggableFinder, findsOneWidget);
      await tester.tap(e4DraggableFinder);
      await tester.pumpAndSettle();

      expect(
        _countOverlays(tester, _kSelectionYellow),
        1,
        reason: 'Selecting e4 renders one selection overlay.',
      );
      expect(
        _countOverlays(tester, _kLastMoveYellow),
        1,
        reason:
            'The e4 last-move overlay is suppressed when e4 is the selected '
            'square (avoid double alpha-blend). Only the e2 last-move tint '
            'remains.',
      );
    });
  });
}
