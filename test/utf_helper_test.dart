import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

/// A suite of tests for UtfHelper (all I/O methods are tested via utf_file_test.dart)
///
void main() {
  group('fromPosixLineBreaks -', () {
    test('empty', () {
      expect(UtfHelper.fromPosixLineBreaks(''), '');
    });
    test('no break', () {
      expect(UtfHelper.fromPosixLineBreaks('Abc'), 'Abc');
    });
    test('no POSIX break', () {
      expect(UtfHelper.fromPosixLineBreaks('Ab\r\nc'), 'Ab\r\nc');
    });
    test('only POSIX breaks', () {
      expect(UtfHelper.fromPosixLineBreaks('A\nb\nc'), 'A\r\nb\r\nc');
    });
    test('mixed breaks', () {
      expect(UtfHelper.fromPosixLineBreaks('A\r\nb\nc'), 'A\r\nb\r\nc');
    });
  });
  group('toPosixLineBreaks -', () {
    test('empty', () {
      expect(UtfHelper.toPosixLineBreaks(''), '');
    });
    test('no break', () {
      expect(UtfHelper.toPosixLineBreaks('Abc'), 'Abc');
    });
    test('no Windows break', () {
      expect(UtfHelper.toPosixLineBreaks('Ab\nc'), 'Ab\nc');
    });
    test('only Windows breaks', () {
      expect(UtfHelper.toPosixLineBreaks('A\r\nb\r\nc'), 'A\nb\nc');
    });
    test('mixed breaks', () {
      expect(UtfHelper.toPosixLineBreaks('A\r\nb\nc'), 'A\nb\nc');
    });
  });
}
