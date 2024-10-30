library advanced_chess_board;

import 'package:advanced_chess_board/widgets/chess_piece_widget.dart';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'widgets/chess_square.dart';

class AdvancedChessBoard extends StatefulWidget {
  final Color lightSquareColor;
  final Color darkSquareColor;

  const AdvancedChessBoard({
    super.key,
    this.lightSquareColor = const Color(0xFFEBECD0),
    this.darkSquareColor = const Color(0xFF739552),
  });

  @override
  State<AdvancedChessBoard> createState() => _AdvancedChessBoardState();
}

class _AdvancedChessBoardState extends State<AdvancedChessBoard> {
  chess.Chess game = chess.Chess();
  List<String> legalMoves = [];
  String? selectedSquare;

  void _handleTap(String square) {
    setState(() {
      if (selectedSquare == null ||
          (selectedSquare != square && game.turn == game.get(square)?.color)) {
        // Select a piece and highlight legal moves
        selectedSquare = square;
        legalMoves = List<String>.from(game.moves({"square": square}));
        print(legalMoves);
      } else if (selectedSquare == square) {
        // Deselect if tapping on the same square
        selectedSquare = null;
        legalMoves = [];
      } else {
        // Attempt to make a move
        String moveNotation = '$selectedSquare$square';
        if (legalMoves
            .any((move) => move == moveNotation || move.contains(square))) {
          game.move({'from': selectedSquare, 'to': square});
        }
        selectedSquare = null;
        legalMoves = [];
      }
    });
  }

  Offset _calculatePieceOffset(int index, double squareSize) {
    final row = index ~/ 8;
    final col = index % 8;
    return Offset(col * squareSize, row * squareSize);
  }

  String _indexToSquare(int index) {
    final row = 8 - (index ~/ 8);
    final col = String.fromCharCode('a'.codeUnitAt(0) + (index % 8));
    return '$col$row';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, boxConstraints) {
        final squareSize = boxConstraints.maxWidth / 8;
        return AspectRatio(
          aspectRatio: 1.0,
          child: Stack(
            children: [
              _buildChessBoard(squareSize),
              _buildAnimatedPieces(squareSize)
            ],
          ),
        );
      },
    );
  }

  GridView _buildChessBoard(double squareSize) {
    return GridView.builder(
      itemCount: 64,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
      itemBuilder: (context, index) {
        final row = 7 - index ~/ 8;
        final col = index % 8;
        final square = _indexToSquare(index);
        final isLightSquare = (row % 2) != (col % 2);
        final squareColor =
            isLightSquare ? widget.lightSquareColor : widget.darkSquareColor;

        final hasPiece = game.get(square) != null;
        return GestureDetector(
          onTap: () => _handleTap(square),
          child: Stack(
            children: [
              ChessSquare(color: squareColor),
              if (square == selectedSquare && game.get(square) != null)
                _buildSelectedPieceOverlay(),
              if (_isSquareHighlighted(square))
                _buildHighlightOverlay(hasPiece, squareSize),
            ],
          ),
        );
      },
    );
  }

  Align _buildHighlightOverlay(final bool hasPiece, final double squareSize) {
    final smallDotSize = squareSize * 0.3;
    final circleSize = squareSize * 0.98;
    return Align(
      alignment: Alignment.center,
      child: hasPiece
          ? Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.withOpacity(0.7),
                  width: squareSize * 0.1,
                ),
              ),
            )
          : Container(
              width: smallDotSize,
              height: smallDotSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
    );
  }

  Widget _buildSelectedPieceOverlay() {
    return Container(
      color: Colors.yellow.withOpacity(0.6),
    );
  }

  Widget _buildAnimatedPieces(double squareSize) {
    return Stack(
      children: [
        for (var index = 0; index < 64; index++)
          if (game.get(_indexToSquare(index)) != null)
            _buildPieceAtSquare(index, squareSize),
      ],
    );
  }

  Widget _buildPieceAtSquare(int index, double squareSize) {
    final square = _indexToSquare(index);
    final piece = game.get(square)!;
    final offset = _calculatePieceOffset(index, squareSize);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 15),
      curve: Curves.easeInOut,
      left: offset.dx,
      top: offset.dy,
      child: ChessPieceWidget(
        piece: piece,
        squareSize: squareSize,
        square: square,
        onTap: _handleTap,
      ),
    );
  }

  bool _isSquareHighlighted(String square) {
    return legalMoves.any((move) => move.contains(square));
  }
}
