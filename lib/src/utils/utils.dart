import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../piece_set/piece_set.dart';

/// Maps a [chess.Color] to the corresponding [PlayerColor].
PlayerColor _playerColorOf(final chess.Color c) {
  return c == chess.Color.WHITE ? PlayerColor.white : PlayerColor.black;
}

/// Returns a [Widget] rendering [piece] using the given [set].
///
/// Delegates to [set.imageFor] to obtain the [ImageProvider], then wraps it
/// in an [Image] with [BoxFit.contain]. This replaces the old
/// `getChessPieceWidget` helper and decouples piece rendering from the
/// hard-coded asset paths.
Widget buildPieceWidget(final chess.Piece piece, final PieceSet set) {
  return Image(
    image: set.imageFor(_playerColorOf(piece.color), piece.type),
    fit: BoxFit.contain,
  );
}

/// Returns the single-character piece letter used by the `chess` package's
/// move API (`'q'`, `'r'`, `'b'`, `'n'`, `'p'`, `'k'`).
String pieceTypeToString(final chess.PieceType pieceType) {
  switch (pieceType) {
    case chess.PieceType.BISHOP:
      return 'b';
    case chess.PieceType.KING:
      return 'k';
    case chess.PieceType.KNIGHT:
      return 'n';
    case chess.PieceType.PAWN:
      return 'p';
    case chess.PieceType.QUEEN:
      return 'q';
    case chess.PieceType.ROOK:
      return 'r';
    default:
      throw StateError('Unreachable: unknown piece type $pieceType');
  }
}

/// Returns a human-readable descriptive label for [piece], e.g. "white pawn"
/// or "black knight". Used by the board's [Semantics] wrappers.
String pieceSemanticsLabel(final chess.Piece? piece) {
  if (piece == null) return 'empty';
  final colorWord = piece.color == chess.Color.WHITE ? 'white' : 'black';
  final typeWord = switch (piece.type) {
    chess.PieceType.PAWN => 'pawn',
    chess.PieceType.KNIGHT => 'knight',
    chess.PieceType.BISHOP => 'bishop',
    chess.PieceType.ROOK => 'rook',
    chess.PieceType.QUEEN => 'queen',
    chess.PieceType.KING => 'king',
    _ => 'piece',
  };
  return '$colorWord $typeWord';
}
