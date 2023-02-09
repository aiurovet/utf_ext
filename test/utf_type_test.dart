import 'package:utf_ext/utf_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for UtfType
///
void main() {
  group('Get UTF type -', () {
    test('empty', () {
      expect(UtfType.fromBom([]), null);
    });
    test('too short', () {
      expect(UtfType.fromBom([0xFE]), null);
    });
    test('no BOM', () {
      expect(UtfType.fromBom([0x41, 0x42, 0x43, 0x44]),
          null);
    });
    test('UTF-8', () {
      expect(UtfType.fromBom([0xEF, 0xBB, 0xBF, 0x41]),
          UtfType.utf8);
    });
    test('UTF-16BE', () {
      expect(UtfType.fromBom([0xFE, 0xFF, 0x41, 0x42]),
          UtfType.utf16be);
    });
    test('UTF-16LE', () {
      expect(UtfType.fromBom([0xFF, 0xFE, 0x41, 0x42]),
          UtfType.utf16le);
    });
    test('UTF-32BE', () {
      expect(UtfType.fromBom([0x00, 0x00, 0xFE, 0xFF]),
          UtfType.utf32be);
    });
    test('UTF-32LE', () {
      expect(UtfType.fromBom([0xFF, 0xFE, 0x00, 0x00]),
          UtfType.utf32le);
    });
  });
}
