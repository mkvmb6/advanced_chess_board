// Task 13.5 — pub.dev metadata test.
//
// Covers bugfix.md §2.30, §3.20.
// Validates: Requirements 2.30 — Correctness Property P1.18 (pub.dev metadata
// present).
//
// Parses `pubspec.yaml` via `package:yaml` and asserts the four required
// pub.dev metadata keys (`repository`, `issue_tracker`, `topics`, `platforms`)
// are present and non-empty. Task 2 added these keys; this test locks in that
// they stay present and well-formed.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('P1.18 pub.dev metadata', () {
    late final YamlMap pubspec;

    setUpAll(() {
      final body = File('pubspec.yaml').readAsStringSync();
      pubspec = loadYaml(body) as YamlMap;
    });

    test('repository is a non-empty string', () {
      final repository = pubspec['repository'];
      expect(repository, isA<String>(),
          reason: 'pubspec.yaml must declare `repository:` as a string');
      expect((repository as String).trim(), isNotEmpty,
          reason: '`repository` must be non-empty');
    });

    test('issue_tracker is a non-empty string', () {
      final issueTracker = pubspec['issue_tracker'];
      expect(issueTracker, isA<String>(),
          reason: 'pubspec.yaml must declare `issue_tracker:` as a string');
      expect((issueTracker as String).trim(), isNotEmpty,
          reason: '`issue_tracker` must be non-empty');
    });

    test('topics is a non-empty list', () {
      final topics = pubspec['topics'];
      expect(topics, isA<YamlList>(),
          reason: 'pubspec.yaml must declare `topics:` as a list');
      expect((topics as YamlList).length, greaterThan(0),
          reason: '`topics` must contain at least one entry');
      for (final t in topics) {
        expect(t, isA<String>(), reason: 'every topic entry must be a string');
        expect((t as String).trim(), isNotEmpty,
            reason: 'topic entries must be non-empty strings');
      }
    });

    test('platforms is a non-empty map', () {
      final platforms = pubspec['platforms'];
      expect(platforms, isA<YamlMap>(),
          reason: 'pubspec.yaml must declare `platforms:` as a map');
      expect((platforms as YamlMap).length, greaterThan(0),
          reason: '`platforms` must list at least one supported platform');
    });
  });
}
