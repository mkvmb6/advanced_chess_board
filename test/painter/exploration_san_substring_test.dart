// Exploration test — bugfix.md §1.6.
//
// PROPERTY: prop_verbose_moves_is_destination_oracle (design.md P1.4).
// Validates: Requirements 1.6
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   FEN: r3k3/8/8/8/8/8/8/R3K3 w - - 0 1
//   The old `_isSquarePartOfValidMoves` used `move.contains(square)` against
//   SAN strings. Probing sentinel non-squares like "a" or "R" against the
//   rook's SAN list (["Ra2", "Ra3", ..., "Rxa8", "Rb1", ...]) returned true
//   because those letters appear as substrings of legitimate SAN tokens.
//
//   Fixed code uses `chess.Chess.generate_moves({'square': X})` and compares
//   each returned Move's `toAlgebraic` to the target — only genuine chess
//   squares can match, and every match is by exact equality.
// -----------------------------------------------------------------------------

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§1.6 verbose-moves destination oracle', () {
    test(
      'non-square sentinel "a" is not a legal destination from a1',
      () {
        final controller = ChessBoardController();
        controller.loadGameFromFEN('r3k3/8/8/8/8/8/8/R3K3 w - - 0 1');

        // The fixed helper works via `generate_moves` and `toAlgebraic`,
        // so only real algebraic squares can appear as destinations. A
        // bare letter "a" is not one of them — attempting the move must
        // return false.
        final accepted = controller.makeMove(from: 'a1', to: 'a');
        expect(
          accepted,
          isFalse,
          reason:
              '"a" is not a valid algebraic square; makeMove must reject it. '
              'The unfixed code would have accepted it because SAN tokens '
              'containing "a" match the substring check.',
        );
      },
    );

    test(
      'piece letter "R" is not a legal destination from a1',
      () {
        final controller = ChessBoardController();
        controller.loadGameFromFEN('r3k3/8/8/8/8/8/8/R3K3 w - - 0 1');

        final accepted = controller.makeMove(from: 'a1', to: 'R');
        expect(
          accepted,
          isFalse,
          reason:
              '"R" is a piece letter, not a square; makeMove must reject it.',
        );
      },
    );

    test(
      'genuine castling squares ARE legal destinations via verbose moves',
      () {
        // Starting castle-ready FEN: king on e1, rooks on a1/h1.
        final controller = ChessBoardController();
        controller.loadGameFromFEN('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');

        // Kingside: king on e1 → g1 (castle short).
        final shortAccepted = controller.makeMove(from: 'e1', to: 'g1');
        expect(shortAccepted, isTrue,
            reason: 'Short castling (e1->g1) must be legal.');

        // Reload and try queenside.
        controller.loadGameFromFEN('r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1');
        final longAccepted = controller.makeMove(from: 'e1', to: 'c1');
        expect(longAccepted, isTrue,
            reason: 'Long castling (e1->c1) must be legal.');
      },
    );
  });
}
