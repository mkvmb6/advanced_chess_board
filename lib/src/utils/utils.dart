import 'package:chess/chess.dart';
import 'package:flutter/material.dart';

import '../constants/global_constants.dart';
import '../constants/image_constants.dart';

/// Returns a [Widget] rendering [chessPiece] as a `package:advanced_chess_board`
/// asset image.
Widget getChessPieceWidget(final Piece chessPiece) {
  if (chessPiece.color == Color.WHITE) {
    switch (chessPiece.type) {
      case PieceType.BISHOP:
        return _getPieceImageWidget(PieceImages.whiteBishop);
      case PieceType.KING:
        return _getPieceImageWidget(PieceImages.whiteKing);
      case PieceType.KNIGHT:
        return _getPieceImageWidget(PieceImages.whiteKnight);
      case PieceType.PAWN:
        return _getPieceImageWidget(PieceImages.whitePawn);
      case PieceType.QUEEN:
        return _getPieceImageWidget(PieceImages.whiteQueen);
      case PieceType.ROOK:
        return _getPieceImageWidget(PieceImages.whiteRook);
    }
    throw StateError('Unreachable: unknown white piece type ${chessPiece.type}');
  }
  switch (chessPiece.type) {
    case PieceType.BISHOP:
      return _getPieceImageWidget(PieceImages.blackBishop);
    case PieceType.KING:
      return _getPieceImageWidget(PieceImages.blackKing);
    case PieceType.KNIGHT:
      return _getPieceImageWidget(PieceImages.blackKnight);
    case PieceType.PAWN:
      return _getPieceImageWidget(PieceImages.blackPawn);
    case PieceType.QUEEN:
      return _getPieceImageWidget(PieceImages.blackQueen);
    case PieceType.ROOK:
      return _getPieceImageWidget(PieceImages.blackRook);
  }
  throw StateError('Unreachable: unknown black piece type ${chessPiece.type}');
}

Widget _getPieceImageWidget(final String assetPath) {
  return Image.asset(
    assetPath,
    package: packageName,
    fit: BoxFit.contain,
  );
}

/// Returns the single-character piece letter used by the `chess` package's
/// move API (`'q'`, `'r'`, `'b'`, `'n'`, `'p'`, `'k'`).
String pieceTypeToString(final PieceType pieceType) {
  switch (pieceType) {
    case PieceType.BISHOP:
      return 'b';
    case PieceType.KING:
      return 'k';
    case PieceType.KNIGHT:
      return 'n';
    case PieceType.PAWN:
      return 'p';
    case PieceType.QUEEN:
      return 'q';
    case PieceType.ROOK:
      return 'r';
  }
  throw StateError('Unreachable: unknown piece type $pieceType');
}

/// Returns a human-readable descriptive label for [piece], e.g. "white pawn"
/// or "black knight". Used by the board's [Semantics] wrappers.
String pieceSemanticsLabel(final Piece? piece) {
  if (piece == null) return 'empty';
  final colorWord = piece.color == Color.WHITE ? 'white' : 'black';
  final typeWord = switch (piece.type) {
    PieceType.PAWN => 'pawn',
    PieceType.KNIGHT => 'knight',
    PieceType.BISHOP => 'bishop',
    PieceType.ROOK => 'rook',
    PieceType.QUEEN => 'queen',
    PieceType.KING => 'king',
    _ => 'piece',
  };
  return '$colorWord $typeWord';
}
