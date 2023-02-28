import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

/// A suite of tests for UtfCodec
///
void main() {
  group('constructor -', () {
    test('(none)', () {
      final codec = UtfCodec(null, hasSink: false, type: UtfType.none);
      expect([codec.decoder.type, codec.encoder.type],
          [UtfType.none, UtfType.none]);
    });
    test('UTF-8', () {
      final codec = UtfCodec(null, hasSink: false, type: UtfType.utf8);
      expect([codec.decoder.type, codec.encoder.type],
          [UtfType.utf8, UtfType.utf8]);
    });
    test('UTF-16BE', () {
      final codec = UtfCodec(null, hasSink: false, type: UtfType.utf16be);
      expect([codec.decoder.type, codec.encoder.type],
          [UtfType.utf16be, UtfType.utf16be]);
    });
    test('UTF-16LE', () {
      final codec = UtfCodec(null, hasSink: false, type: UtfType.utf16le);
      expect([codec.decoder.type, codec.encoder.type],
          [UtfType.utf16le, UtfType.utf16le]);
    });
    test('UTF-32BE', () {
      final codec = UtfCodec(null, hasSink: false, type: UtfType.utf32be);
      expect([codec.decoder.type, codec.encoder.type],
          [UtfType.utf32be, UtfType.utf32be]);
    });
    test('UTF-32LE', () {
      final codec = UtfCodec(null, hasSink: false, type: UtfType.utf32le);
      expect([codec.decoder.type, codec.encoder.type],
          [UtfType.utf32le, UtfType.utf32le]);
    });
  });
}
