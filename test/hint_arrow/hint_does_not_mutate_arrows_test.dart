// Feature: chess-board-ux-enhancements, Property P1.27:
// The `arrows:` list passed to AdvancedChessBoard is never mutated by
// any hint-arrow lifecycle transition.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hint arrow does not mutate arrows list', () {
    testWidgets(
      'P1.27: arrows list is not mutated by hint lifecycle',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        final arrows = <ChessArrow>[
          ChessArrow(startSquare: 'e2', endSquare: 'e4'),
          ChessArrow(startSquare: 'e7', endSquare: 'e5'),
        ];
        final originalArrow0 = arrows[0];
        final originalArrow1 = arrows[1];
        final originalLength = arrows.length;

        const hint1 = HintArrow(startSquare: 'g1', endSquare: 'f3');
        const hint2 = HintArrow(startSquare: 'd2', endSquare: 'd4');

        // Pump with hint1.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  arrows: arrows,
                  hintArrow: hint1,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify arrows list is unchanged.
        expect(arrows.length, equals(originalLength));
        expect(identical(arrows[0], originalArrow0), isTrue);
        expect(identical(arrows[1], originalArrow1), isTrue);

        // Replace hint.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  arrows: arrows,
                  hintArrow: hint2,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify arrows list is still unchanged.
        expect(arrows.length, equals(originalLength));
        expect(identical(arrows[0], originalArrow0), isTrue);
        expect(identical(arrows[1], originalArrow1), isTrue);

        // Dismiss hint.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  arrows: arrows,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify arrows list is still unchanged.
        expect(arrows.length, equals(originalLength));
        expect(identical(arrows[0], originalArrow0), isTrue);
        expect(identical(arrows[1], originalArrow1), isTrue);
      },
    );
  });
}
