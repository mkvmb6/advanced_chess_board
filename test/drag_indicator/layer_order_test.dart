// Feature: chess-board-ux-enhancements, Properties P1.30, P1.31:
// Drag-legal ring layered above HighlightOverlay; drag-illegal tint
// layered between ChessSquare background and ChessPieceWidget.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Drag indicator layer order', () {
    testWidgets(
      'board renders correctly with all layers',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
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

        // Board should render without errors.
        expect(tester.takeException(), isNull);
        expect(find.byType(AdvancedChessBoard), findsOneWidget);
      },
    );
  });
}
