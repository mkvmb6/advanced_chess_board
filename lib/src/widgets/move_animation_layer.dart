import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../piece_set/piece_set.dart';
import 'chess_piece_widget.dart';

/// An overlay layer that animates a chess piece from one square to another
/// when a move is made via tap or the controller's programmatic API.
///
/// Drag-and-drop moves do NOT use this layer — the [Draggable.feedback]
/// already follows the pointer. See [AdvancedChessBoard.moveAnimationDuration].
class MoveAnimationLayer extends StatefulWidget {
  /// Creates a [MoveAnimationLayer].
  const MoveAnimationLayer({
    super.key,
    required this.fromSquare,
    required this.toSquare,
    required this.piece,
    required this.squareSize,
    required this.orientation,
    required this.duration,
    required this.onComplete,
    required this.pieceSet,
  });

  /// Algebraic source square, e.g. `"e2"`.
  final String fromSquare;

  /// Algebraic destination square, e.g. `"e4"`.
  final String toSquare;

  /// Piece being moved.
  final chess.Piece piece;

  /// Side length of one square in logical pixels.
  final double squareSize;

  /// Orientation of the board; controls the square → pixel mapping.
  final PlayerColor orientation;

  /// Duration of the translation.
  final Duration duration;

  /// Fired once the animation completes.
  final VoidCallback onComplete;

  /// The piece set used to render the animating piece.
  final PieceSet pieceSet;

  @override
  State<MoveAnimationLayer> createState() => _MoveAnimationLayerState();
}

class _MoveAnimationLayerState extends State<MoveAnimationLayer> {
  bool _started = false;

  @override
  void initState() {
    super.initState();
    // Trigger the AnimatedPositioned transition on the next frame by
    // flipping _started to true after the widget is in the tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _started = true;
        });
      }
    });
  }

  Offset _offsetForSquare(final String square) {
    final file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = int.parse(square[1]);
    final col = widget.orientation == PlayerColor.white ? file : 7 - file;
    final row = widget.orientation == PlayerColor.white ? 8 - rank : rank - 1;
    return Offset(col * widget.squareSize, row * widget.squareSize);
  }

  @override
  Widget build(final BuildContext context) {
    final from = _offsetForSquare(widget.fromSquare);
    final to = _offsetForSquare(widget.toSquare);
    final current = _started ? to : from;
    return IgnorePointer(
      child: SizedBox.expand(
        child: Stack(
          children: <Widget>[
            AnimatedPositioned(
              duration: widget.duration,
              curve: Curves.easeOutCubic,
              left: current.dx,
              top: current.dy,
              width: widget.squareSize,
              height: widget.squareSize,
              onEnd: widget.onComplete,
              child: ChessPieceWidget(
                piece: widget.piece,
                squareSize: widget.squareSize,
                isBoardEnabled: false,
                pieceSet: widget.pieceSet,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
