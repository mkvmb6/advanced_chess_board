import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

import '../constants/global_constants.dart';
import '../constants/image_constants.dart';
import '../models/enums.dart';

/// An immutable mapping from `(PlayerColor, chess.PieceType)` to an
/// [ImageProvider] — i.e. a swappable piece set.
///
/// The default [PieceSet.chessDotCom] wraps the 12 `assets/pieces/*.png`
/// files bundled with this package. Consumers can subclass [PieceSet] to
/// point at their own assets, or use [PieceSet.fromAssetMap] for the
/// common case of a 12-entry asset map.
@immutable
abstract class PieceSet {
  /// Base const constructor; subclasses MUST provide one too so the
  /// top-level default value can be const.
  const PieceSet();

  /// Convenience constructor building a [PieceSet] from a 12-entry
  /// `Map<({PlayerColor color, chess.PieceType type}), ImageProvider>`.
  ///
  /// Throws [ArgumentError] when any of the 12 `(color, type)` keys is
  /// absent.
  const factory PieceSet.fromAssetMap(
    Map<({PlayerColor color, chess.PieceType type}), ImageProvider> map,
  ) = _MapBackedPieceSet;

  /// Returns the [ImageProvider] for a piece of [color] and [type].
  ///
  /// Called once per rendered piece per build — cheap implementations
  /// (returning a cached `const AssetImage(...)`) are strongly preferred.
  ImageProvider imageFor(PlayerColor color, chess.PieceType type);

  /// The bundled Chess.com-sourced PNG set shipped since 1.0.0.
  /// Default value for [AdvancedChessBoard.pieceSet].
  static const PieceSet chessDotCom = _ChessDotComPieceSet();
}

/// The canonical order of piece types for equality comparisons.
const List<chess.PieceType> _canonicalTypes = <chess.PieceType>[
  chess.PieceType.PAWN,
  chess.PieceType.KNIGHT,
  chess.PieceType.BISHOP,
  chess.PieceType.ROOK,
  chess.PieceType.QUEEN,
  chess.PieceType.KING,
];

/// The canonical order of player colors for equality comparisons.
const List<PlayerColor> _canonicalColors = <PlayerColor>[
  PlayerColor.white,
  PlayerColor.black,
];

class _ChessDotComPieceSet extends PieceSet {
  const _ChessDotComPieceSet();

  @override
  ImageProvider imageFor(final PlayerColor color, final chess.PieceType type) {
    if (color == PlayerColor.white) {
      switch (type) {
        case chess.PieceType.PAWN:
          return const AssetImage(PieceImages.whitePawn, package: packageName);
        case chess.PieceType.KNIGHT:
          return const AssetImage(
            PieceImages.whiteKnight,
            package: packageName,
          );
        case chess.PieceType.BISHOP:
          return const AssetImage(
            PieceImages.whiteBishop,
            package: packageName,
          );
        case chess.PieceType.ROOK:
          return const AssetImage(PieceImages.whiteRook, package: packageName);
        case chess.PieceType.QUEEN:
          return const AssetImage(
            PieceImages.whiteQueen,
            package: packageName,
          );
        case chess.PieceType.KING:
          return const AssetImage(PieceImages.whiteKing, package: packageName);
        default:
          throw ArgumentError('Unknown piece type: $type');
      }
    } else {
      switch (type) {
        case chess.PieceType.PAWN:
          return const AssetImage(PieceImages.blackPawn, package: packageName);
        case chess.PieceType.KNIGHT:
          return const AssetImage(
            PieceImages.blackKnight,
            package: packageName,
          );
        case chess.PieceType.BISHOP:
          return const AssetImage(
            PieceImages.blackBishop,
            package: packageName,
          );
        case chess.PieceType.ROOK:
          return const AssetImage(PieceImages.blackRook, package: packageName);
        case chess.PieceType.QUEEN:
          return const AssetImage(
            PieceImages.blackQueen,
            package: packageName,
          );
        case chess.PieceType.KING:
          return const AssetImage(PieceImages.blackKing, package: packageName);
        default:
          throw ArgumentError('Unknown piece type: $type');
      }
    }
  }
}

class _MapBackedPieceSet extends PieceSet {
  const _MapBackedPieceSet(this._map)
      : assert(_map.length == 12,
            'PieceSet.fromAssetMap requires exactly 12 entries');

  final Map<({PlayerColor color, chess.PieceType type}), ImageProvider> _map;

  @override
  ImageProvider imageFor(final PlayerColor color, final chess.PieceType type) {
    final key = (color: color, type: type);
    final provider = _map[key];
    if (provider == null) {
      throw ArgumentError(
        'PieceSet.fromAssetMap is missing entry for ($color, $type)',
      );
    }
    return provider;
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    if (other is! _MapBackedPieceSet) return false;
    for (final color in _canonicalColors) {
      for (final type in _canonicalTypes) {
        final key = (color: color, type: type);
        if (_map[key] != other._map[key]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    var hash = 0;
    for (final color in _canonicalColors) {
      for (final type in _canonicalTypes) {
        final key = (color: color, type: type);
        hash = Object.hash(hash, _map[key]);
      }
    }
    return hash;
  }
}
