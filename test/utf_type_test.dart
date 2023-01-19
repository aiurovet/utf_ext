import 'dart:typed_data';

import 'package:utf_ext/utf_ext.dart';
import 'package:test/test.dart';

/// A suite of tests for UtfType
///
void main() {
  group('Get UTF type -', () {
    test('empty', () {
      expect(UtfType.fromBom(Uint8List.fromList([]), 0), null);
    });
    test('too short', () {
      expect(UtfType.fromBom(Uint8List.fromList([0xFE]), 1), null);
    });
    test('no BOM', () {
      expect(UtfType.fromBom(Uint8List.fromList([0x41, 0x42, 0x43, 0x44]), 4),
          null);
    });
    test('UTF-8', () {
      expect(UtfType.fromBom(Uint8List.fromList([0xEF, 0xBB, 0xBF, 0x41]), 4),
          UtfType.utf8);
    });
    test('UTF-16BE', () {
      expect(UtfType.fromBom(Uint8List.fromList([0xFE, 0xFF, 0x41, 0x42]), 4),
          UtfType.utf16be);
    });
    test('UTF-16LE', () {
      expect(UtfType.fromBom(Uint8List.fromList([0xFF, 0xFE, 0x41, 0x42]), 4),
          UtfType.utf16le);
    });
    test('UTF-32BE', () {
      expect(UtfType.fromBom(Uint8List.fromList([0x00, 0x00, 0xFE, 0xFF]), 4),
          UtfType.utf32be);
    });
    test('UTF-32LE', () {
      expect(UtfType.fromBom(Uint8List.fromList([0xFF, 0xFE, 0x00, 0x00]), 4),
          UtfType.utf32le);
    });
  });
}
