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
  List<ChessPiece> pieces = [];
  ChessPiece? selectedPiece;


  @override
  void initState() {
    super.initState();
    _initializePieces();
  }

  void _initializePieces() {
    pieces = [
      ChessPiece(
          type: PieceType.rook,
          color: PieceColor.black,
          position: Position(0, 0)),
      ChessPiece(
          type: PieceType.knight,
          color: PieceColor.black,
          position: Position(0, 1)),
      ChessPiece(
          type: PieceType.king,
          color: PieceColor.white,
          position: Position(1, 1)),
    ];
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
          final row = index ~/ 8;
          final col = index % 8;
          final isLightSquare = (row + col) % 2 == 0;
          final squareColor =
              isLightSquare ? widget.lightSquareColor : widget.darkSquareColor;

          // Find piece on the current square
          final piece = pieces
              .where(
                (p) => p.position.row == row && p.position.col == col,
              )
              .firstOrNull;

          return GestureDetector(
            onTap: () => _handleTap(row, col),
            child: Stack(
              children: [
                ChessSquare(color: squareColor),
                if (piece != null) _buildPiece(piece),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPiece(ChessPiece piece) {
    return Center(
      // child: Text(
      //   piece.type.toString().split('.').last,
      //   style: TextStyle(
      //     color: piece.color == PieceColor.white ? Colors.white : Colors.black,
      //     fontSize: 24,
      //   ),
      // ),
      child: getChessPieceWidget(piece),
    );
  }

  void _handleTap(int row, int col) {
    final tappedPiece = pieces
        .where(
          (p) => p.position.row == row && p.position.col == col,
        )
        .firstOrNull;

    setState(() {
      if (selectedPiece == null) {
        selectedPiece = tappedPiece; // Select the piece
      } else if (selectedPiece != null && tappedPiece == null) {
        // Move the selected piece if tapping an empty square
        selectedPiece!.position = Position(row, col);
        selectedPiece = null; // Deselect after moving
      } else {
        selectedPiece = tappedPiece; // Select a new piece
      }
    });
  }
}
