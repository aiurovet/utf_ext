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
  UtfDecoder(this.id,
      {bool hasSink = true,
      UtfBomHandler? onBom,
      Sink<String>? sink,
      UtfType type = UtfType.none}) {
    _init(hasSink, onBom, sink, type);
  }

  /// Implementation of [convert]
  ///
  @override
  String convert(List<int> input, [int start = 0, int? end]) {
    if (_sink == null) {
      return '';
    }

    final result = _sink!.convert(input, start, end);

    if (start == 0) {
      _type = _sink!.type;
    }

    return result;
  }

  /// Initializer
  ///
  void _init(
      bool hasSink, UtfBomHandler? onBom, Sink<String>? sink, UtfType type) {
    _onBom = onBom;
    _type = type;

    if (!hasSink) {
      startChunkedConversion(sink);
    }
  }

  /// Implementation of [startChunkedConversion]
  ///
  @override
  ByteConversionSink startChunkedConversion(Sink<String>? sink) {
    StringConversionSink? stringSink;

    if (sink is StringConversionSink) {
      stringSink = sink;
    } else if (sink != null) {
      stringSink = StringConversionSink.from(sink);
    }

    _sink = UtfDecoderSink(
        id, onBom: _onBom, strConvSink: stringSink, type: _type);

    return _sink!;
  }
}
