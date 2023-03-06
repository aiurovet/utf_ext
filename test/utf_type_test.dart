import 'package:utf_ext/utf_ext.dart';
import 'package:test/test.dart';

import 'utf_abc.dart';

/// A suite of tests for UtfType
///
void main() {
  final file = UtfAbc.getDummyFile();

  group('Get UTF type -', () {
    test('empty', () {
      expect(UtfType.fromBom([]), UtfType.none);
    });
    test('too short', () {
      expect(UtfType.fromBom([0xFE]), UtfType.none);
    });
    test('fromBom', () {
      UtfAbc.forEachTypeSync(file, (type, _) async {
        final bomLen = type.getBomLength(false);
        final source = UtfAbc.getBytes(type).sublist(0, bomLen + 1);
        expect(UtfType.fromBom(source), type);
      });
    });
  });
}
