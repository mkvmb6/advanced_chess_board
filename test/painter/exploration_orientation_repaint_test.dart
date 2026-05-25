// Exploration test — bugfix.md §1.5.
//
// PROPERTY: prop_arrow_painter_repaints_on_orientation_change (design.md P1.3).
// Validates: Requirements 1.5
//
// EXPECTED TO FAIL ON UNFIXED CODE — failure confirms the bug condition.
//
// Bug: `ArrowPainter.shouldRepaint` never consults `boardOrientation`.
// When the arrow list is unchanged but orientation flips, the painter falls
// through to `return true` only by accident of the inverted logic — and for
// the "arrows changed AND orientation changed" case it returns false, missing
// the orientation delta entirely. Either way, orientation is not a first-
// class part of the painter's identity.
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   arrowsA  = [ChessArrow(a2->a4)]
//   painterW = ArrowPainter(arrowsA, PlayerColor.white)
//   painterB = ArrowPainter(arrowsA, PlayerColor.black)
//
//   Scenario 1 (orientation only, arrows equal):
//     painterB.shouldRepaint(painterW) -> true
//     (PASSES because the inverted length branch returns false for equal
//      lengths, then the per-element branch returns false for equal arrows,
//      and the method falls through to `return true`. The "pass" is
//      accidental — orientation is NOT part of the equality check.)
//
//   Scenario 2 (orientation different AND arrows different):
//     painterB'.shouldRepaint(painterW) -> false    (expected: true)
//     FAILS because the inverted length branch short-circuits with `return
//     false` the moment the arrow lists differ in length — the non-existent
//     orientation check never runs.
//
// Scenario 1 is retained as a pinning test; Scenario 2 is the actual
// counterexample confirming the bug.
// -----------------------------------------------------------------------------

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/utils/arrow_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§1.5 arrow repaint on orientation change', () {
    test('flipping orientation alone triggers repaint', () {
      final arrowsA = <ChessArrow>[
        ChessArrow(startSquare: 'a2', endSquare: 'a4'),
      ];
      final oldPainter = ArrowPainter(arrowsA, PlayerColor.white);
      final newPainter = ArrowPainter(arrowsA, PlayerColor.black);

      expect(
        newPainter.shouldRepaint(oldPainter),
        isTrue,
        reason:
            'Orientation flipped white -> black; arrow coordinates depend on '
            'orientation so the canvas MUST repaint.',
      );
    });

    test('orientation-different AND arrows-different triggers repaint', () {
      final arrowsA = <ChessArrow>[
        ChessArrow(startSquare: 'a2', endSquare: 'a4'),
      ];
      final arrowsB = <ChessArrow>[
        ChessArrow(startSquare: 'a2', endSquare: 'a4'),
        ChessArrow(startSquare: 'h1', endSquare: 'h8'),
      ];
      final oldPainter = ArrowPainter(arrowsA, PlayerColor.white);
      final newPainter = ArrowPainter(arrowsB, PlayerColor.black);

      expect(
        newPainter.shouldRepaint(oldPainter),
        isTrue,
        reason: 'Both arrow list and orientation changed; canvas MUST repaint. '
            'Unfixed code returns false because the inverted length branch '
            'short-circuits before the non-existent orientation check.',
      );
    });
  });
}
