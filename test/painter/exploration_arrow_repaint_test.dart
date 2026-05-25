// Exploration test — bugfix.md §1.4.
//
// PROPERTY: prop_arrow_painter_repaints_on_arrow_list_change (design.md P1.3).
// Validates: Requirements 1.4
//
// EXPECTED TO FAIL ON UNFIXED CODE — failure confirms the bug condition.
//
// Bug: `ArrowPainter.shouldRepaint` inverts its boolean logic:
//   - length mismatch => `return false` (should be true);
//   - per-element inequality => `return false` (should be true);
//   - falls through to `return true` when everything is equal (should be false).
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   arrowsA       = [ChessArrow(a2->a4)]
//   arrowsAPlus   = [ChessArrow(a2->a4), ChessArrow(h1->h8)]
//   new ArrowPainter(arrowsAPlus, white).shouldRepaint(
//       ArrowPainter(arrowsA, white))
//     expected: true
//     observed: false
//
//   The inverted `length != oldDelegate.arrows.length` branch returns false.
// -----------------------------------------------------------------------------

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/utils/arrow_painter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§1.4 arrow repaint on list change', () {
    test('adding an arrow triggers repaint', () {
      final arrowsA = <ChessArrow>[
        ChessArrow(startSquare: 'a2', endSquare: 'a4'),
      ];
      final arrowsAPlus = <ChessArrow>[
        ...arrowsA,
        ChessArrow(startSquare: 'h1', endSquare: 'h8'),
      ];

      final oldPainter = ArrowPainter(arrowsA, PlayerColor.white);
      final newPainter = ArrowPainter(arrowsAPlus, PlayerColor.white);

      expect(
        newPainter.shouldRepaint(oldPainter),
        isTrue,
        reason: 'Arrow list length changed 1 -> 2; canvas must repaint. '
            'Unfixed code returns false because the branch is inverted.',
      );
    });

    test('changing an arrow endpoint triggers repaint', () {
      final arrowsA = <ChessArrow>[
        ChessArrow(startSquare: 'a2', endSquare: 'a4'),
      ];
      final arrowsDifferent = <ChessArrow>[
        ChessArrow(startSquare: 'a2', endSquare: 'a5'),
      ];

      final oldPainter = ArrowPainter(arrowsA, PlayerColor.white);
      final newPainter = ArrowPainter(arrowsDifferent, PlayerColor.white);

      expect(
        newPainter.shouldRepaint(oldPainter),
        isTrue,
        reason: 'Arrow endpoint changed a4 -> a5; canvas must repaint. '
            'Unfixed code returns false because the per-element branch is '
            'inverted.',
      );
    });

    test('identical painters do NOT trigger repaint', () {
      final arrowsA = <ChessArrow>[
        ChessArrow(startSquare: 'a2', endSquare: 'a4'),
      ];
      final oldPainter = ArrowPainter(arrowsA, PlayerColor.white);
      final newPainter = ArrowPainter(
        List<ChessArrow>.from(arrowsA),
        PlayerColor.white,
      );

      expect(
        newPainter.shouldRepaint(oldPainter),
        isFalse,
        reason:
            'Identical arrow list AND orientation should NOT cause repaint; '
            'unfixed code falls through to `return true` on equality.',
      );
    });
  });
}
