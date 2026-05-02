// Feature: chess-board-ux-enhancements, Property P2.3:
// enableMoves: false is render-only under every 3.1.0 parameter
// combination — no move, no audio, no drag indicator.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _Counter {
  int value = 0;
}

class _CountingSoundPack extends SoundPack {
  const _CountingSoundPack(this.counter);
  final _Counter counter;

  @override
  Future<void> play(final SoundEvent e) async {
    counter.value += 1;
  }
}

void main() {
  group('Preservation P2.3: enableMoves:false preserved under 3.1.0', () {
    testWidgets(
      'P2.3: taps do not mutate FEN with 3.1.0 params',
      (final WidgetTester tester) async {
        final counter = _Counter();
        final pack = _CountingSoundPack(counter);
        final controller = ChessBoardController();
        final startingFen = controller.fen;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  enableMoves: false,
                  boardTheme: BoardTheme.brown,
                  coordinates: CoordinateLabels.outside,
                  soundPack: pack,
                  hintArrow: const HintArrow(
                    startSquare: 'g1',
                    endSquare: 'f3',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap every square.
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        for (var row = 0; row < 8; row++) {
          for (var col = 0; col < 8; col++) {
            final dx = col * squareSize + squareSize / 2;
            final dy = row * squareSize + squareSize / 2;
            await tester.tapAt(Offset(dx, dy));
          }
        }
        await tester.pumpAndSettle();

        expect(controller.fen, equals(startingFen));
        expect(counter.value, equals(0));
      },
    );
  });
}
