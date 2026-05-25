// Feature: chess-board-ux-enhancements, Property P1.1:
// PieceSet's `==` / `hashCode` respect the 12 `(color, type) → ImageProvider`
// entries of the set; reference-equal const subclasses compare equal;
// map-backed sets compare equal iff the 12 entries are map-equal.

import 'dart:typed_data';

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<({PlayerColor color, chess.PieceType type}), ImageProvider> _buildMap(
    final ImageProvider provider) {
  final map = <({PlayerColor color, chess.PieceType type}), ImageProvider>{};
  for (final color in PlayerColor.values) {
    for (final type in const <chess.PieceType>[
      chess.PieceType.PAWN,
      chess.PieceType.KNIGHT,
      chess.PieceType.BISHOP,
      chess.PieceType.ROOK,
      chess.PieceType.QUEEN,
      chess.PieceType.KING,
    ]) {
      map[(color: color, type: type)] = provider;
    }
  }
  return map;
}

void main() {
  group('PieceSet equality and hashCode', () {
    test('two PieceSet.chessDotCom are equal', () {
      const a = PieceSet.chessDotCom;
      const b = PieceSet.chessDotCom;
      expect(a == b, isTrue);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('two fromAssetMap with equal maps are equal', () {
      final provider = MemoryImage(Uint8List.fromList(<int>[0, 0, 0, 0]));
      final map1 = _buildMap(provider);
      final map2 = _buildMap(provider);
      final set1 = PieceSet.fromAssetMap(map1);
      final set2 = PieceSet.fromAssetMap(map2);
      expect(set1 == set2, isTrue);
      expect(set1.hashCode, equals(set2.hashCode));
    });

    test('fromAssetMap with different providers are not equal', () {
      final provider1 = MemoryImage(Uint8List.fromList(<int>[0, 0, 0, 0]));
      final provider2 = MemoryImage(Uint8List.fromList(<int>[1, 1, 1, 1]));
      final map1 = _buildMap(provider1);
      final map2 = _buildMap(provider2);
      final set1 = PieceSet.fromAssetMap(map1);
      final set2 = PieceSet.fromAssetMap(map2);
      expect(set1 == set2, isFalse);
    });

    test('chessDotCom != fromAssetMap', () {
      final provider = MemoryImage(Uint8List.fromList(<int>[0, 0, 0, 0]));
      final map = _buildMap(provider);
      final customSet = PieceSet.fromAssetMap(map);
      expect(PieceSet.chessDotCom == customSet, isFalse);
    });

    test('single-entry difference flips equality', () {
      final provider1 = MemoryImage(Uint8List.fromList(<int>[0, 0, 0, 0]));
      final provider2 = MemoryImage(Uint8List.fromList(<int>[1, 1, 1, 1]));
      final map1 = _buildMap(provider1);
      final map2 = _buildMap(provider1);
      // Change one entry in map2.
      map2[(color: PlayerColor.white, type: chess.PieceType.KING)] = provider2;
      final set1 = PieceSet.fromAssetMap(map1);
      final set2 = PieceSet.fromAssetMap(map2);
      expect(set1 == set2, isFalse);
    });
  });
}
