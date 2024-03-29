// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:convert';
import 'dart:typed_data';

import 'package:utf_ext/utf_ext.dart';

/// Class to perform the actual encoding to UTF file/stream
///
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
  UtfEncoder(this.id,
      {bool hasSink = true,
      Sink<List<int>>? sink,
      UtfType type = UtfType.none,
      bool? withBom}) {
    _init(hasSink, sink, type, withBom);
  }

  /// Implementation of [convert]
  ///
  @override
  Uint8List convert(String input, [int start = 0, int? end]) =>
      _sink?.convert(input, start, end) ?? UtfType.emptyBom;

  /// Initializer
  ///
  void _init(bool hasSink, Sink<List<int>>? sink, UtfType type, bool? withBom) {
    _type = type;
    _withBom = withBom ?? (type != UtfType.none);

    if (!hasSink || (sink != null)) {
      startChunkedConversion(sink);
    }
  }

  /// Implementation of [startChunkedConversion]
  ///
  @override
  StringConversionSink startChunkedConversion(Sink<List<int>>? sink) {
    if (_sink != null) {
      return _sink!;
    }

    ByteConversionSink? byteSink;

    if (sink is ByteConversionSink) {
      byteSink = sink;
    } else if (sink != null) {
      byteSink = ByteConversionSink.from(sink);
    }

    _sink = UtfEncoderSink(id,
        byteConvSink: byteSink, type: _type, withBom: _withBom);

    return _sink!;
  }
}
