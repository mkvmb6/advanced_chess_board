// Example tests for the fix in ArrowPainter.shouldRepaint (Task 5).
// Covers bugfix.md §2.4, §2.5 and property P1.3 from design.md.

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/utils/arrow_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArrowPainter.shouldRepaint', () {
    test('equal painters do not repaint', () {
      final arrows = <ChessArrow>[
        ChessArrow(startSquare: 'a2', endSquare: 'a4'),
      ];
      final a = ArrowPainter(arrows, PlayerColor.white);
      final b = ArrowPainter(
        List<ChessArrow>.from(arrows),
        PlayerColor.white,
      );
      expect(b.shouldRepaint(a), isFalse);
    });

    test('arrow list length change triggers repaint', () {
      final a = ArrowPainter(
        <ChessArrow>[ChessArrow(startSquare: 'a2', endSquare: 'a4')],
        PlayerColor.white,
      );
      final b = ArrowPainter(
        <ChessArrow>[
          ChessArrow(startSquare: 'a2', endSquare: 'a4'),
          ChessArrow(startSquare: 'h1', endSquare: 'h8'),
        ],
        PlayerColor.white,
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('arrow color change triggers repaint', () {
      final a = ArrowPainter(
        <ChessArrow>[
          ChessArrow(startSquare: 'a2', endSquare: 'a4', color: Colors.red),
        ],
        PlayerColor.white,
      );
      final b = ArrowPainter(
        <ChessArrow>[
          ChessArrow(startSquare: 'a2', endSquare: 'a4', color: Colors.blue),
        ],
        PlayerColor.white,
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('orientation change triggers repaint', () {
      final arrows = <ChessArrow>[
        ChessArrow(startSquare: 'a2', endSquare: 'a4'),
      ];
      final a = ArrowPainter(arrows, PlayerColor.white);
      final b = ArrowPainter(arrows, PlayerColor.black);
      expect(b.shouldRepaint(a), isTrue);
    });
  });
}
