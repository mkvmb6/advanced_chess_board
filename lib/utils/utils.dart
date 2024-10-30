import 'package:advanced_chess_board/constants/global_constants.dart';
import 'package:advanced_chess_board/constants/image_constants.dart';
import 'package:chess/chess.dart';
import 'package:flutter/material.dart';

Widget getChessPieceWidget(final Piece chessPiece) {
  if (chessPiece.color == Color.WHITE) {
    switch (chessPiece.type) {
      case PieceType.BISHOP:
        return Image.asset(
          PieceImages.whiteBishop,
          package: packageName,
        );
      case PieceType.KING:
        return Image.asset(
          PieceImages.whiteKing,
          package: packageName,
        );
      case PieceType.KNIGHT:
        return Image.asset(
          PieceImages.whiteKnight,
          package: packageName,
        );
      case PieceType.PAWN:
        return Image.asset(
          PieceImages.whitePawn,
          package: packageName,
        );
      case PieceType.QUEEN:
        return Image.asset(
          PieceImages.whiteQueen,
          package: packageName,
        );
      case PieceType.ROOK:
        return Image.asset(
          PieceImages.whiteRook,
          package: packageName,
        );
    }
  } else {
    switch (chessPiece.type) {
      case PieceType.BISHOP:
        return Image.asset(
          PieceImages.blackBishop,
          package: packageName,
        );
      case PieceType.KING:
        return Image.asset(
          PieceImages.blackKing,
          package: packageName,
        );
      case PieceType.KNIGHT:
        return Image.asset(
          PieceImages.blackKnight,
          package: packageName,
        );
      case PieceType.PAWN:
        return Image.asset(
          PieceImages.blackPawn,
          package: packageName,
        );
      case PieceType.QUEEN:
        return Image.asset(
          PieceImages.blackQueen,
          package: packageName,
        );
      case PieceType.ROOK:
        return Image.asset(
          PieceImages.blackRook,
          package: packageName,
        );
    }
  }
  return const Text("No piece found");
}

String pieceTypeToString(final PieceType pieceType) {
  switch (pieceType) {
    case PieceType.BISHOP:
      return "b";
    case PieceType.KING:
      return "k";
    case PieceType.KNIGHT:
      return "n";
    case PieceType.PAWN:
      return "p";
    case PieceType.QUEEN:
      return "q";
    case PieceType.ROOK:
      return "r";
  }
  return "q";
}
