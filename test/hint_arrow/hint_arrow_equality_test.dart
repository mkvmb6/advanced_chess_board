// Feature: chess-board-ux-enhancements, Property P1.1:
// HintArrow's `==` / `hashCode` respect all three fields.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart';

import '../properties/generators.dart';

void main() {
  ft.group('HintArrow equality and hashCode', () {
    ft.test('equal HintArrows compare equal', () {
      const a = HintArrow(startSquare: 'e2', endSquare: 'e4');
      const b = HintArrow(startSquare: 'e2', endSquare: 'e4');
      ft.expect(a == b, ft.isTrue);
      ft.expect(a.hashCode, ft.equals(b.hashCode));
    });

    ft.test('differing startSquare flips equality', () {
      const a = HintArrow(startSquare: 'e2', endSquare: 'e4');
      const b = HintArrow(startSquare: 'd2', endSquare: 'e4');
      ft.expect(a == b, ft.isFalse);
    });

    ft.test('differing endSquare flips equality', () {
      const a = HintArrow(startSquare: 'e2', endSquare: 'e4');
      const b = HintArrow(startSquare: 'e2', endSquare: 'e5');
      ft.expect(a == b, ft.isFalse);
    });

    ft.test('differing duration flips equality', () {
      const a = HintArrow(
        startSquare: 'e2',
        endSquare: 'e4',
        duration: Duration(seconds: 2),
      );
      const b = HintArrow(
        startSquare: 'e2',
        endSquare: 'e4',
        duration: Duration(seconds: 3),
      );
      ft.expect(a == b, ft.isFalse);
    });

    ft.test('null duration vs non-null duration flips equality', () {
      const a = HintArrow(startSquare: 'e2', endSquare: 'e4');
      const b = HintArrow(
        startSquare: 'e2',
        endSquare: 'e4',
        duration: Duration(seconds: 2),
      );
      ft.expect(a == b, ft.isFalse);
    });

    // PBT: reflexivity.
    Glados<HintArrow>(any.hintArrow).test(
      'prop_equality_reflexive: h == h',
      (final HintArrow h) {
        ft.expect(h == h, ft.isTrue);
        ft.expect(h.hashCode, ft.equals(h.hashCode));
      },
    );

    // PBT: symmetry.
    Glados2<HintArrow, HintArrow>(any.hintArrow, any.hintArrow).test(
      'prop_equality_symmetric: h1 == h2 implies h2 == h1',
      (final HintArrow h1, final HintArrow h2) {
        ft.expect(h1 == h2, ft.equals(h2 == h1));
      },
    );
  });
}
