// Task 13.5 — README content test.
//
// Covers bugfix.md §2.32.
// Validates: Requirements 2.32 — Correctness Property P1.20 (README refresh).
//
// Three assertions:
//   1. README does NOT contain the stale "arrow will be added" sentence.
//   2. README contains at least one Markdown table header (a line with at
//      least two `|` pipe delimiters).
//   3. README mentions at least three of the new ChessBoardController
//      getters: isInCheck, isStalemate, isGameOver, history, pgn, moveCount.
//
// NOTE: On the unfixed README these assertions FAIL; Task 17 refreshes the
// README to satisfy them. Per the task prompt we encode the expected
// assertions now.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P1.20 README refresh', () {
    late final String body;

    setUpAll(() {
      body = File('README.md').readAsStringSync();
    });

    test('does NOT contain the stale "arrow will be added" line', () {
      expect(
        body,
        isNot(contains('arrow will be added')),
        reason: 'README.md must no longer claim arrow support is coming — '
            'arrows shipped in 2.0.0.',
      );
    });

    test('contains at least one Markdown table header row', () {
      // A Markdown table header row contains multiple `|` delimiters on a
      // single line. Match any line with at least two pipes (i.e. `| col |`).
      final tableRow = RegExp(r'^\|[^\n]*\|[^\n]*\|', multiLine: true);
      expect(
        tableRow.hasMatch(body),
        isTrue,
        reason: 'README.md must contain at least one Markdown table (line with '
            'at least two `|` delimiters) — parameter/getter reference '
            'tables are required by §2.32.',
      );
    });

    test('references at least three of the new controller getters', () {
      const getterNames = <String>[
        'isInCheck',
        'isStalemate',
        'isGameOver',
        'history',
        'pgn',
        'moveCount',
      ];
      final found = <String>[
        for (final name in getterNames)
          if (body.contains(name)) name,
      ];

      expect(
        found.length,
        greaterThanOrEqualTo(3),
        reason: 'README.md must reference at least three of the new '
            'ChessBoardController getters. Found: $found',
      );
    });
  });
}
