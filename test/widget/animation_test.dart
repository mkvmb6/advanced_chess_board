// Task 13.4 — widget tests for the move animation layer.
// Covers §2.25. Validates P1.14.
//
// - Tap move: the MoveAnimationLayer appears, and at ~50% of the default
//   150 ms duration its ChessPieceWidget is midway between the from-square
//   and the to-square (x/y lies strictly between start and end).
// - Drag-drop move: no MoveAnimationLayer ever appears (drag-drop suppresses
//   the animation; the Draggable.feedback already follows the pointer).

import 'package:advanced_chess_board/advanced_chess_board.dart';
// ignore: implementation_imports
import 'package:advanced_chess_board/src/widgets/chess_piece_widget.dart';
// ignore: implementation_imports
import 'package:advanced_chess_board/src/widgets/chess_square.dart';
// ignore: implementation_imports
import 'package:advanced_chess_board/src/widgets/move_animation_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const double _boardSize = 400;
const double _squareSize = _boardSize / 8;

Future<void> _pumpBoard(
  final WidgetTester tester,
  final ChessBoardController c,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: _boardSize,
            height: _boardSize,
            child: AdvancedChessBoard(controller: c),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _squareFinder(final String sq) {
  return find.byWidgetPredicate(
    (final w) => w is ChessSquare && w.square == sq,
  );
}

void main() {
  group('Move animation (P1.14 §2.25)', () {
    testWidgets('tap move triggers MoveAnimationLayer with interpolating piece',
        (final tester) async {
      final c = ChessBoardController();
      await _pumpBoard(tester, c);

      // Select e2 pawn by tapping its Draggable (the piece sits on top, so
      // this dispatches to the ChessPieceWidget's onTap handler, which calls
      // _handleTap('e2', squareSize) and selects the pawn).
      final e2PieceFinder = find.byWidgetPredicate(
        (final w) => w is Draggable<String> && w.data == 'e2',
      );
      await tester.tap(e2PieceFinder, warnIfMissed: false);
      await tester.pump();

      // Now tap e4 (empty square) to commit the move via the non-drag path.
      await tester.tap(_squareFinder('e4'), warnIfMissed: false);

      // Pump exactly one frame to let setState(_animatingMove = ...) commit,
      // and a second to let the MoveAnimationLayer mount and schedule its
      // post-frame callback.
      await tester.pump();
      await tester.pump();

      final layerFinder = find.byType(MoveAnimationLayer);
      expect(
        layerFinder,
        findsOneWidget,
        reason: 'A tap move must trigger an animation layer before the move '
            'completes.',
      );

      // Advance roughly 50% of the 150ms default duration.
      await tester.pump(const Duration(milliseconds: 75));

      // The animating piece lives inside the MoveAnimationLayer.
      final animatingPiece = find.descendant(
        of: layerFinder,
        matching: find.byType(ChessPieceWidget),
      );
      expect(animatingPiece, findsOneWidget);

      // Compute from/to positions in logical pixels (white orientation):
      //   e2 -> col=4, row=6
      //   e4 -> col=4, row=4
      const fromTopLeft = Offset(4 * _squareSize, 6 * _squareSize);
      const toTopLeft = Offset(4 * _squareSize, 4 * _squareSize);

      final currentTopLeft = tester.getTopLeft(animatingPiece);
      // The layer sits inside a Stack positioned by the LayoutBuilder; it may
      // be offset by the Center / SizedBox chrome. We only care about the
      // delta between from/to, so measure relative to the board origin.
      final boardOrigin = tester.getTopLeft(find.byType(AdvancedChessBoard));
      final relTop = currentTopLeft - boardOrigin;

      expect(
        relTop.dx,
        closeTo(fromTopLeft.dx, 0.5),
        reason: 'e-file move: x stays constant at 4*squareSize.',
      );
      // The y should be strictly between the from-square y and the to-square y
      // (not equal to either).
      final minY = toTopLeft.dy; // smaller (closer to top)
      final maxY = fromTopLeft.dy; // larger
      expect(
        relTop.dy,
        greaterThan(minY),
        reason:
            'At 50% of the animation the piece must not yet have arrived at '
            'the destination (relTop.dy must exceed $minY).',
      );
      expect(
        relTop.dy,
        lessThan(maxY),
        reason: 'At 50% of the animation the piece must have left the origin '
            '(relTop.dy must be below $maxY).',
      );

      // Let the animation finish to avoid leaking pending timers.
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
    });

    testWidgets('drag-drop move does NOT produce a MoveAnimationLayer',
        (final tester) async {
      final c = ChessBoardController();
      await _pumpBoard(tester, c);

      // Find the e2 pawn's Draggable.
      final e2Finder = find.byWidgetPredicate(
        (final w) => w is Draggable<String> && w.data == 'e2',
      );
      expect(e2Finder, findsOneWidget);

      // Record the e2 and e4 centres from the live layout to avoid any
      // coordinate mismatch caused by the MaterialApp chrome.
      final e2Centre = tester.getCenter(e2Finder);
      final e4Centre = tester.getCenter(_squareFinder('e4'));

      // Perform a drag gesture from e2 to e4. Start slightly, then move the
      // full distance so the drag recogniser claims the gesture.
      final gesture = await tester.startGesture(e2Centre);
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
      await gesture.moveTo(e4Centre);
      await tester.pump();

      expect(
        find.byType(MoveAnimationLayer),
        findsNothing,
        reason: 'Mid-drag, there must be no animation overlay.',
      );

      await gesture.up();
      // Settle without any additional pumps first to prevent leaking timers,
      // then verify no animation layer was ever mounted.
      await tester.pump();
      await tester.pump();

      expect(
        find.byType(MoveAnimationLayer),
        findsNothing,
        reason: 'After a drag-drop move, there must be no animation overlay — '
            'the drag feedback already provided the visual interpolation.',
      );

      // Wait for any pending frames and confirm the move actually happened.
      await tester.pumpAndSettle(const Duration(milliseconds: 300));
      expect(
        find.byWidgetPredicate(
          (final w) => w is Draggable<String> && w.data == 'e4',
        ),
        findsOneWidget,
        reason: 'Drag-drop commits the move: e4 Draggable must exist.',
      );
    });
  });
}
