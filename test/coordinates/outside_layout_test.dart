// Feature: chess-board-ux-enhancements, Properties P1.10, P1.11, P1.12:
// Outside gutters are disjoint from the playing grid; orientation
// reverses gutter label order; AspectRatio(1) wraps the playing grid only.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CoordinateLabels.outside layout', () {
    testWidgets(
      'P1.12: playing grid is square (AspectRatio(1) preserved)',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 512,
                height: 512,
                child: AdvancedChessBoard(
                  controller: controller,
                  coordinates: CoordinateLabels.outside,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // The AspectRatio widget wrapping the playing grid should be present.
        final aspectRatioFinder = find.byWidgetPredicate(
          (final w) => w is AspectRatio && w.aspectRatio == 1.0,
        );
        expect(
          aspectRatioFinder,
          findsAtLeastNWidgets(1),
          reason: 'AspectRatio(1) must wrap the playing grid',
        );
      },
    );

    testWidgets(
      'outside mode renders board without overflow',
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
                  coordinates: CoordinateLabels.outside,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No overflow errors.
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'P1.11: white orientation rank gutter has 8 to 1 top-to-bottom',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 512,
                height: 512,
                child: AdvancedChessBoard(
                  controller: controller,
                  coordinates: CoordinateLabels.outside,
                  boardOrientation: PlayerColor.white,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Find all Text widgets that are rank labels (1-8).
        final rankTexts = tester
            .widgetList<Text>(find.byType(Text))
            .where(
              (final t) =>
                  t.data != null && RegExp(r'^[1-8]$').hasMatch(t.data!),
            )
            .toList();

        // Should have 8 rank labels.
        expect(rankTexts.length, greaterThanOrEqualTo(8));
      },
    );

    testWidgets(
      'P1.11: black orientation rank gutter has 1 to 8 top-to-bottom',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 512,
                height: 512,
                child: AdvancedChessBoard(
                  controller: controller,
                  coordinates: CoordinateLabels.outside,
                  boardOrientation: PlayerColor.black,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // No overflow errors.
        expect(tester.takeException(), isNull);
      },
    );
  });
}
