import 'dart:convert';

import 'package:utf_ext/utf_ext.dart';

class UtfDecoder extends Converter<List<int>, String> {
  /// Stream name, can be file path
  ///
  final String? id;

  /// UTF BOM handler
  ///
  UtfBomHandler? _onBom;

  /// Actual decoder
  ///
  UtfDecoderSink? _sink;

  /// UTF type
  ///
  UtfType get type => _type;
  UtfType _type = UtfType.none;

  /// Default constructor
  ///
  UtfDecoder(this.id, {UtfBomHandler? onBom, UtfType type = UtfType.none}) {
    _init(onBom, type);
  }

  /// Implementation of [convert]
  ///
  @override
  String convert(List<int> input) => _sink?.convert(input) ?? '';

  /// Initializer
  ///
  void _init(UtfBomHandler? onBom, UtfType type) {
    _onBom = onBom;
    _type = type;
  }

  /// Implementation of [startChunkedConversion]
  ///
  @override
  ByteConversionSink startChunkedConversion(Sink<String> sink) {
    StringConversionSink stringSink;

    if (sink is StringConversionSink) {
      stringSink = sink;
    } else {
      stringSink = StringConversionSink.from(sink);
    }

    _sink =
        UtfDecoderSink(id: id, onBom: _onBom, sink: stringSink, type: _type);

    return _sink!;
  }
}
