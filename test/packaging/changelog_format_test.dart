// Task 13.5 — CHANGELOG header format test.
//
// Covers bugfix.md §2.31.
// Validates: Requirements 2.31 — Correctness Property P1.19 (dated CHANGELOG).
//
// Every release header in CHANGELOG.md must match the regex
//   ^## \d+\.\d+\.\d+ — \d{4}-\d{2}(-\d{2})?$
// per design.md acceptance (month-only or full-date ISO-8601 form accepted).
//
// NOTE: On unfixed CHANGELOG.md (where release headers have no date, e.g.
// `## 2.3.0`), this test FAILS by design. Task 16 backfills the dates, after
// which the test passes. Per the task prompt, we encode the *expected*
// assertions now; Task 16 is responsible for satisfying them.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('P1.19 CHANGELOG release headers are ISO-8601 dated', () {
    late final String body;

    setUpAll(() {
      body = File('CHANGELOG.md').readAsStringSync();
    });

    test('every release header matches the dated format', () {
      // Pull every header that looks like a release (`## <semver>` at line
      // start) regardless of whether it carries a date.
      final anyReleaseHeader = RegExp(
        r'^## \d+\.\d+\.\d+.*$',
        multiLine: true,
      );
      // The exact shape required by design.md acceptance: `## X.Y.Z — YYYY-MM`
      // or `## X.Y.Z — YYYY-MM-DD`.
      final datedReleaseHeader = RegExp(
        r'^## \d+\.\d+\.\d+ — \d{4}-\d{2}(-\d{2})?$',
        multiLine: true,
      );

      final allHeaders = anyReleaseHeader
          .allMatches(body)
          .map((m) => m.group(0) ?? '')
          .toList();
      final datedHeaders = datedReleaseHeader
          .allMatches(body)
          .map((m) => m.group(0) ?? '')
          .toList();

      expect(allHeaders, isNotEmpty,
          reason: 'CHANGELOG.md must contain at least one release header');

      final undated = <String>[
        for (final h in allHeaders)
          if (!datedHeaders.contains(h)) h,
      ];

      expect(
        undated,
        isEmpty,
        reason: 'Every release header in CHANGELOG.md must match '
            '`## X.Y.Z — YYYY-MM(-DD)?`. Undated headers: $undated',
      );
    });
  });
}
