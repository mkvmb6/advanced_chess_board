import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

class ChessSquare extends StatelessWidget {
  final Color color;
  final String square;
  final chess.Color boardOrientation;
  final double squareSize;

  const ChessSquare({
    super.key,
    required this.color,
    required this.square,
    required this.boardOrientation,
    required this.squareSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
      ),
      alignment: Alignment.topLeft,
      child: _buildSquareName(),
    );
  }

  Widget _buildSquareName() {
    final file = square[0];
    final rank = square[1];
    final isRankRendered = _shouldRankBeRendered(file, rank);
    final isFileRendered = _shouldFileBeRendered(file, rank);

    return Column(
      mainAxisAlignment: isRankRendered
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.end,
      children: [
        if (isRankRendered) _buildTextWidget(rank),
        if (isFileRendered) _buildTextWidget(file),
      ],
    );
  }

  Padding _buildTextWidget(final String rank) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0),
      child: Text(
        rank,
        style: TextStyle(
            color: Colors.black26,
            fontWeight: FontWeight.bold,
            fontSize: squareSize * 0.18),
      ),
    );
  }

  bool _shouldRankBeRendered(final String file, final String rank) {
    if (boardOrientation == chess.Color.WHITE) {
      return file == "a";
    } else {
      return file == "h";
    }
  }

  bool _shouldFileBeRendered(final String file, final String rank) {
    if (boardOrientation == chess.Color.WHITE) {
      return rank == "1";
    } else {
      return rank == "8";
    }
  }
}
