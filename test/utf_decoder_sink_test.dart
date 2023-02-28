import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

/// A suite of tests for UtfDecoderSink
///
void main() {
  final abcUtf8 = <int>[
    0xEF,
    0xBB,
    0xBF,
    0x41,
    0x42,
    0x43,
  ];
  final abcUtf32be = <int>[
    0x00,
    0x00,
    0xFE,
    0xFF,
    0x00,
    0x00,
    0x00,
    0x41,
    0x00,
    0x00,
    0x00,
    0x42,
    0x00,
    0x00,
    0x00,
    0x43,
  ];

  group('constructor -', () {
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
      expect(decoder.convert(abcUtf8, 0, 3), "");
    });
    test('UTF-8 - change of BOM', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf8);
      decoder.convert(abcUtf32be, 0, 3);
      expect(decoder.type, UtfType.utf32be);
    });
    test('UTF-8 - convert start', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf8);
      expect(decoder.convert(abcUtf8), "ABC");
    });
    test('UTF-8 - convert middle', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf8);
      expect(decoder.convert(abcUtf8, 4), "BC");
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
      expect(decoder.convert(abcUtf32be, 0, 4), "");
    });
    test('UTF-32BE - change of BOM', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf32be);
      decoder.convert(abcUtf8, 0, 4);
      expect(decoder.type, UtfType.utf8);
    });
    test('UTF-32BE - convert start', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf32be);
      expect(decoder.convert(abcUtf32be), "ABC");
    });
    test('UTF-32BE - convert middle', () {
      final decoder = UtfDecoderSink(id: null, type: UtfType.utf32be);
      expect(decoder.convert(abcUtf32be, 8), "BC");
    });
  });
}
