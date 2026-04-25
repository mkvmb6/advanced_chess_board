import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../utils/utils.dart';

/// A single chess piece tile sized to fit the board square it occupies.
///
/// Wraps a cached asset image in a [MouseRegion] that flips the cursor
/// between `grab` / `grabbing` / `basic` depending on [isDragging] and
/// [isBoardEnabled], and exposes a descriptive [Semantics] label for
/// assistive technologies.
class ChessPieceWidget extends StatelessWidget {
  /// Creates a [ChessPieceWidget] rendering [piece] at [squareSize] px.
  const ChessPieceWidget({
    super.key,
    required this.piece,
    required this.squareSize,
    required this.isBoardEnabled,
    this.isDragging = false,
    this.onTap,
  });

  /// The chess piece to render.
  final chess.Piece piece;

  /// Size in logical pixels of the square this piece occupies.
  final double squareSize;

  /// `true` while this piece is currently being dragged; changes the mouse
  /// cursor to `grabbing`.
  final bool isDragging;

  /// `true` when the board accepts moves; controls whether the piece shows
  /// a `grab` cursor.
  final bool isBoardEnabled;

  /// Callback fired when the piece is tapped (pointer down).
  final VoidCallback? onTap;

  @override
  Widget build(final BuildContext context) {
    return Semantics(
      label: pieceSemanticsLabel(piece),
      button: isBoardEnabled,
      child: MouseRegion(
        cursor: isDragging
            ? SystemMouseCursors.grabbing
            : isBoardEnabled
                ? SystemMouseCursors.grab
                : SystemMouseCursors.basic,
        child: SizedBox(
          width: squareSize,
          height: squareSize,
          child: Center(
            child: GestureDetector(
              onTapDown: (_) {
                if (onTap != null) onTap!();
              },
              child: getChessPieceWidget(piece),
            ),
          ),
        ),
      ),
    );
  }
}
