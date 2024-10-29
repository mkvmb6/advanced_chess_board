library advanced_chess_board;

import 'package:advanced_chess_board/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'models/chess_piece.dart';
import 'models/position.dart';
import 'widgets/chess_square.dart';

class AdvancedChessBoard extends StatefulWidget {
  // Board color configuration
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
      if (selectedSquare == null) {
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

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: GridView.builder(
        itemCount: 64,
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        itemBuilder: (context, index) {
          final row = 7 - index ~/ 8;
          final col = index % 8;
          final square = '${String.fromCharCode(97 + col)}${row + 1}';
          final isLightSquare = (row + col) % 2 == 0;
          final squareColor =
              isLightSquare ? widget.lightSquareColor : widget.darkSquareColor;

          final isHighlighted = legalMoves.any((move) => move.contains(square));
          final hasPiece = game.get(square) != null;
          return GestureDetector(
            onTap: () => _handleTap(square),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final smallDotSize = constraints.maxWidth * 0.3;
                final circleSize = constraints.maxWidth * 0.98;
                return Stack(
                  children: [
                    ChessSquare(color: squareColor),
                    if (isHighlighted)
                      Align(
                        alignment: Alignment.center,
                        child: hasPiece
                            ? Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.grey.withOpacity(0.7),
                                    width: constraints.maxWidth * 0.1,
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
                      ),
                    if (hasPiece) _buildPiece(game.get(square)!),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildPiece(chess.Piece piece) {
    return Center(
      child: getChessPieceWidget(piece),
    );
  }
}
