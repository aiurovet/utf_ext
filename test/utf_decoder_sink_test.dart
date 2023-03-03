import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

import 'utf_abc.dart';

/// A suite of tests for UtfDecoderSink
///
void main() {
  final file = UtfAbc.getDummyFile();

  group('UtfDecoderSink - convert -', () {
    test('onBom', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        var wasCalled = false;
        UtfDecoderSink(null, onBom: (type, isWrite) => wasCalled = true, type: type);
        expect(wasCalled, true);
      });
    });
    test('empty', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final decoder = UtfDecoderSink(null, type: type);
        expect(decoder.convert(<int>[]), '');
      });
    });
    test('just BOM', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final decoder = UtfDecoderSink(null, type: type);
        expect(decoder.convert(UtfAbc.getBytes(type), 0, type.getBomLength(false)), '');
      });
    });
    test('change of BOM', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final newType = (type == UtfType.utf32be ? UtfType.utf8 : UtfType.utf32be);
        final decoder = UtfDecoderSink(null, type: type);
        decoder.convert(UtfAbc.getBytes(newType), 0, 1);
        expect(decoder.type, newType);
      });
    });
    test('convert - start', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final decoder = UtfDecoderSink(null, type: type);
        final bomLen = type.toFinal(false).getBomLength(false);
        final minCharLen = type.getMinCharLength(false);
        final result = decoder.convert(UtfAbc.getBytes(type), 0, bomLen + 3 * minCharLen);
        expect(result, UtfAbc.complexStr.substring(0, 3));
      });
    });
    test('convert - middle', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final decoder = UtfDecoderSink(null, type: type);
        final bomLen = type.getBomLength(false);
        final minCharLen = type.getMinCharLength(false);
        final result = decoder.convert(UtfAbc.getBytes(type), bomLen + 1 * minCharLen, bomLen + 3 * minCharLen);
        expect(result, UtfAbc.complexStr.substring(1, 3));
      });
    });


    // test('UTF-32BE - onBom', () {
    //   var wasCalled = false;
    //   UtfDecoderSink(
    //       null,
    //       onBom: (type, isWrite) => wasCalled = true,
    //       type: UtfType.utf32be);
    //   expect(wasCalled, true);
    // });
    // test('UTF-32BE - empty', () {
    //   final decoder = UtfDecoderSink(null, type: UtfType.utf32be);
    //   expect(decoder.convert(<int>[]), '');
    // });
    // test('UTF-32BE - just BOM', () {
    //   final decoder = UtfDecoderSink(null, type: UtfType.utf32be);
    //   expect(decoder.convert(UtfAbc.bytesUtf32be, 0, 4), '');
    // });
    // test('UTF-32BE - change of BOM', () {
    //   final decoder = UtfDecoderSink(null, type: UtfType.utf32be);
    //   decoder.convert(UtfAbc.bytesUtf8, 0, 4);
    //   expect(decoder.type, UtfType.utf8);
    // });
    // test('UTF-32BE - convert start', () {
    //   final decoder = UtfDecoderSink(null, type: UtfType.utf32be);
    //   expect(decoder.convert(UtfAbc.bytesUtf32be, 0, 4 * (1 + 10)),
    //       UtfAbc.complexStr.substring(0, 10));
    // });
    // test('UTF-32BE - convert middle', () {
    //   final decoder = UtfDecoderSink(null, type: UtfType.utf32be);
    //   expect(decoder.convert(UtfAbc.bytesUtf32be, 8), UtfAbc.complexStr.substring(1));
    // });
  });
}
