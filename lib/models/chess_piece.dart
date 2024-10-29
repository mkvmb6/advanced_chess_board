import '../models/position.dart';

enum PieceType { pawn, knight, bishop, rook, queen, king }
enum PieceColor { white, black }

class ChessPiece {
  final PieceType type;
  final PieceColor color;
  Position position;

  ChessPiece({
    required this.type,
    required this.color,
    required this.position,
  });
}
