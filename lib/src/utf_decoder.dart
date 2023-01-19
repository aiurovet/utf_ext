import 'dart:convert';

import 'package:utf_ext/utf_ext.dart';

class UtfDecoder extends Converter<List<int>, String> {
  final String? id; // stream name, can be file path

  late UtfDecoderSink? _sink;

  UtfType get type => _type;
  UtfType _type = UtfType.none;

  UtfDecoder(this.id, [UtfType type = UtfType.none]) {
    init(type);
  }

  @override
  String convert(List<int> input) => _sink?.convert(input) ?? '';

  void init(UtfType type) {
    _type = type;
    _sink = UtfDecoderSink(id, type);
  }

  @override
  ByteConversionSink startChunkedConversion(Sink<String> sink) {
    StringConversionSink stringSink;

    if (sink is StringConversionSink) {
      stringSink = sink;
    } else {
      stringSink = StringConversionSink.from(sink);
    }

    return UtfDecoderSink(id, _type, stringSink);
  }
}
