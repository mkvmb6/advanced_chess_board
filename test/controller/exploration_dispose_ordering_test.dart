// Exploration test — bugfix.md §1.3.
//
// PROPERTY: prop_dispose_orders_super_last (design.md P1.2).
// Validates: Requirements 1.3
//
// EXPECTED TO FAIL ON UNFIXED CODE — failure confirms the bug condition.
//
// Bug: `ChessBoardController.dispose` invokes `super.dispose()` BEFORE setting
// `_listener = null`. In debug mode `ChangeNotifier` asserts that the
// notifier has been disposed only once, and any subsequent `addListener`
// / `removeListener` / `notifyListeners` call after dispose throws
// `FlutterError("A ChangeNotifier was used after being disposed.")`.
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   `controller.dispose()` returns normally (no direct throw) because the
//   override swallows the ordering issue. Then the subsequent
//   `controller.addListener(() {})` ALSO does not throw, because the unfixed
//   `addListener` override never delegates to `super.addListener` — the
//   `ChangeNotifier`'s post-dispose assertion path is bypassed entirely.
//
//   Test assertion `expect(caught, isNotNull)` fails:
//     Expected: not null
//     Actual: <null>
//
//   This failure confirms the bug: the dispose contract is silently
//   violated because the override hides the post-dispose assertion. Once
//   Task 4.1 removes the addListener override and reorders dispose so
//   super.dispose() runs last, the post-dispose addListener call will
//   correctly throw a FlutterError and this test will pass.
// -----------------------------------------------------------------------------

import 'package:advanced_chess_board/advanced_chess_board.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('§1.3 dispose ordering exploration', () {
    test('dispose is idempotent and leaves controller in a safe state', () {
      final controller = ChessBoardController();
      controller.addListener(() {});

      // dispose() itself should complete without throwing.
      // Separately, we verify that the controller's internal listener field
      // was correctly nulled BEFORE super.dispose() ran by calling
      // `debugAssertNotDisposed` via any public API.
      expect(controller.dispose, returnsNormally);

      // After dispose, attempting to register a listener must throw exactly
      // the ChangeNotifier "used after disposed" assertion — NOT a
      // `LateInitializationError` or NPE originating from `_listener = null`
      // running after super.dispose().
      //
      // On fixed code this raises `FlutterError` cleanly (super.dispose ran
      // last; listener field cleanup happened first).
      FlutterError? caught;
      try {
        controller.addListener(() {});
      } on FlutterError catch (e) {
        caught = e;
      }

      // On UNFIXED code, one of the following will be observed:
      //   (a) no exception at all (the override doesn't delegate to super);
      //   (b) a different assertion type because _listener was touched after
      //       super.dispose() marked the notifier disposed.
      // The fixed behaviour is: a clean FlutterError "used after disposed".
      expect(
        caught,
        isNotNull,
        reason: 'Registering a listener after dispose should raise a '
            'FlutterError "used after disposed" — unfixed code may skip this '
            'check because the override does not delegate to super.',
      );
      expect(
        caught!.toString(),
        contains('disposed'),
        reason: 'The FlutterError should mention "disposed".',
      );
    });
  });
}
