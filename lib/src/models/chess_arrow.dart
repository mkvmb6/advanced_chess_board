import 'package:flutter/material.dart';

/// A directional arrow drawn between two squares on the chess board.
///
/// Use a list of [ChessArrow]s to annotate moves, threats, plans, or any
/// other relationship between squares. Arrows are drawn as a line with an
/// equilateral-triangle arrowhead.
class ChessArrow {
  /// Creates a [ChessArrow] from [startSquare] to [endSquare].
  ///
  /// Both squares use algebraic notation (e.g. `"e2"`, `"e4"`).
  /// [color] defaults to a translucent amber (`Colors.amber.withAlpha(128)`).
  ChessArrow({
    required this.startSquare,
    required this.endSquare,
    final Color? color,
  }) : color = color ?? Colors.amber.withAlpha(128);

  /// Algebraic source square, e.g. `"e2"`.
  final String startSquare;

  /// Algebraic destination square, e.g. `"e4"`.
  final String endSquare;

  /// Colour of the arrow. Defaults to `Colors.amber.withAlpha(128)`.
  final Color? color;

  @override
  bool operator ==(final Object other) {
    return other is ChessArrow &&
        startSquare == other.startSquare &&
        endSquare == other.endSquare &&
        color == other.color;
  }

  @override
  int get hashCode =>
      startSquare.hashCode ^ endSquare.hashCode ^ color.hashCode;
}
