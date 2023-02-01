import 'dart:convert';
import 'dart:typed_data';

import 'package:utf_ext/utf_ext.dart';

class UtfEncoder extends Converter<String, List<int>> {
  /// Stream name, can be file path
  ///
  final String? id;

  /// Actual encoder
  ///
  UtfEncoderSink? _sink;

  /// UTF type
  ///
  UtfType get type => _type;
  UtfType _type = UtfType.none;

  /// Default constructor
  ///
  UtfEncoder(this.id, {UtfType type = UtfType.none}) {
    _init(type);
  }

  /// Implementation of [convert]
  ///
  @override
  Uint8List convert(String input) => _sink?.convert(input) ?? UtfType.noBom;

  /// Initializer
  ///
  void _init(UtfType type) {
    _type = type;
  }

  /// Implementation of [startChunkedConversion]
  ///
  @override
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) {
    ByteConversionSink byteSink;

    if (sink is ByteConversionSink) {
      byteSink = sink;
    } else {
      byteSink = ByteConversionSink.from(sink);
    }

    _sink = UtfEncoderSink(id: id, sink: byteSink, type: _type);

    return _sink!;
  }
}
