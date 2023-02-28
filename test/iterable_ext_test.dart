import 'package:utf_ext/src/iterable_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for IterableExt<T>
///
void main() {
  group('startsWith - List<int> -', () {
    test('empty-empty', () {
      expect(<int>[].startsWith(<int>[]), false);
    });
    test('empty-some', () {
      expect(<int>[].startsWith(<int>[0]), false);
    });
    test('smaller-bigger', () {
      expect(
          <int>[
            0,
            1,
          ].startsWith(<int>[
            0,
            1,
            2,
          ]),
          false);
    });
    test('contains but not starts with', () {
      expect(
          <int>[
            3,
            0,
            1,
            2,
          ].startsWith(<int>[
            0,
            1,
          ]),
          false);
    });
    test('really starts with', () {
      expect(
          <int>[
            0,
            1,
            2,
          ].startsWith(<int>[
            0,
            1,
          ]),
          true);
    });
  });
  group('startsWith - List<String> -', () {
    test('empty-empty', () {
      expect(<String>[].startsWith(<String>[]), false);
    });
    test('empty-some', () {
      expect(<String>[].startsWith(<String>["x"]), false);
    });
    test('smaller-bigger', () {
      expect(
          <String>[
            "a",
            "b",
          ].startsWith(<String>[
            "a",
            "b",
            "c",
          ]),
          false);
    });
    test('contains but not starts with', () {
      expect(
          <String>[
            "d",
            "a",
            "b",
            "c",
          ].startsWith(<String>[
            "a",
            "b",
          ]),
          false);
    });
    test('really starts with', () {
      expect(
          <String>[
            "a",
            "b",
            "c",
          ].startsWith(<String>[
            "a",
            "b",
          ]),
          true);
    });
  });
}
