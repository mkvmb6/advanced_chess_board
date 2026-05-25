// Exploration test — bugfix.md §1.29.
//
// PROPERTY: prop_test_file_is_non_trivial (design.md P1 — testing-presence
// clause of the §2.29 family).
// Validates: Requirements 1.29
//
// CHICKEN-AND-EGG NOTE (per tasks.md §1 execution note 5):
// This clause is "self-healing" once Task 1 writes the other 12 exploration
// files and replaces the stub. The cleanest way to encode the original bug
// condition is to persist the original stub body (`void main() {}`) as a
// fixture string and assert that the current file differs from it — that way
// the test captures the pre-Task-1 state even though the file has been
// rewritten as an index.
//
// -----------------------------------------------------------------------------
// OBSERVED COUNTEREXAMPLE (captured from `flutter test` against unfixed code):
//
//   On the unfixed main branch, `test/advanced_chess_board_test.dart` had
//   the body:
//
//     void main() {}
//
//   The assertion `File(...).readAsStringSync().trim() != _legacyStub.trim()`
//   returns false (strings are equal), so the test FAILS — confirming the
//   bug condition "the test file is empty".
//
//   After Task 1 replaces the file with an index that imports 13 sub-tests,
//   this assertion FLIPS to true and the test passes. That's the
//   self-healing behaviour documented in tasks.md §1 note 5.
// -----------------------------------------------------------------------------

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The exact body the stub test file had on the unfixed `main` branch.
/// Captured here so the exploration test has a stable oracle regardless of
/// whatever we replace the file with in Task 1.
const String _legacyStub = 'void main() {}\n';

void main() {
  group('§1.29 empty test file self-heal', () {
    test('test file is no longer the stub', () {
      final file = File('test/advanced_chess_board_test.dart');
      expect(file.existsSync(), isTrue,
          reason: 'test/advanced_chess_board_test.dart must exist');

      final body = file.readAsStringSync();

      expect(
        body.trim(),
        isNot(_legacyStub.trim()),
        reason:
            'test/advanced_chess_board_test.dart must contain more than the '
            'legacy stub `void main() {}`. On unfixed code, the body IS the '
            'stub and this assertion fails — confirming §1.29.',
      );

      // Sanity check: the current file must either (a) contain a `test(` /
      // `testWidgets(` invocation itself, OR (b) `import` sub-test files
      // that do. We assert the presence of at least one import pointing into
      // the exploration sub-directories, which is how Task 1 rewires things.
      final hasDirectTest = body.contains(RegExp(r'\btest\s*\(')) ||
          body.contains(RegExp(r'\btestWidgets\s*\('));
      final hasSubTestImports = body.contains("import '") &&
          (body.contains('controller/') ||
              body.contains('painter/') ||
              body.contains('widget/') ||
              body.contains('packaging/'));

      expect(
        hasDirectTest || hasSubTestImports,
        isTrue,
        reason: 'Current test harness file must either invoke `test(`/'
            '`testWidgets(` directly or import sub-test files that do.',
      );
    });
  });
}
