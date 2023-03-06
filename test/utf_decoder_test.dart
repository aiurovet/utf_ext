import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

import 'utf_abc.dart';

/// A suite of tests for UtfDecoder
///
void main() {
  final file = UtfAbc.getDummyFile();

  group('convert -', () {
    test('onBom', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        var wasCalled = false;
        UtfDecoder(null, hasSink: false, onBom: (type, isWrite) => wasCalled = true, type: type);
        expect(wasCalled, true);
      });
    });
    test('empty', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final decoder = UtfDecoder(null, hasSink: false, type: type);
        expect(decoder.convert(<int>[]), '');
      });
    });
    test('just BOM', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final decoder = UtfDecoder(null, hasSink: false, type: type);
        expect(decoder.convert(UtfAbc.getBytes(type), 0, type.getBomLength(false)), '');
      });
    });
    test('change of BOM', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final newType = (type == UtfType.utf32be ? UtfType.utf8 : UtfType.utf32be);
        final decoder = UtfDecoder(null, hasSink: false, type: type);
        decoder.convert(UtfAbc.getBytes(newType), 0, 1);
        expect(decoder.type, newType);
      });
    });
    test('start', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final decoder = UtfDecoder(null, hasSink: false, type: type);
        final bomLen = type.getBomLength(false);
        final minCharLen = type.getMinCharLength(false);
        final result = decoder.convert(UtfAbc.getBytes(type), 0, bomLen + 3 * minCharLen);
        expect(result, UtfAbc.complexStr.substring(0, 3));
      });
    });
    test('middle', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final decoder = UtfDecoder(null, hasSink: false, type: type);
        final bomLen = type.getBomLength(false);
        final minCharLen = type.getMinCharLength(false);
        final result = decoder.convert(UtfAbc.getBytes(type), bomLen + 1 * minCharLen, bomLen + 3 * minCharLen);
        expect(result, UtfAbc.complexStr.substring(1, 3));
      });
    });
    test('complex', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final decoder = UtfDecoder(null, hasSink: false, type: type);
        final result = decoder.convert(UtfAbc.getBytes(type));
        expect(result, UtfAbc.complexStr);
      });
    });
  });
}
