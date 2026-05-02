// Feature: chess-board-ux-enhancements, Property P1.20:
// Default AdvancedChessBoard uses const SilentSoundPack; play(e)
// returns an already-resolved Future<void> with no side effect.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SilentSoundPack default', () {
    test('SilentSoundPack.play returns a resolved Future', () async {
      const pack = SilentSoundPack();
      // Should complete without error.
      await expectLater(pack.play(SoundEvent.move), completes);
      await expectLater(pack.play(SoundEvent.capture), completes);
      await expectLater(pack.play(SoundEvent.check), completes);
      await expectLater(pack.play(SoundEvent.castle), completes);
      await expectLater(pack.play(SoundEvent.promote), completes);
      await expectLater(pack.play(SoundEvent.gameEnd), completes);
    });

    test('two const SilentSoundPack are identical', () {
      const a = SilentSoundPack();
      const b = SilentSoundPack();
      expect(identical(a, b), isTrue);
    });

    testWidgets(
      'default AdvancedChessBoard uses SilentSoundPack',
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

        // Find the AdvancedChessBoard widget and check its soundPack.
        final boardWidget = tester.widget<AdvancedChessBoard>(
          find.byType(AdvancedChessBoard),
        );
        expect(boardWidget.soundPack, isA<SilentSoundPack>());
        expect(
          identical(boardWidget.soundPack, const SilentSoundPack()),
          isTrue,
        );
      },
    );
  });
}
