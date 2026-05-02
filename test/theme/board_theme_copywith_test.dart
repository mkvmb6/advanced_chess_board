// Feature: chess-board-ux-enhancements, Property P1.2:
// BoardTheme.copyWith preserves unreplaced fields; any single-field
// replacement updates only that field; the _unset sentinel path for
// nullable fields works correctly.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart';

import '../properties/generators.dart';

void main() {
  ft.group('BoardTheme.copyWith', () {
    // copyWith with no args returns an equal theme.
    ft.test('copyWith with no args returns equal theme', () {
      const t = BoardTheme(
        lightSquareColor: Color(0xFFEBECD0),
        darkSquareColor: Color(0xFF739552),
        coordinateLabelColor: Color(0xFF123456),
        kingCheckColor: Color(0xFF654321),
      );
      final copy = t.copyWith();
      ft.expect(copy, ft.equals(t));
    });

    // copyWith replaces lightSquareColor only.
    ft.test('copyWith replaces lightSquareColor only', () {
      const t = BoardTheme();
      const newColor = Color(0xFF112233);
      final copy = t.copyWith(lightSquareColor: newColor);
      ft.expect(copy.lightSquareColor, ft.equals(newColor));
      ft.expect(copy.darkSquareColor, ft.equals(t.darkSquareColor));
      ft.expect(copy.selectionColor, ft.equals(t.selectionColor));
      ft.expect(
        copy.lastMoveHighlightColor,
        ft.equals(t.lastMoveHighlightColor),
      );
      ft.expect(
        copy.legalDestinationColor,
        ft.equals(t.legalDestinationColor),
      );
      ft.expect(
        copy.coordinateLabelColor,
        ft.equals(t.coordinateLabelColor),
      );
      ft.expect(copy.kingCheckmateColor, ft.equals(t.kingCheckmateColor));
      ft.expect(copy.kingCheckColor, ft.equals(t.kingCheckColor));
      ft.expect(copy.hintArrowColor, ft.equals(t.hintArrowColor));
      ft.expect(copy.dragLegalRingColor, ft.equals(t.dragLegalRingColor));
      ft.expect(copy.dragIllegalTintColor, ft.equals(t.dragIllegalTintColor));
    });

    // _unset sentinel: copyWith(coordinateLabelColor: null) explicitly sets null.
    ft.test('copyWith(coordinateLabelColor: null) explicitly sets null', () {
      const t = BoardTheme(coordinateLabelColor: Color(0xFF123456));
      final copy = t.copyWith(coordinateLabelColor: null);
      ft.expect(copy.coordinateLabelColor, ft.isNull);
    });

    // _unset sentinel: copyWith() without coordinateLabelColor leaves it unchanged.
    ft.test('copyWith() without coordinateLabelColor leaves it unchanged', () {
      const t = BoardTheme(coordinateLabelColor: Color(0xFF123456));
      final copy = t.copyWith();
      ft.expect(copy.coordinateLabelColor, ft.equals(const Color(0xFF123456)));
    });

    // _unset sentinel: copyWith(kingCheckColor: null) explicitly sets null.
    ft.test('copyWith(kingCheckColor: null) explicitly sets null', () {
      const t = BoardTheme(kingCheckColor: Color(0xFF654321));
      final copy = t.copyWith(kingCheckColor: null);
      ft.expect(copy.kingCheckColor, ft.isNull);
    });

    // _unset sentinel: copyWith() without kingCheckColor leaves it unchanged.
    ft.test('copyWith() without kingCheckColor leaves it unchanged', () {
      const t = BoardTheme(kingCheckColor: Color(0xFF654321));
      final copy = t.copyWith();
      ft.expect(copy.kingCheckColor, ft.equals(const Color(0xFF654321)));
    });

    // PBT: for any BoardTheme, copyWith with no args returns an equal theme.
    Glados<BoardTheme>(any.boardTheme).test(
      'prop_copywith_no_args_returns_equal_theme',
      (final BoardTheme t) {
        final copy = t.copyWith();
        ft.expect(copy, ft.equals(t));
      },
    );

    // PBT: for any BoardTheme and any color, copyWith(lightSquareColor: c)
    // updates only that field.
    Glados<BoardTheme>(any.boardTheme).test(
      'prop_copywith_lightSquareColor_updates_only_that_field',
      (final BoardTheme base) {
        const c = Color(0xFF112233);
        final copy = base.copyWith(lightSquareColor: c);
        ft.expect(copy.lightSquareColor, ft.equals(c));
        ft.expect(copy.darkSquareColor, ft.equals(base.darkSquareColor));
        ft.expect(copy.selectionColor, ft.equals(base.selectionColor));
        ft.expect(
          copy.lastMoveHighlightColor,
          ft.equals(base.lastMoveHighlightColor),
        );
        ft.expect(
          copy.legalDestinationColor,
          ft.equals(base.legalDestinationColor),
        );
        ft.expect(
          copy.coordinateLabelColor,
          ft.equals(base.coordinateLabelColor),
        );
        ft.expect(copy.kingCheckmateColor, ft.equals(base.kingCheckmateColor));
        ft.expect(copy.kingCheckColor, ft.equals(base.kingCheckColor));
        ft.expect(copy.hintArrowColor, ft.equals(base.hintArrowColor));
        ft.expect(copy.dragLegalRingColor, ft.equals(base.dragLegalRingColor));
        ft.expect(
          copy.dragIllegalTintColor,
          ft.equals(base.dragIllegalTintColor),
        );
      },
    );
  });
}
