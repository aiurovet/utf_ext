import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

import 'utf_abc.dart';

/// A suite of tests for UtfEncoder
///
void main() {
  final file = UtfAbc.getDummyFile();

  group('convert -', () {
    test('start with BOM', () {
      UtfAbc.forEachTypeSync(file, (type, _) async {
        final encoder =
            UtfEncoder(null, hasSink: false, type: type, withBom: null);
        final bomLen = type.getBomLength(true);
        final charLen = type.getMinCharLength(true);
        final expected = UtfAbc.getBytes(type).sublist(0, bomLen + charLen);
        expect(encoder.convert(UtfAbc.complexStr, 0, 1), expected);
      });
    });
    test('middle, no BOM', () {
      UtfAbc.forEachTypeSync(file, (type, _) async {
        final encoder =
            UtfEncoder(null, hasSink: false, type: type, withBom: false);
        final bomLen = type.getBomLength(true);
        final charLen = type.getMinCharLength(true);
        final expected = UtfAbc.getBytes(type)
            .sublist(bomLen + 1 * charLen, bomLen + 3 * charLen);
        expect(encoder.convert(UtfAbc.complexStr, 1, 3), expected);
      });
    });
    test('complex, no BOM', () {
      UtfAbc.forEachTypeSync(file, (type, _) async {
        final encoder =
            UtfEncoder(null, hasSink: false, type: type, withBom: false);
        final bomLen = type.getBomLength(true);
        final expected = UtfAbc.getBytes(type).sublist(bomLen);
        expect(encoder.convert(UtfAbc.complexStr), expected);
      });
    });
    test('complex with BOM', () {
      UtfAbc.forEachTypeSync(file, (type, _) async {
        final encoder =
            UtfEncoder(null, hasSink: false, type: type, withBom: null);
        expect(encoder.convert(UtfAbc.complexStr), UtfAbc.getBytes(type));
      });
    });
  });
}
