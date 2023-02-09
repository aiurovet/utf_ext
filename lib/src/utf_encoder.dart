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

  /// Flag indicating BOM is required to precede the actual bytes
  /// Gets passed to UtfEncoderSink upon the start of conversion
  ///
  var _withBom = true;

  /// Default constructor
  ///
  UtfEncoder(this.id, {Sink<List<int>>? sink, UtfType type = UtfType.none, bool withBom = true}) {
    _init(sink, type, withBom);
  }

  /// Implementation of [convert]
  ///
  @override
  Uint8List convert(String input) => _sink?.convert(input) ?? UtfType.emptyBom;

  /// Initializer
  ///
  void _init(Sink<List<int>>? sink, UtfType type, bool withBom) {
    _type = type;
    _withBom = withBom;

    if (sink != null) {
      _sink = UtfEncoderSink(id: id, sink: sink, type: _type, withBom: _withBom);
    }
  }

  /// Implementation of [startChunkedConversion]
  ///
  @override
  StringConversionSink startChunkedConversion(Sink<List<int>> sink) {
    if (_sink != null) {
      return _sink!;
    }

    ByteConversionSink byteSink;

    if (sink is ByteConversionSink) {
      byteSink = sink;
    } else {
      byteSink = ByteConversionSink.from(sink);
    }

    _sink = UtfEncoderSink(id: id, sink: byteSink, type: _type, withBom: _withBom);

    return _sink!;
  }
}
