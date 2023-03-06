import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

import 'utf_abc.dart';

/// A suite of tests for UtfException
///
void main() {
  final file = UtfAbc.getDummyFile();

  group('UtfException -', () {
    test('getEnding - empty', () {
      final e = UtfException.getEnding('', 0);
      expect(e, '');
    });
    test('getEnding - short', () {
      final e = UtfException.getEnding('abc', 1);
      expect(e, 'c');
    });
    test('getEnding - longer', () {
      final e = UtfException.getEnding('abc def', 5);
      expect(e, 'c def');
    });
    test('getEnding - whole', () {
      final e = UtfException.getEnding('abc def');
      expect(e, 'abc def');
    });
    test('getEnding - whole and beyond', () {
      final e = UtfException.getEnding('abc def', 1000);
      expect(e, 'abc def');
    });
    test('getDescription', () {
      UtfAbc.forEachTypeSync(file, (type, _) async {
        final d = UtfException(null, type, null, 0).getDescription();
        expect(d, 'Malformed $type in the beginning');
      });
    });
  });
}
