// Task 13.3 — property-based tests for `ArrowPainter.shouldRepaint`.
// Covers §2.4, §2.5.
//
// Property IDs (from design.md):
//   P1.3 — ArrowPainter.shouldRepaint(old) returns `true` iff arrows list OR
//          orientation differs between `old` and `new` painter instances.

import 'dart:math' as math;

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:advanced_chess_board/src/utils/arrow_painter.dart';
import 'package:flutter_test/flutter_test.dart' as ft;
import 'package:glados/glados.dart' hide group, test, expect;

import '../properties/generators.dart';

/// Value equality over an arrow list — matches `ChessArrow.operator ==` /
/// `hashCode`. Used as the oracle for "did the arrows change?".
bool _arrowsEqual(final List<ChessArrow> a, final List<ChessArrow> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// A single painter input — encodes `(arrows, orientation)` so two of these
/// can be threaded through `Glados2` (glados ships Glados/Glados2/Glados3).
class _PainterInput {
  const _PainterInput(this.arrows, this.orientation);

  final List<ChessArrow> arrows;
  final PlayerColor orientation;

  @override
  String toString() => 'PainterInput(arrows=$arrows, orientation=$orientation)';
}

extension _PainterInputGen on Any {
  /// Random `(arrows, orientation)` pair.
  Generator<_PainterInput> get painterInput =>
      (final math.Random random, final int size) {
        final arrows =
            any.listWithLengthInRange(0, 6, any.chessArrow)(random, size);
        final orient = any.boardOrientation(random, size);
        return Shrinkable<_PainterInput>(
          _PainterInput(arrows.value, orient.value),
          () => const <Shrinkable<_PainterInput>>[],
        );
      };
}

void main() {
  ft.group('ArrowPainter — property-based', () {
    Glados2<_PainterInput, _PainterInput>(
      any.painterInput,
      any.painterInput,
    ).test(
      'prop_shouldRepaint_iff_semantic_change',
      (final _PainterInput oldInput, final _PainterInput newInput) {
        final oldPainter = ArrowPainter(oldInput.arrows, oldInput.orientation);
        final newPainter = ArrowPainter(newInput.arrows, newInput.orientation);

        final semanticChange = oldInput.orientation != newInput.orientation ||
            !_arrowsEqual(oldInput.arrows, newInput.arrows);

        ft.expect(
          newPainter.shouldRepaint(oldPainter),
          semanticChange,
          reason: 'shouldRepaint must return `true` iff arrows differ OR '
              'orientation differs. '
              'old=$oldInput, new=$newInput, semanticChange=$semanticChange',
        );
      },
    );
  });
}
