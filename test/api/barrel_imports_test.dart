// Compile-only smoke test: importing ONLY the barrel must expose the four
// public symbols of the package.
//
// Covers §2.15, §2.16 (public API reorganisation + barrel) and preserves
// §3.19 (top-level import still resolves).

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('barrel re-exports the four public symbols', () {
    expect(AdvancedChessBoard, isA<Type>());
    expect(ChessBoardController, isA<Type>());
    expect(ChessArrow, isA<Type>());
    expect(PlayerColor.white, isA<PlayerColor>());
    expect(PlayerColor.black, isA<PlayerColor>());
  });
}
