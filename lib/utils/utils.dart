
import 'package:advanced_chess_board/constants/global_constants.dart';
import 'package:advanced_chess_board/constants/image_constants.dart';
import 'package:chess_vectors_flutter/chess_vectors_flutter.dart';
import 'package:flutter/material.dart';

import '../models/chess_piece.dart';

Widget getChessPieceWidget(final ChessPiece chessPiece) {
  if(chessPiece.color == PieceColor.white) {
    switch(chessPiece.type){
      case PieceType.pawn:
        return Image.asset(PieceImages.whitePawn, package: packageName,);
      case PieceType.knight:
        return Image.asset(PieceImages.whiteKnight, package: packageName,);
      case PieceType.bishop:
        return Image.asset(PieceImages.whiteBishop, package: packageName,);
      case PieceType.rook:
        return Image.asset(PieceImages.whiteRook, package: packageName,);
      case PieceType.queen:
        return Image.asset(PieceImages.whiteQueen, package: packageName,);
      case PieceType.king:
        return Image.asset(PieceImages.whiteKing, package: packageName,);
    }
  }
  else {
    switch(chessPiece.type){
      case PieceType.pawn:
        return Image.asset(PieceImages.blackPawn, package: packageName,);
      case PieceType.knight:
        return Image.asset(PieceImages.blackKnight, package: packageName,);
      case PieceType.bishop:
        return Image.asset(PieceImages.blackBishop, package: packageName,);
      case PieceType.rook:
        return Image.asset(PieceImages.blackRook, package: packageName,);
      case PieceType.queen:
        return Image.asset(PieceImages.blackQueen, package: packageName,);
      case PieceType.king:
        return Image.asset(PieceImages.blackKing, package: packageName,);
    }    
  }
}