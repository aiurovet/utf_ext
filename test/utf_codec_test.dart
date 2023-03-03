import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

import 'utf_abc.dart';

/// A suite of tests for UtfCodec
///
void main() {
  final file = UtfAbc.getDummyFile();

  group('UtfCodec - constructor -', () {
    test('for each', () {
      UtfAbc.forEachTypeSync(file, (type, file) async {
        final codec = UtfCodec(null, hasSink: false, type: type);
        expect([codec.decoder.type, codec.encoder.type], [type, type]);
      });
    });
  });
}
