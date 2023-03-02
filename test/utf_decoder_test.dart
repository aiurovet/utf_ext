import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

import 'utf_abc.dart';

/// A suite of tests for UtfDecoder
///
void main() {
  group('convert -', () {
    test('UTF-8 - onBom', () {
      var wasCalled = false;
      UtfDecoder(null, hasSink: false, onBom: (type, isWrite) => wasCalled = true, type: UtfType.utf8)
          .convert(Uint8List.fromList(UtfType.utf8.toBom(false)..addAll([0x41])));
      expect(wasCalled, true);
    });
    test('UTF-8 - empty', () {
      final decoder = UtfDecoder(null, hasSink: false, type: UtfType.utf8);
      expect(decoder.convert(<int>[]), '');
    });
    test('UTF-8 - just BOM', () {
      final decoder = UtfDecoder(null, hasSink: false, type: UtfType.utf8);
      expect(decoder.convert(UtfAbc.bytesUtf8, 0, 3), '');
    });
    test('UTF-8 - change of BOM', () {
      final decoder = UtfDecoder(null, hasSink: false, type: UtfType.utf8);
      decoder.convert(UtfAbc.bytesUtf32be, 0, 3);
      expect(decoder.type, UtfType.utf32be);
    });
    test('UTF-8 - convert start', () {
      final decoder = UtfDecoder(null, hasSink: false, type: UtfType.utf8);
      expect(decoder.convert(UtfAbc.bytesUtf8), UtfAbc.complexStr);
    });
    test('UTF-8 - convert middle', () {
      final decoder = UtfDecoder(null, hasSink: false, type: UtfType.utf8);
      expect(decoder.convert(UtfAbc.bytesUtf8, 4), UtfAbc.complexStr.substring(1));
    });
    test('UTF-32BE - onBom', () {
      var wasCalled = false;
      UtfDecoder(null, hasSink: false, onBom: (type, isWrite) => wasCalled = true, type: UtfType.utf32be)
          .convert(Uint8List.fromList(UtfType.utf32be.toBom(false)..addAll([0x00, 0x00, 0x00, 0x41])));
      expect(wasCalled, true);
    });
    test('UTF-32BE - empty', () {
      final decoder = UtfDecoder(null, hasSink: false, type: UtfType.utf32be);
      expect(decoder.convert(<int>[]), '');
    });
    test('UTF-32BE - just BOM', () {
      final decoder = UtfDecoder(null, hasSink: false, type: UtfType.utf32be);
      expect(decoder.convert(UtfAbc.bytesUtf32be, 0, 4), '');
    });
    test('UTF-32BE - change of BOM', () {
      final decoder = UtfDecoder(null, hasSink: false, type: UtfType.utf32be);
      decoder.convert(UtfAbc.bytesUtf8, 0, 4);
      expect(decoder.type, UtfType.utf8);
    });
    test('UTF-32BE - convert start', () {
      final decoder = UtfDecoder(null, hasSink: false, type: UtfType.utf32be);
      expect(decoder.convert(UtfAbc.bytesUtf32be, 0, 4 * (1 + 10)),
          UtfAbc.complexStr.substring(0, 10));
    });
    test('UTF-32BE - convert middle', () {
      final decoder = UtfDecoder(null, hasSink: false, type: UtfType.utf32be);
      expect(decoder.convert(UtfAbc.bytesUtf32be, 8), UtfAbc.complexStr.substring(1));
    });
  });
}
