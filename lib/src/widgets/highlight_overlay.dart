import 'package:flutter/material.dart';

/// A translucent hint drawn on a square to indicate it is a legal
/// destination for the currently-selected piece.
///
/// Two visual styles:
/// - a small centered dot, when [hasPiece] is `false`;
/// - a hollow ring, when [hasPiece] is `true` (hinting a capture).
///
/// The [color] parameter controls the base colour; the ring border uses
/// `color.withAlpha(75)` and the dot fill uses `color.withAlpha(100)`,
/// preserving the 3.0.0 alpha values as derived shades of the theme's
/// base colour.
class HighlightOverlay extends StatelessWidget {
  /// Creates a highlight overlay.
  const HighlightOverlay({
    super.key,
    required this.squareSize,
    required this.hasPiece,
    required this.color,
  });

  /// Size of the underlying square in logical pixels.
  final double squareSize;

  /// Whether the square already contains a piece (capture hint).
  final bool hasPiece;

  /// Base colour for the overlay. The ring border uses `color.withAlpha(75)`
  /// and the dot fill uses `color.withAlpha(100)`.
  final Color color;

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
                  color: color.withAlpha(75),
                  width: squareSize * 0.1,
                ),
              ),
            )
          : Container(
              width: smallDotSize,
              height: smallDotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(100),
              ),
            ),
    );
  }
}
