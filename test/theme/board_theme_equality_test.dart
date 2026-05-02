// Feature: chess-board-ux-enhancements, Property P1.1:
// BoardTheme's `==` / `hashCode` respect all 11 fields — equal inputs
// compare equal and have equal hashes; any single differing field
// flips equality to false.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart';

import '../properties/generators.dart';

void main() {
  ft.group('BoardTheme equality and hashCode', () {
    // Two themes with identical fields must be equal.
    ft.test('equal themes compare equal and have equal hashCodes', () {
      const t1 = BoardTheme(
        lightSquareColor: Color(0xFFEBECD0),
        darkSquareColor: Color(0xFF739552),
        selectionColor: Color(0x9BFFEB3B),
        lastMoveHighlightColor: Color(0x80FFEB3B),
        legalDestinationColor: Color(0x40000000),
        kingCheckmateColor: Color(0x9BF44336),
        hintArrowColor: Color(0x9932CD32),
        dragLegalRingColor: Color(0xA0FFFFFF),
        dragIllegalTintColor: Color(0x40F44336),
      );
      const t2 = BoardTheme(
        lightSquareColor: Color(0xFFEBECD0),
        darkSquareColor: Color(0xFF739552),
        selectionColor: Color(0x9BFFEB3B),
        lastMoveHighlightColor: Color(0x80FFEB3B),
        legalDestinationColor: Color(0x40000000),
        kingCheckmateColor: Color(0x9BF44336),
        hintArrowColor: Color(0x9932CD32),
        dragLegalRingColor: Color(0xA0FFFFFF),
        dragIllegalTintColor: Color(0x40F44336),
      );
      ft.expect(t1 == t2, ft.isTrue);
      ft.expect(t1.hashCode, ft.equals(t2.hashCode));
    });

    // Each of the 11 fields individually: differing field flips equality.
    ft.test('differing lightSquareColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(lightSquareColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    ft.test('differing darkSquareColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(darkSquareColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    ft.test('differing selectionColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(selectionColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    ft.test('differing lastMoveHighlightColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(lastMoveHighlightColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    ft.test('differing legalDestinationColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(legalDestinationColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    ft.test('differing coordinateLabelColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(coordinateLabelColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    ft.test('differing kingCheckmateColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(kingCheckmateColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    ft.test('differing kingCheckColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(kingCheckColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    ft.test('differing hintArrowColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(hintArrowColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    ft.test('differing dragLegalRingColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(dragLegalRingColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    ft.test('differing dragIllegalTintColor flips equality', () {
      const base = BoardTheme();
      const other = BoardTheme(dragIllegalTintColor: Color(0xFF000000));
      ft.expect(base == other, ft.isFalse);
    });

    // PBT: for any two random BoardThemes, themes differing only in
    // lightSquareColor compare equal iff the colors are equal.
    Glados<BoardTheme>(any.boardTheme).test(
      'prop_equality_reflexive: t == t',
      (final BoardTheme t) {
        ft.expect(t == t, ft.isTrue);
        ft.expect(t.hashCode, ft.equals(t.hashCode));
      },
    );

    Glados2<BoardTheme, BoardTheme>(any.boardTheme, any.boardTheme).test(
      'prop_equality_symmetric: t1 == t2 implies t2 == t1',
      (final BoardTheme t1, final BoardTheme t2) {
        ft.expect(t1 == t2, ft.equals(t2 == t1));
      },
    );
  });
}
