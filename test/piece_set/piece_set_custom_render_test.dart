// Feature: chess-board-ux-enhancements, Property P1.7:
// For any custom PieceSet, every ChessPieceWidget rendered by the
// board references that set via widget.pieceSet; no ImageProvider
// outside the set's `imageFor` output is used.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/constants/global_constants.dart';
import 'package:advanced_chess_board/src/widgets/chess_piece_widget.dart';
import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<({PlayerColor color, chess.PieceType type}), ImageProvider>
    _buildTransparentMap() {
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
      // Use AssetImage from the package - these are always valid.
      map[(color: color, type: type)] = const AssetImage(
        'assets/pieces/wp.png',
        package: packageName,
      );
    }
  }
  return map;
}

void main() {
  group('Custom PieceSet drives every rendered piece', () {
    testWidgets(
      'board with custom PieceSet renders ChessPieceWidgets with that set',
      (final WidgetTester tester) async {
        final customMap = _buildTransparentMap();
        final customSet = PieceSet.fromAssetMap(customMap);
        final controller = ChessBoardController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 400,
                child: AdvancedChessBoard(
                  controller: controller,
                  pieceSet: customSet,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // All ChessPieceWidgets should reference the custom set.
        final pieceWidgets = tester.widgetList<ChessPieceWidget>(
          find.byType(ChessPieceWidget),
        );
        for (final widget in pieceWidgets) {
          expect(
            widget.pieceSet,
            equals(customSet),
            reason: 'ChessPieceWidget should use the custom PieceSet',
          );
        }
      },
    );

    testWidgets(
      'default board uses PieceSet.chessDotCom',
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

        // All ChessPieceWidgets should reference chessDotCom.
        final pieceWidgets = tester.widgetList<ChessPieceWidget>(
          find.byType(ChessPieceWidget),
        );
        for (final widget in pieceWidgets) {
          expect(
            widget.pieceSet,
            equals(PieceSet.chessDotCom),
            reason: 'Default ChessPieceWidget should use PieceSet.chessDotCom',
          );
        }
      },
    );
  });
}
