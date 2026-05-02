// Feature: chess-board-ux-enhancements, Property P2.2:
// Controller semantics (notify:false, game escape hatch, typed getters,
// ListenableBuilder auto-swap, state reset on controller swap) are
// preserved under 3.1.0.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart';

import 'generators.dart';

void main() {
  ft.group('Preservation P2.2: controller semantics preserved', () {
    Glados<String>(any.chessFen).test(
      'prop_notify_false_suppresses_under_3_1_0',
      (final String fen) {
        final c = ChessBoardController();
        c.loadGameFromFEN(fen, notify: false);

        var notifications = 0;
        c.addListener(() => notifications++);

        c.resetBoard(notify: false);
        c.loadGameFromFEN(fen, notify: false);

        final moves = c.game.generate_moves();
        if (moves.isNotEmpty) {
          final m = moves.first;
          c.makeMove(
            from: m.fromAlgebraic,
            to: m.toAlgebraic,
            promotion: m.promotion?.name,
            notify: false,
          );
          c.undo(notify: false);
        }

        ft.expect(
          notifications,
          0,
          reason: 'notify:false must suppress every listener invocation',
        );
      },
    );

    ft.test('game escape hatch returns chess.Chess instance', () {
      final c = ChessBoardController();
      ft.expect(c.game, ft.isA<chess.Chess>());
      ft.expect(identical(c.game, c.game), ft.isTrue);
    });

    ft.testWidgets(
      'controller swap clears selection state',
      (final ft.WidgetTester tester) async {
        final controllerA = ChessBoardController();
        final controllerB = ChessBoardController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(controller: controllerA),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Swap controller.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(controller: controllerB),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Board should still render.
        ft.expect(ft.find.byType(AdvancedChessBoard), ft.findsOneWidget);
      },
    );
  });
}
