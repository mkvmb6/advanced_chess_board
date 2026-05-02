// Feature: chess-board-ux-enhancements, Property P2.8:
// Draggable.feedback width = min(squareSize * kMaxFeedbackScale,
//                                squareSize + kMaxFeedbackOverflowPx),
// preserved from 3.0.0.

import 'dart:math' as math;

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/widgets/chess_piece_widget.dart';
import 'package:advanced_chess_board/src/constants/global_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Preservation P2.8: drag feedback clamping preserved', () {
    for (final double boardSize in <double>[200, 320, 400]) {
      final squareSize = boardSize / 8;
      final expectedFeedbackSize = math.min(
        squareSize * kMaxFeedbackScale,
        squareSize + kMaxFeedbackOverflowPx,
      );

      testWidgets(
        'P2.8: feedback size at boardSize=$boardSize is $expectedFeedbackSize',
        (final WidgetTester tester) async {
          final controller = ChessBoardController();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SizedBox(
                  width: boardSize,
                  height: boardSize,
                  child: AdvancedChessBoard(controller: controller),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Find Draggable widgets and check their feedback size.
          final draggables = tester.widgetList<Draggable<String>>(
            find.byType(Draggable<String>),
          );

          for (final draggable in draggables) {
            final feedback = draggable.feedback;
            if (feedback is ChessPieceWidget) {
              expect(
                feedback.squareSize,
                closeTo(expectedFeedbackSize, 0.5),
                reason:
                    'Feedback size should be clamped at boardSize=$boardSize',
              );
            }
          }
        },
      );
    }
  });
}
