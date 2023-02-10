import 'dart:convert';

import 'package:utf_ext/utf_ext.dart';

/// Container class for decoder and encoder
///
class UtfCodec extends Codec<String, List<int>> {
  /// The actual decoder
  ///
  @override
  UtfDecoder get decoder => _decoder;
  late final UtfDecoder _decoder;

  /// The actual encoder
  ///
  @override
  UtfEncoder get encoder => _encoder;
  late final UtfEncoder _encoder;

  /// Default constructor
  ///
  UtfCodec(id,
      {UtfBomHandler? onBom,
      UtfType type = UtfType.none,
      bool withBom = true}) {
    _decoder = UtfDecoder(id, type: type, onBom: onBom);
    _encoder = UtfEncoder(id, type: type);
  }
}
