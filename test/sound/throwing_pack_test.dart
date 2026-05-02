// Feature: chess-board-ux-enhancements, Property P1.19:
// Sync or async throws from SoundPack.play are swallowed; the board's
// next build runs normally and no exception propagates to the tester.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingSoundPack extends SoundPack {
  _ThrowingSoundPack({required this.throwSync});
  final bool throwSync;

  @override
  Future<void> play(final SoundEvent e) {
    if (throwSync) {
      throw StateError('sync boom from SoundPack.play');
    }
    return Future<void>.error(StateError('async boom from SoundPack.play'));
  }
}

void main() {
  group('Throwing SoundPack is swallowed', () {
    testWidgets(
      'P1.19: synchronous throw from SoundPack.play does not propagate',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        final pack = _ThrowingSoundPack(throwSync: true);

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

        // Tap e2 to select, then tap e4 to move — triggers _makeMove.
        const boardSize = 400.0;
        const squareSize = boardSize / 8;
        // e2 is col 4 (e=5th file, index 4), row 6 (rank 2 from top in white view).
        const e2 = Offset(
          4 * squareSize + squareSize / 2,
          6 * squareSize + squareSize / 2,
        );
        const e4 = Offset(
          4 * squareSize + squareSize / 2,
          4 * squareSize + squareSize / 2,
        );

        await tester.tapAt(e2);
        await tester.pumpAndSettle();
        await tester.tapAt(e4);
        await tester.pumpAndSettle();

        // No exception should propagate.
        expect(tester.takeException(), isNull);

        // Board should still render.
        expect(find.byType(AdvancedChessBoard), findsOneWidget);
      },
    );

    testWidgets(
      'P1.19: async throw from SoundPack.play does not propagate',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        final pack = _ThrowingSoundPack(throwSync: false);

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

        // Make a move programmatically.
        controller.makeMove(from: 'e2', to: 'e4');
        await tester.pumpAndSettle();

        // No exception should propagate.
        expect(tester.takeException(), isNull);

        // Board should still render.
        expect(find.byType(AdvancedChessBoard), findsOneWidget);
      },
    );
  });
}
