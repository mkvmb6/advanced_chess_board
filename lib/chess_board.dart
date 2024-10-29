library advanced_chess_board;

import 'package:flutter/material.dart';

import 'models/chess_piece.dart';


class ChessBoard extends StatefulWidget {
  final double size;
  final Function(String from, String to)? onMove;
  final Function(String position)? onPieceSelected;
  final bool enableDrag;

  const ChessBoard({
    Key? key,
    this.size = 400,
    this.onMove,
    this.onPieceSelected,
    this.enableDrag = true,
  }) : super(key: key);

  @override
  ChessBoardState createState() => ChessBoardState();
}

class ChessBoardState extends State<ChessBoard> with SingleTickerProviderStateMixin {
  late BoardState boardState;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    boardState = BoardState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
        ),
        itemCount: 64,
        itemBuilder: _buildSquare,
      ),
    );
  }

  Widget _buildSquare(BuildContext context, int index) {
    // TODO: Implement square building with pieces
    return Container();
  }
}


class BoardState {
  Map<String, ChessPiece?> pieces = {};
  bool isWhiteTurn = true;
  Set<String> highlightedSquares = {};
  String? selectedPiece;
  bool isFlipped = false;

  BoardState();

  void loadFromFEN(String fen) {
    // TODO: Implement FEN parsing
  }

  List<String> getLegalMoves(String position) {
    // TODO: Implement legal move calculation
    return [];
  }
}