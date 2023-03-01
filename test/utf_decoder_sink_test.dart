import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

import 'utf.dart';

/// A suite of tests for UtfDecoderSink
///
void main() {
  group('convert -', () {
    test('UTF-8 - onBom', () {
      var wasCalled = false;
      UtfDecoderSink(
          id: null,
          onBom: (type, isWrite) => wasCalled = true,
          type: UtfType.utf8);
      expect(wasCalled, true);
    });
    test('UTF-8 - empty', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf8);
      expect(decoder.convert(<int>[]), "");
    });
    test('UTF-8 - just BOM', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf8);
      expect(decoder.convert(Utf.bytesUtf8, 0, 3), "");
    });
    test('UTF-8 - change of BOM', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf8);
      decoder.convert(Utf.bytesUtf32be, 0, 3);
      expect(decoder.type, UtfType.utf32be);
    });
    test('UTF-8 - convert start', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf8);
      expect(decoder.convert(Utf.bytesUtf8), Utf.complexStr);
    });
    test('UTF-8 - convert middle', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf8);
      expect(decoder.convert(Utf.bytesUtf8, 4), Utf.complexStr.substring(1));
    });
    test('UTF-32BE - onBom', () {
      var wasCalled = false;
      UtfDecoderSink(
          id: null,
          onBom: (type, isWrite) => wasCalled = true,
          type: UtfType.utf32be);
      expect(wasCalled, true);
    });
    test('UTF-32BE - empty', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf32be);
      expect(decoder.convert(<int>[]), "");
    });
    test('UTF-32BE - just BOM', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf32be);
      expect(decoder.convert(Utf.bytesUtf32be, 0, 4), "");
    });
    test('UTF-32BE - change of BOM', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf32be);
      decoder.convert(Utf.bytesUtf8, 0, 4);
      expect(decoder.type, UtfType.utf8);
    });
    test('UTF-32BE - convert start', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf32be);
      expect(decoder.convert(Utf.bytesUtf32be, 0, 4 * (1 + 10)),
          Utf.complexStr.substring(0, 10));
    });
    test('UTF-32BE - convert middle', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf32be);
      expect(decoder.convert(Utf.bytesUtf32be, 8), Utf.complexStr.substring(1));
    });
  });
}
