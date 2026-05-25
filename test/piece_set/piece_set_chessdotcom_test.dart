// Feature: chess-board-ux-enhancements, Property P1.6:
// PieceSet.chessDotCom.imageFor(color, type) equals
// const AssetImage(PieceImages.<...>, package: 'advanced_chess_board')
// for every one of the 12 (color, type) pairs.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/constants/global_constants.dart';
import 'package:advanced_chess_board/src/constants/image_constants.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieceSet.chessDotCom resolves to bundled assets', () {
    final expectedPaths = <({PlayerColor color, chess.PieceType type}), String>{
      (color: PlayerColor.white, type: chess.PieceType.PAWN):
          PieceImages.whitePawn,
      (color: PlayerColor.white, type: chess.PieceType.KNIGHT):
          PieceImages.whiteKnight,
      (color: PlayerColor.white, type: chess.PieceType.BISHOP):
          PieceImages.whiteBishop,
      (color: PlayerColor.white, type: chess.PieceType.ROOK):
          PieceImages.whiteRook,
      (color: PlayerColor.white, type: chess.PieceType.QUEEN):
          PieceImages.whiteQueen,
      (color: PlayerColor.white, type: chess.PieceType.KING):
          PieceImages.whiteKing,
      (color: PlayerColor.black, type: chess.PieceType.PAWN):
          PieceImages.blackPawn,
      (color: PlayerColor.black, type: chess.PieceType.KNIGHT):
          PieceImages.blackKnight,
      (color: PlayerColor.black, type: chess.PieceType.BISHOP):
          PieceImages.blackBishop,
      (color: PlayerColor.black, type: chess.PieceType.ROOK):
          PieceImages.blackRook,
      (color: PlayerColor.black, type: chess.PieceType.QUEEN):
          PieceImages.blackQueen,
      (color: PlayerColor.black, type: chess.PieceType.KING):
          PieceImages.blackKing,
    };

    for (final entry in expectedPaths.entries) {
      final color = entry.key.color;
      final type = entry.key.type;
      final expectedPath = entry.value;

      test('chessDotCom.imageFor($color, $type) == AssetImage($expectedPath)',
          () {
        final provider = PieceSet.chessDotCom.imageFor(color, type);
        expect(provider, isA<AssetImage>());
        final assetImage = provider as AssetImage;
        expect(assetImage.assetName, equals(expectedPath));
        expect(assetImage.package, equals(packageName));
      });
    }

    test('all 12 pairs return non-null providers', () {
      for (final color in PlayerColor.values) {
        for (final type in const <chess.PieceType>[
          chess.PieceType.PAWN,
          chess.PieceType.KNIGHT,
          chess.PieceType.BISHOP,
          chess.PieceType.ROOK,
          chess.PieceType.QUEEN,
          chess.PieceType.KING,
        ]) {
          final provider = PieceSet.chessDotCom.imageFor(color, type);
          expect(provider, isNotNull);
        }
      }
    });
  });
}
