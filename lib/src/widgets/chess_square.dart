import 'dart:math' as math;

import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../constants/global_constants.dart';
import '../coordinates/coordinate_labels.dart';
import '../models/enums.dart';
import '../utils/utils.dart';

/// A single 64th of the board: the coloured background tile plus optional
/// rank/file labels along the a-file (white) / h-file (black) and 1st rank
/// (white) / 8th rank (black) edges.
///
/// The tile is wrapped in a [Semantics] node labelled
/// `"<square>, <piece description|empty>"` for screen readers.
class ChessSquare extends StatelessWidget {
  /// Creates a [ChessSquare].
  const ChessSquare({
    super.key,
    required this.color,
    required this.invertColor,
    required this.square,
    required this.boardOrientation,
    required this.squareSize,
    required this.coordinates,
    this.piece,
    this.labelColor,
  });

  /// Background colour of the square.
  final Color color;

  /// Colour used for the rank/file labels when [labelColor] is `null`
  /// (typically the inverse of [color]).
  final Color invertColor;

  /// Algebraic square name, e.g. `"e4"`.
  final String square;

  /// Orientation of the board; controls which edge carries labels.
  final PlayerColor boardOrientation;

  /// Size of the square in logical pixels.
  final double squareSize;

  /// Coordinate-label rendering mode. When [CoordinateLabels.inside],
  /// labels are rendered inside the corner squares. Otherwise, no inside
  /// labels are rendered.
  final CoordinateLabels coordinates;

  /// The piece currently on this square, or `null` if empty. Used to build
  /// the [Semantics] label.
  final chess.Piece? piece;

  /// Optional explicit label colour. When non-null, labels use this colour
  /// at alpha 200. When `null`, labels use [invertColor] at alpha 200,
  /// matching 3.0.0 behaviour.
  final Color? labelColor;

  @override
  Widget build(final BuildContext context) {
    final file = square[0];
    final rank = square[1];
    // Labels only render inside the square when coordinates == inside.
    final showInsideLabels = coordinates == CoordinateLabels.inside;
    final isRankRendered = showInsideLabels && _shouldRankBeRendered(file);
    final isFileRendered = showInsideLabels && _shouldFileBeRendered(rank);
    final fontSize = math.max(kMinLabelFontSize, squareSize * 0.18);
    final effectiveLabelColor = labelColor ?? invertColor;

    return Semantics(
      container: true,
      label: '$square, ${pieceSemanticsLabel(piece)}',
      excludeSemantics: true,
      child: ClipRect(
        child: Container(
          decoration: BoxDecoration(color: color),
          alignment: Alignment.topLeft,
          child: Stack(
            children: <Widget>[
              if (isRankRendered)
                Positioned(
                  left: 2,
                  top: 0,
                  child: _buildLabel(rank, fontSize, effectiveLabelColor),
                ),
              if (isFileRendered)
                Positioned(
                  right: 2,
                  bottom: 0,
                  child: _buildLabel(file, fontSize, effectiveLabelColor),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(
    final String label,
    final double fontSize,
    final Color color,
  ) {
    return Text(
      label,
      style: TextStyle(color: color.withAlpha(200), fontSize: fontSize),
    );
  }

  bool _shouldRankBeRendered(final String file) {
    return boardOrientation == PlayerColor.white ? file == 'a' : file == 'h';
  }

  bool _shouldFileBeRendered(final String rank) {
    return boardOrientation == PlayerColor.white ? rank == '1' : rank == '8';
  }
}
