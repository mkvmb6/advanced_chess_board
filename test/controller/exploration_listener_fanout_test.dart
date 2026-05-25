// Exploration test — bugfix.md §1.1, §1.2.
//
// PROPERTY: prop_multi_listener_fanout_fails_on_unfixed (design.md P1.1).
// Validates: Requirements 1.1, 1.2
//
// EXPECTED TO FAIL ON UNFIXED CODE — failure confirms the bug condition.
//
// Bug: `ChessBoardController.addListener` overrides `ChangeNotifier.addListener`
// and stores a single `VoidCallback? _listener`; every later `addListener`
// overwrites the previous one and `_notifyListeners` only invokes that single
// field. So when N listeners are registered, only the most-recently-registered
// one fires.
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   glados counterexample: 2 (smallest n that breaks the property).
//   For n = 2 listeners registered before `makeMove(e2 -> e4)`:
//     expected counters: [1, 1]
//     observed counters: [0, 1]
//   i.e. the first listener never fires; only the last one does.
// -----------------------------------------------------------------------------

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter_test/flutter_test.dart';
// Glados re-exports `package:test/test.dart` which collides with
// flutter_test's `group`/`test`/`expect` symbols. Hide those so only the
// flutter_test versions win; keep `Glados` + `any` + its extensions.
import 'package:glados/glados.dart' hide test, group, expect;

void main() {
  group('§1.1 / §1.2 listener fan-out exploration', () {
    // Example case that is always reproducible: 2 listeners.
    test('two listeners both fire on makeMove (example)', () {
      final controller = ChessBoardController();
      var counterA = 0;
      var counterB = 0;

      controller.addListener(() => counterA++);
      controller.addListener(() => counterB++);

      final accepted = controller.makeMove(from: 'e2', to: 'e4');
      expect(accepted, isTrue, reason: 'e2-e4 is a legal opening move');

      expect(counterA, 1,
          reason: 'Listener A must fire exactly once — but on unfixed code it '
              'never fires because addListener overwrote it with listener B.');
      expect(counterB, 1, reason: 'Listener B must fire exactly once.');
    });

    // Property: for any n in [2, 10] listeners, every one must fire once
    // per successful mutation.
    Glados<int>(
      any.intInRange(2, 11), // 2..10 inclusive (upper bound is exclusive)
    ).test('every listener fires exactly once for any n in [2, 10]', (final n) {
      final controller = ChessBoardController();
      final counters = List<int>.filled(n, 0);
      for (var i = 0; i < n; i++) {
        controller.addListener(() => counters[i]++);
      }

      final accepted = controller.makeMove(from: 'e2', to: 'e4');
      expect(accepted, isTrue);

      // Expected invariant: every counter == 1.
      // On unfixed code, counters == [0, 0, ..., 0, 1].
      for (var i = 0; i < n; i++) {
        expect(
          counters[i],
          1,
          reason: 'Listener #$i (of $n) must fire exactly once on makeMove.',
        );
      }
    });
  });
}
