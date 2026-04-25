import 'package:flutter/material.dart';

/// A translucent hint drawn on a square to indicate it is a legal
/// destination for the currently-selected piece.
///
/// Two visual styles:
/// - a small centered dot, when [hasPiece] is `false`;
/// - a hollow ring, when [hasPiece] is `true` (hinting a capture).
class HighlightOverlay extends StatelessWidget {
  /// Creates a highlight overlay.
  const HighlightOverlay({
    super.key,
    required this.squareSize,
    required this.hasPiece,
  });

  /// Size of the underlying square in logical pixels.
  final double squareSize;

  /// Whether the square already contains a piece (capture hint).
  final bool hasPiece;

  @override
  Widget build(final BuildContext context) {
    final smallDotSize = squareSize * 0.3;
    final circleSize = squareSize * 0.98;
    return Align(
      child: hasPiece
          ? Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black12.withAlpha(75),
                  width: squareSize * 0.1,
                ),
              ),
            )
          : Container(
              width: smallDotSize,
              height: smallDotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black12.withAlpha(100),
              ),
            ),
    );
  }
}
