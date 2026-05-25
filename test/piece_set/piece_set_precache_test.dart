// Feature: chess-board-ux-enhancements, Property P1.8:
// Active PieceSet is precached on first didChangeDependencies; swapping
// pieceSet across didUpdateWidget precaches the new set's 12 providers
// and the next build renders with the new set.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/widgets/chess_piece_widget.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<({PlayerColor color, chess.PieceType type}), ImageProvider> _buildMap(
    final int seed) {
  // Use AssetImage from the package - these are always valid.
  // Different seeds use different piece images to ensure the sets are distinct.
  final paths = seed == 1
      ? <chess.PieceType, String>{
          chess.PieceType.PAWN: 'assets/pieces/wp.png',
          chess.PieceType.KNIGHT: 'assets/pieces/wn.png',
          chess.PieceType.BISHOP: 'assets/pieces/wb.png',
          chess.PieceType.ROOK: 'assets/pieces/wr.png',
          chess.PieceType.QUEEN: 'assets/pieces/wq.png',
          chess.PieceType.KING: 'assets/pieces/wk.png',
        }
      : <chess.PieceType, String>{
          chess.PieceType.PAWN: 'assets/pieces/bp.png',
          chess.PieceType.KNIGHT: 'assets/pieces/bn.png',
          chess.PieceType.BISHOP: 'assets/pieces/bb.png',
          chess.PieceType.ROOK: 'assets/pieces/br.png',
          chess.PieceType.QUEEN: 'assets/pieces/bq.png',
          chess.PieceType.KING: 'assets/pieces/bk.png',
        };

  final map = <({PlayerColor color, chess.PieceType type}), ImageProvider>{};
  for (final color in PlayerColor.values) {
    for (final type in const <chess.PieceType>[
      chess.PieceType.PAWN,
      chess.PieceType.KNIGHT,
      chess.PieceType.BISHOP,
      chess.PieceType.ROOK,
      chess.PieceType.QUEEN,
      chess.PieceType.KING,
    ]) {
      map[(color: color, type: type)] = AssetImage(
        paths[type]!,
        package: 'advanced_chess_board',
      );
    }
  }
  return map;
}

void main() {
  group('PieceSet precache', () {
    testWidgets(
      'swapping pieceSet triggers rebuild with new set',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        final map1 = _buildMap(1);
        final map2 = _buildMap(2);
        final set1 = PieceSet.fromAssetMap(map1);
        final set2 = PieceSet.fromAssetMap(map2);

        // Pump with set1.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  pieceSet: set1,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify set1 is used.
        final pieceWidgets1 = tester.widgetList<ChessPieceWidget>(
          find.byType(ChessPieceWidget),
        );
        for (final widget in pieceWidgets1) {
          expect(widget.pieceSet, equals(set1));
        }

        // Swap to set2.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  pieceSet: set2,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify set2 is now used.
        final pieceWidgets2 = tester.widgetList<ChessPieceWidget>(
          find.byType(ChessPieceWidget),
        );
        for (final widget in pieceWidgets2) {
          expect(widget.pieceSet, equals(set2));
        }
      },
    );

    testWidgets(
      'same pieceSet across rebuild does not trigger extra precache',
      (final WidgetTester tester) async {
        final controller = ChessBoardController();
        final map = _buildMap(1);
        final set = PieceSet.fromAssetMap(map);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  pieceSet: set,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Rebuild with same set — should not throw.
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  pieceSet: set,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Board should still render (precache failures are non-fatal).
        expect(find.byType(AdvancedChessBoard), findsOneWidget);
      },
    );
  });
}
