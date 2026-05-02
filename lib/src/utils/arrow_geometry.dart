import '../models/enums.dart';

/// Maps an algebraic [square] (e.g. `"e4"`) to a `(row, col)` index pair
/// in the board's visual coordinate space, accounting for [orientation].
///
/// The returned `(row, col)` pair uses zero-based indices where `(0, 0)` is
/// the top-left corner of the rendered board. When [orientation] is
/// [PlayerColor.white], rank 8 is at row 0 and the a-file is at column 0.
/// When [orientation] is [PlayerColor.black], the board is flipped: rank 1
/// is at row 0 and the h-file is at column 0.
///
/// [square] must be a valid algebraic square in the form `"<file><rank>"`,
/// e.g. `"a1"`, `"e4"`, `"h8"`.
(int, int) getIndexFromSquare(String square, PlayerColor orientation) {
  var row = 8 - square[1].codeUnitAt(0) + 48;
  var col = square[0].codeUnitAt(0) - 97;
  if (orientation == PlayerColor.black) {
    row = 7 - row;
    col = 7 - col;
  }
  return (row, col);
}
