// Feature: chess-board-ux-enhancements, Property P1.17:
// Controller undo/reset/loadGameFromFEN never fires SoundPack.play.

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
  group('No audio on undo/reset/loadGameFromFEN', () {
    testWidgets(
      'undo does not fire SoundPack.play',
      (final WidgetTester tester) async {
        final counter = _Counter();
        final pack = _CountingSoundPack(counter);
        final controller = ChessBoardController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  soundPack: pack,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Make a move first.
        controller.makeMove(from: 'e2', to: 'e4');
        await tester.pumpAndSettle();

        final before = counter.value;

        // Undo should not fire audio.
        controller.undo();
        await tester.pumpAndSettle();

        expect(
          counter.value,
          equals(before),
          reason: 'undo must not fire SoundPack.play',
        );
      },
    );

    testWidgets(
      'resetBoard does not fire SoundPack.play',
      (final WidgetTester tester) async {
        final counter = _Counter();
        final pack = _CountingSoundPack(counter);
        final controller = ChessBoardController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  soundPack: pack,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final before = counter.value;

        // Reset should not fire audio.
        controller.resetBoard();
        await tester.pumpAndSettle();

        expect(
          counter.value,
          equals(before),
          reason: 'resetBoard must not fire SoundPack.play',
        );
      },
    );

    testWidgets(
      'loadGameFromFEN does not fire SoundPack.play',
      (final WidgetTester tester) async {
        final counter = _Counter();
        final pack = _CountingSoundPack(counter);
        final controller = ChessBoardController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  soundPack: pack,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final before = counter.value;

        // loadGameFromFEN should not fire audio.
        controller.loadGameFromFEN(
          'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        );
        await tester.pumpAndSettle();

        expect(
          counter.value,
          equals(before),
          reason: 'loadGameFromFEN must not fire SoundPack.play',
        );
      },
    );

    testWidgets(
      'notify:false mutations do not fire SoundPack.play',
      (final WidgetTester tester) async {
        final counter = _Counter();
        final pack = _CountingSoundPack(counter);
        final controller = ChessBoardController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  soundPack: pack,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final before = counter.value;

        controller.resetBoard(notify: false);
        controller.loadGameFromFEN(
          'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
          notify: false,
        );
        controller.undo(notify: false);

        await tester.pumpAndSettle();

        expect(
          counter.value,
          equals(before),
          reason: 'notify:false mutations must not fire SoundPack.play',
        );
      },
    );
  });
}
