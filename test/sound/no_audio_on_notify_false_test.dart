// Feature: chess-board-ux-enhancements, Property P1.18:
// controller.makeMove(..., notify: false) never fires SoundPack.play,
// because notify-false moves don't flow through _makeMove.

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
  group('No audio on makeMove notify:false', () {
    testWidgets(
      'P1.18: controller.makeMove(notify:false) does not fire SoundPack.play',
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

        // Direct controller.makeMove with notify:false bypasses the widget's
        // _makeMove path, so no audio should fire.
        controller.makeMove(from: 'e2', to: 'e4', notify: false);
        controller.makeMove(from: 'e7', to: 'e5', notify: false);
        controller.makeMove(from: 'g1', to: 'f3', notify: false);

        await tester.pumpAndSettle();

        expect(
          counter.value,
          equals(before),
          reason:
              'controller.makeMove(notify:false) must not fire SoundPack.play',
        );
      },
    );
  });
}
