import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

/// A suite of tests for UtfException
///
void main() {
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
    test('getDescription - UTF-8 - empty', () {
      final d = UtfException(null, UtfType.utf8, null, 0).getDescription();
      expect(d, 'Malformed UTF-8 in the beginning');
    });
    test('getDescription - UTF-16LE - non-empty', () {
      final d = UtfException(null, UtfType.utf16le, 'abc', 123).getDescription();
      expect(d, 'Malformed UTF-16LE at offset 123 after the text: abc');
    });
    test('toString - UTF-8 - empty', () {
      final d = UtfException('abc.txt', UtfType.utf8, null, 0);
      expect(d.toString(), 'Error in abc.txt: Malformed UTF-8 in the beginning');
    });
    test('toString - UTF-16LE - non-empty', () {
      final d = UtfException('abc.txt', UtfType.utf16le, 'abc', 123);
      expect(d.toString(), 'Error in abc.txt: Malformed UTF-16LE at offset 123 after the text: abc');
    });
  });
}
