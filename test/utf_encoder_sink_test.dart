import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

/// A suite of tests for UtfEncoderSink
///
void main() {
  final empty = Uint8List.fromList(<int>[]);

  final bytesUtf8 = Uint8List.fromList(<int>[
    0xEF,
    0xBB,
    0xBF,
    0x41,
    0x62,
    0x63,
    0xD0,
    0x90,
    0xD0,
    0xB1,
    0xD0,
    0xB2,
    0xD0,
    0xB3,
    0xE1,
    0x83,
    0x85,
    0xD5,
    0xB6,
    0xE0,
    0xB9,
    0x92,
    0xE4,
    0xBF,
    0xB0,
    0xF0,
    0x90,
    0xA1,
    0x81,
    0xE2,
    0x84,
    0xB5,
    0xF0,
    0x9D,
    0x92,
    0x9C,
  ]);
  final bytesUtf32be = Uint8List.fromList(<int>[
    0x00,
    0x00,
    0xFE,
    0xFF,
    0x00,
    0x00,
    0xFF,
    0xFE,
    0x00,
    0x00,
    0x41,
    0x00,
    0x00,
    0x00,
    0x62,
    0x00,
    0x00,
    0x00,
    0x63,
    0x00,
    0x00,
    0x00,
    0x10,
    0x04,
    0x00,
    0x00,
    0x31,
    0x04,
    0x00,
    0x00,
    0x32,
    0x04,
    0x00,
    0x00,
    0x33,
    0x04,
    0x00,
    0x00,
    0xC5,
    0x10,
    0x00,
    0x00,
    0x76,
    0x05,
    0x00,
    0x00,
    0x52,
    0x0E,
    0x00,
    0x00,
    0xF0,
    0x4F,
    0x01,
    0x00,
    0x41,
    0x08,
    0x00,
    0x00,
    0x35,
    0x21,
    0x01,
    0x00,
    0x9C,
    0xD4,
    0x00,
    0x00,
    0xCC,
    0x0B,
    0x00,
    0x00,
    0xCC,
    0x0B,
    0x00,
    0x00,
    0xCC,
    0x0B,
    0x00,
    0x00,
    0xCC,
    0x0B,
    0x00,
    0x00,
    0xCC,
    0x0B,
    0x00,
    0x00,
    0xCC,
    0x0B,
    0x00,
    0x00,
    0xCC,
    0x0B,
  ]);

  final complexString = "AbcАбвгჅն๒俰𐡁ℵ𝒜";
  // final complexBytes = UtfEncoderSink(id: null, type: UtfType.utf32be, withBom: false).convert(complexString);

  // if (complexBytes.isEmpty) {
  //   complexBytes.clear();
  // }

  group('constructor -', () {
    test('UTF-8 - convert empty no BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: false);
      expect(encoder.convert("", 0, 3), empty);
    });
    test('UTF-8 - convert empty with BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: true);
      expect(encoder.convert("", 0, 3), bytesUtf8.sublist(0, 3));
    });
    test('UTF-8 - convert start with BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: true);
      expect(encoder.convert("Abc", 0, 1), bytesUtf8.sublist(0, 4));
    });
    test('UTF-8 - convert middle, no BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: false);
      expect(encoder.convert("Abc", 1, 3), bytesUtf8.sublist(4, 6));
    });
    test('UTF-8 - convert complex with BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: true);
      expect(encoder.convert(complexString), bytesUtf8);
    });

    test('UTF-32BE - convert empty no BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf32be, withBom: false);
      expect(encoder.convert("", 0, 3), empty);
    });
    test('UTF-32BE - convert empty with BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf32be, withBom: true);
      expect(encoder.convert("", 0, 3), bytesUtf32be.sublist(0, 4));
    });
    test('UTF-32BE - convert start with BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf32be, withBom: true);
      expect(encoder.convert("Abc", 0, 1), bytesUtf32be.sublist(4, 12));
    });
    test('UTF-32BE - convert middle, no BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf32be, withBom: false);
      expect(encoder.convert("Abc", 1, 3), bytesUtf32be.sublist(12, 20));
    });
  });
}
