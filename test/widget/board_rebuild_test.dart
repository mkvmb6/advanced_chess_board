// Task 13.4 — widget tests for controller auto-subscription and swap.
// Covers §2.8, §2.9. Validates P1.6, P1.7.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Board auto-rebuild on controller changes', () {
    testWidgets('programmatic move triggers rebuild without external listener',
        (final tester) async {
      final c = ChessBoardController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 400,
              child: AdvancedChessBoard(controller: c),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (final w) => w is Draggable<String> && w.data == 'e2',
        ),
        findsOneWidget,
      );

      c.makeMove(from: 'e2', to: 'e4');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      expect(
        find.byWidgetPredicate(
          (final w) => w is Draggable<String> && w.data == 'e4',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (final w) => w is Draggable<String> && w.data == 'e2',
        ),
        findsNothing,
      );
    });

    testWidgets('swapping controllers unsubscribes from old, subscribes to new',
        (final tester) async {
      final a = ChessBoardController();
      final b = ChessBoardController();

      Widget build(final ChessBoardController controller) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(controller: controller),
              ),
            ),
          );

      await tester.pumpWidget(build(a));
      await tester.pumpAndSettle();

      // Swap to controller b.
      await tester.pumpWidget(build(b));
      await tester.pumpAndSettle();

      // Mutate old controller — no rebuild expected.
      a.makeMove(from: 'e2', to: 'e4');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // e2 Draggable still present (b hasn't moved; the old controller a
      // changed but the widget is now on b).
      expect(
        find.byWidgetPredicate(
          (final w) => w is Draggable<String> && w.data == 'e2',
        ),
        findsOneWidget,
      );

      // Mutate new controller — rebuild expected.
      b.makeMove(from: 'd2', to: 'd4');
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(
        find.byWidgetPredicate(
          (final w) => w is Draggable<String> && w.data == 'd4',
        ),
        findsOneWidget,
      );
    });
  });
}
