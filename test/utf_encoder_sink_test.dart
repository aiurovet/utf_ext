import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

import 'utf.dart';

/// A suite of tests for UtfEncoderSink
///
void main() {
  group('convert full complex with BOM -', () {
    test('UTF-8', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: true);
      expect(encoder.convert(Utf.complexStr), Utf.bytesUtf8);
    });
    test('UTF-16BE', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf16be, withBom: true);
      expect(encoder.convert(Utf.complexStr), Utf.bytesUtf16be);
    });
    test('UTF-16LE', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf16le, withBom: true);
      expect(encoder.convert(Utf.complexStr), Utf.bytesUtf16le);
    });
    test('UTF-32BE', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf32be, withBom: true);
      expect(encoder.convert(Utf.complexStr), Utf.bytesUtf32be);
    });
    test('UTF-32LE', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf32le, withBom: true);
      expect(encoder.convert(Utf.complexStr), Utf.bytesUtf32le);
    });
  });
  group('convert part -', () {
    test('UTF-8 - convert empty no BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: false);
      expect(encoder.convert("", 0, 3), Utf.bytesEmpty);
    });
    test('UTF-8 - convert empty with BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: true);
      expect(encoder.convert("", 0, 3), Utf.bytesUtf8.sublist(0, 3));
    });
    test('UTF-8 - convert start with BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: true);
      expect(encoder.convert("Abc", 0, 1), Utf.bytesUtf8.sublist(0, 4));
    });
    test('UTF-8 - convert middle, no BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: false);
      expect(encoder.convert("Abc", 1, 3), Utf.bytesUtf8.sublist(4, 6));
    });
    test('UTF-8 - convert complex with BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf8, withBom: true);
      expect(encoder.convert(Utf.complexStr), Utf.bytesUtf8);
    });
    test('UTF-32BE - convert empty no BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf32be, withBom: false);
      expect(encoder.convert("", 0, 3), Utf.bytesEmpty);
    });
    test('UTF-32BE - convert empty with BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf32be, withBom: true);
      expect(encoder.convert("", 0, 3), Utf.bytesUtf32be.sublist(0, 4));
    });
    test('UTF-32BE - convert start with BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf32be, withBom: true);
      expect(encoder.convert("Abc", 0, 1), Utf.bytesUtf32be.sublist(0, 8));
    });
    test('UTF-32LE - convert middle, no BOM', () {
      final encoder =
          UtfEncoderSink(id: null, type: UtfType.utf32be, withBom: false);
      expect(encoder.convert("Abc", 1, 3), Utf.bytesUtf32be.sublist(8, 16));
    });
  });
}
