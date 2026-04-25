/// Asset paths for every chess piece image bundled with this package.
///
/// Paths are relative to the package root and must be loaded with
/// `package: 'advanced_chess_board'` on [AssetImage] / [Image.asset].
class PieceImages {
  /// Private constructor — this class is a namespace of constants.
  const PieceImages._();

  /// Black rook asset path.
  static const String blackRook = 'assets/pieces/br.png';

  /// Black bishop asset path.
  static const String blackBishop = 'assets/pieces/bb.png';

  /// Black knight asset path.
  static const String blackKnight = 'assets/pieces/bn.png';

  /// Black queen asset path.
  static const String blackQueen = 'assets/pieces/bq.png';

  /// Black king asset path.
  static const String blackKing = 'assets/pieces/bk.png';

  /// Black pawn asset path.
  static const String blackPawn = 'assets/pieces/bp.png';

  /// White rook asset path.
  static const String whiteRook = 'assets/pieces/wr.png';

  /// White bishop asset path.
  static const String whiteBishop = 'assets/pieces/wb.png';

  /// White knight asset path.
  static const String whiteKnight = 'assets/pieces/wn.png';

  /// White queen asset path.
  static const String whiteQueen = 'assets/pieces/wq.png';

  /// White king asset path.
  static const String whiteKing = 'assets/pieces/wk.png';

  /// White pawn asset path.
  static const String whitePawn = 'assets/pieces/wp.png';
}
