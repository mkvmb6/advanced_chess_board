library advanced_chess_board;

import 'package:advanced_chess_board/utils/utils.dart';
import 'package:advanced_chess_board/widgets/chess_piece_widget.dart';
import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
import 'constants/global_constants.dart';
import 'widgets/chess_square.dart';
import 'widgets/highlight_overlay.dart';

class AdvancedChessBoard extends StatefulWidget {
  final Color lightSquareColor;
  final Color darkSquareColor;
  final String? initialFEN;

  const AdvancedChessBoard({
    super.key,
    this.lightSquareColor = const Color(0xFFEBECD0),
    this.darkSquareColor = const Color(0xFF739552),
    this.initialFEN,
  });

  @override
  State<AdvancedChessBoard> createState() => _AdvancedChessBoardState();
}

class _AdvancedChessBoardState extends State<AdvancedChessBoard> {
  chess.Chess game = chess.Chess();
  Set<String> legalMoves = {};
  String? selectedSquare;
  bool isPieceDragging = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFEN != null) {
      loadFromFEN(widget.initialFEN!);
    }
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
            ],
          ),
        );
      },
    );
  }

  bool _isMoveValid(final String from, final String to) {
    final validMoves = Set<String>.from(game.moves({squareKey: from}));
    return _isSquarePartOfValidMoves(validMoves, to);
  }

  Future<bool> _makeMove(final String from, final String to) async {
    if (_isPromotionMove(from, to)) {
      final pieceType = await _showPromotionDialog(context, 60);
      return game.move({
        fromKey: from,
        toKey: to,
        promotionKey: pieceTypeToString(pieceType),
      });
    }
    return game.move({fromKey: from, toKey: to});
  }

  bool _isPromotionMove(String from, String to) {
    final piece = game.get(from);
    return piece != null &&
        piece.type == chess.PieceType.PAWN &&
        ((piece.color == chess.Color.WHITE && to[1] == "8") ||
            (piece.color == chess.Color.BLACK && to[1] == "1"));
  }

  Widget _buildChessBoard(final double squareSize) {
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
        return _buildSquareWithDragTarget(square, squareColor, squareSize);
      },
    );
  }

  Widget _buildSquareWithDragTarget(
    final String square,
    final Color squareColor,
    final double squareSize,
  ) {
    final piece = game.get(square);
    final hasPiece = piece != null;
    return DragTarget<String>(
      onWillAcceptWithDetails: (data) {
        final fromSquare = data.data;
        return _isMoveValid(fromSquare, square);
      },
      onAcceptWithDetails: (fromSquare) async {
        await _makeMove(fromSquare.data, square);
        selectedSquare = null;
        legalMoves = {};
        setState(() {});
      },
      builder: (context, candidateData, rejectedData) {
        return GestureDetector(
          onTap: () => _handleTap(square),
          child: MouseRegion(
            cursor: isPieceDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.basic,
            child: Stack(
              children: [
                ChessSquare(color: squareColor),
                if (square == selectedSquare && hasPiece)
                  _buildSelectedPieceOverlay(),
                if (_isSquarePartOfValidMoves(legalMoves, square))
                  HighlightOverlay(hasPiece: hasPiece, squareSize: squareSize),
                if (hasPiece) _buildPiece(square, squareSize, piece),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPiece(
    final String square,
    final double squareSize,
    final chess.Piece piece,
  ) {
    return Draggable<String>(
      data: square,
      onDragStarted: () {
        setState(() {
          _setSelectedSquareAndFindLegalMoves(square);
          isPieceDragging = true;
        });
      },
      onDragEnd: (_) => setState(() {
        isPieceDragging = false;
      }),
      feedback: SizedBox(
        width: squareSize,
        height: squareSize,
        child: ChessPieceWidget(
          piece: piece,
          squareSize: squareSize,
          isDragging: isPieceDragging,
        ),
      ),
      childWhenDragging: Container(),
      // Empty space while dragging
      child: ChessPieceWidget(
        piece: piece,
        squareSize: squareSize,
        isDragging: isPieceDragging,
        onTap: () => _handleTap(square),
      ),
    );
  }

  Widget _buildSelectedPieceOverlay() {
    return Container(
      color: Colors.yellow.withOpacity(0.6),
    );
  }

  bool _isSquarePartOfValidMoves(
      final Set<String> validMoves, final String square) {
    return validMoves.any((move) => move.contains(square)) ||
        (game.turn == chess.Color.WHITE &&
            square == "g1" &&
            validMoves.contains("O-O")) ||
        (game.turn == chess.Color.WHITE &&
            square == "c1" &&
            validMoves.contains("O-O-O")) ||
        (game.turn == chess.Color.BLACK &&
            square == "g8" &&
            validMoves.contains("O-O")) ||
        (game.turn == chess.Color.BLACK &&
            square == "c8" &&
            validMoves.contains("O-O-O"));
  }

  Future<void> _handleTap(String square) async {
    if (selectedSquare == null ||
        (selectedSquare != square && game.turn == game.get(square)?.color)) {
      // Select a piece and highlight legal moves
      _setSelectedSquareAndFindLegalMoves(square);
    } else if (selectedSquare == square) {
      // Deselect if tapping on the same square
      selectedSquare = null;
      legalMoves = {};
    } else {
      // Attempt to make a move
      if (_isMoveValid(selectedSquare!, square)) {
        await _makeMove(selectedSquare!, square);
      }
      selectedSquare = null;
      legalMoves = {};
    }
    setState(() {});
  }

  void _setSelectedSquareAndFindLegalMoves(String square) {
    selectedSquare = square;
    legalMoves = Set<String>.from(game.moves({squareKey: square}));
  }

  String _indexToSquare(int index) {
    final row = 8 - (index ~/ 8);
    final col = String.fromCharCode('a'.codeUnitAt(0) + (index % 8));
    return '$col$row';
  }

  Future<chess.PieceType> _showPromotionDialog(
    BuildContext context,
    final double squareSize,
  ) async {
    return await showDialog<chess.PieceType>(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  chess.PieceType.QUEEN,
                  chess.PieceType.ROOK,
                  chess.PieceType.BISHOP,
                  chess.PieceType.KNIGHT
                ].map((pieceType) {
                  return ChessPieceWidget(
                    piece: chess.Piece(pieceType, game.turn),
                    squareSize: squareSize,
                    onTap: () => Navigator.of(context).pop(pieceType),
                  );
                }).toList(),
              ),
            );
          },
        ) ??
        chess.PieceType.QUEEN; // Default to queen if dialog is dismissed
  }

  void loadFromFEN(final String fen) {
    setState(() {
      game.load(fen);
    });
  }
}
