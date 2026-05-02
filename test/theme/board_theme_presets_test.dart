// Feature: chess-board-ux-enhancements, Properties P1.4, P1.5:
// P1.4: BoardTheme.classicGreen pins the 3.0.0 palette bit-for-bit.
// P1.5: All 10 pairwise combinations of the 5 presets are distinct.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardTheme presets', () {
    // P1.4: classicGreen pins 3.0.0 palette.
    test('classicGreen.lightSquareColor == Color(0xFFEBECD0)', () {
      expect(
        BoardTheme.classicGreen.lightSquareColor,
        equals(const Color(0xFFEBECD0)),
      );
    });

    test('classicGreen.darkSquareColor == Color(0xFF739552)', () {
      expect(
        BoardTheme.classicGreen.darkSquareColor,
        equals(const Color(0xFF739552)),
      );
    });

    test('classicGreen == const BoardTheme()', () {
      expect(BoardTheme.classicGreen, equals(const BoardTheme()));
    });

    // P1.5: All 10 pairwise combinations of the 5 presets are distinct.
    test('all 10 pairwise preset pairs are distinct', () {
      final presets = <String, BoardTheme>{
        'classicGreen': BoardTheme.classicGreen,
        'brown': BoardTheme.brown,
        'blue': BoardTheme.blue,
        'purple': BoardTheme.purple,
        'monochrome': BoardTheme.monochrome,
      };
      final names = presets.keys.toList();
      for (var i = 0; i < names.length; i++) {
        for (var j = i + 1; j < names.length; j++) {
          final nameA = names[i];
          final nameB = names[j];
          expect(
            presets[nameA] == presets[nameB],
            isFalse,
            reason: '$nameA and $nameB should be distinct presets',
          );
        }
      }
    });

    // Verify each preset's light/dark square colors.
    test('brown preset has correct colors', () {
      expect(
        BoardTheme.brown.lightSquareColor,
        equals(const Color(0xFFF0D9B5)),
      );
      expect(
        BoardTheme.brown.darkSquareColor,
        equals(const Color(0xFFB58863)),
      );
    });

    test('blue preset has correct colors', () {
      expect(
        BoardTheme.blue.lightSquareColor,
        equals(const Color(0xFFDEE3E6)),
      );
      expect(
        BoardTheme.blue.darkSquareColor,
        equals(const Color(0xFF8CA2AD)),
      );
    });

    test('purple preset has correct colors', () {
      expect(
        BoardTheme.purple.lightSquareColor,
        equals(const Color(0xFFE8E3F3)),
      );
      expect(
        BoardTheme.purple.darkSquareColor,
        equals(const Color(0xFF8476B5)),
      );
    });

    test('monochrome preset has correct colors', () {
      expect(
        BoardTheme.monochrome.lightSquareColor,
        equals(const Color(0xFFEEEEEE)),
      );
      expect(
        BoardTheme.monochrome.darkSquareColor,
        equals(const Color(0xFF606060)),
      );
    });
  });
}
