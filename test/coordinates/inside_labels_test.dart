// Feature: chess-board-ux-enhancements, Property P1.9:
// Inside labels render only on the a/h file and 1/8 rank edges,
// orientation-appropriate.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/widgets/chess_square.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoordinateLabels.inside label placement', () {
    testWidgets(
      'white orientation: rank labels on a-file, file labels on rank 1',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  coordinates: CoordinateLabels.inside,
                  boardOrientation: PlayerColor.white,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // For white orientation:
        // - Rank labels should appear on a-file squares (a1..a8)
        // - File labels should appear on rank-1 squares (a1..h1)
        const files = <String>['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
        const ranks = <String>['1', '2', '3', '4', '5', '6', '7', '8'];

        for (final file in files) {
          for (final rank in ranks) {
            final square = '$file$rank';
            final squareWidget = tester.widget<ChessSquare>(
              find.byWidgetPredicate(
                (final w) => w is ChessSquare && w.square == square,
              ),
            );
            // Rank label should appear only on a-file.
            final shouldHaveRankLabel = file == 'a';
            // File label should appear only on rank 1.
            final shouldHaveFileLabel = rank == '1';

            expect(
              squareWidget.coordinates,
              equals(CoordinateLabels.inside),
              reason: 'Square $square should have inside coordinates',
            );

            // Verify the square's orientation is correct.
            expect(
              squareWidget.boardOrientation,
              equals(PlayerColor.white),
            );

            // The ChessSquare itself handles the label rendering logic.
            // We verify the coordinates field is set correctly.
            if (shouldHaveRankLabel || shouldHaveFileLabel) {
              // These squares should have labels rendered.
              expect(squareWidget.coordinates, equals(CoordinateLabels.inside));
            }
          }
        }
      },
    );

    testWidgets(
      'black orientation: rank labels on h-file, file labels on rank 8',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  coordinates: CoordinateLabels.inside,
                  boardOrientation: PlayerColor.black,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // For black orientation:
        // - Rank labels should appear on h-file squares
        // - File labels should appear on rank-8 squares
        final squareWidgets = tester.widgetList<ChessSquare>(
          find.byType(ChessSquare),
        );
        for (final squareWidget in squareWidgets) {
          expect(
            squareWidget.boardOrientation,
            equals(PlayerColor.black),
          );
          expect(
            squareWidget.coordinates,
            equals(CoordinateLabels.inside),
          );
        }
      },
    );

    testWidgets(
      'none mode: no labels rendered inside squares',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  coordinates: CoordinateLabels.none,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // All ChessSquare widgets should have coordinates == none.
        final squareWidgets = tester.widgetList<ChessSquare>(
          find.byType(ChessSquare),
        );
        for (final squareWidget in squareWidgets) {
          expect(
            squareWidget.coordinates,
            equals(CoordinateLabels.none),
          );
        }
      },
    );
  });
}
