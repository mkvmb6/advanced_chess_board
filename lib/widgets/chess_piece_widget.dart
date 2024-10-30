import 'package:advanced_chess_board/utils/utils.dart';
import 'package:flutter/material.dart';

import 'package:chess/chess.dart' as chess;

class ChessPieceWidget extends StatelessWidget {
  final chess.Piece piece;
  final double squareSize;
  final String square;
  final void Function(String) onTap;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    required this.squareSize,
    required this.square,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: SizedBox(
        width: squareSize,
        height: squareSize,
        child: _buildPiece(),
      ),
    );
  }

  Widget _buildPiece() {
    return Center(
      child: GestureDetector(
        onTap: () => onTap(square),
        child: getChessPieceWidget(piece),
      ),
    );
  }
}
