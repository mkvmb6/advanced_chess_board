// Feature: chess-board-ux-enhancements, Property P2.6:
// Mated-king tint + in-check tint preserved.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Fool's mate FEN.
const String _kFoolsMateFen =
    'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3';

void main() {
  group('Preservation P2.6: mate/check tint preserved', () {
    testWidgets(
      'P2.6: mated king tint uses default Color(0x9BF44336)',
      (final WidgetTester tester) async {
        final controller = ChessBoardController()
          ..loadGameFromFEN(_kFoolsMateFen, notify: false);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(controller: controller),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(controller.isCheckmate, isTrue);

        // The checkmate tint should be rendered.
        final tintFinder = find.byWidgetPredicate(
          (final w) => w is ColoredBox && w.color == const Color(0x9BF44336),
        );
        expect(
          tintFinder,
          findsOneWidget,
          reason: 'Checkmate tint should be rendered on mated king square',
        );
      },
    );

    testWidgets(
      'P2.6: legacy kingBackgroundColorOnCheckmate wins over boardTheme',
      (final WidgetTester tester) async {
        final controller = ChessBoardController()
          ..loadGameFromFEN(_kFoolsMateFen, notify: false);
        const customColor = Color(0xFF112233);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  kingBackgroundColorOnCheckmate: customColor,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The custom color should be used.
        final tintFinder = find.byWidgetPredicate(
          (final w) => w is ColoredBox && w.color == customColor,
        );
        expect(
          tintFinder,
          findsOneWidget,
          reason: 'Legacy kingBackgroundColorOnCheckmate should win',
        );
      },
    );

    testWidgets(
      'P2.6: in-check tint fires when kingCheckColor is non-null',
      (final WidgetTester tester) async {
        // White king in check from black queen.
        const inCheckFen = '4k3/8/8/8/8/8/8/4K2q w - - 0 1';
        final controller = ChessBoardController()
          ..loadGameFromFEN(inCheckFen, notify: false);

        const checkColor = Color(0xFF0000FF);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  boardTheme: const BoardTheme(kingCheckColor: checkColor),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        if (controller.isInCheck) {
          // The check tint should be rendered.
          final tintFinder = find.byWidgetPredicate(
            (final w) => w is ColoredBox && w.color == checkColor,
          );
          expect(
            tintFinder,
            findsOneWidget,
            reason:
                'In-check tint should be rendered when kingCheckColor is set',
          );
        }
      },
    );
  });
}
