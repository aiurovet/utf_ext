// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:convert';
import 'dart:typed_data';

import 'package:utf_ext/utf_ext.dart';

/// Supplementary class for chunked conversion implementation
///
class UtfEncoderSink extends StringConversionSinkBase {
  /// Flag indicating the CPU has big-endian architecture
  ///
  static final bool isBigEndianHost = UtfDecoderSink.isBigEndianHost;

  /// Length of the BOM found
  ///
  int get bomLength => _bomLength;
  int _bomLength = 0;

  /// Identifier (path, name, etc.)
  ///
  final String? id;

  /// Flag indicating the stream is in big-endian format
  ///
  bool get isBigEndianData => _isBigEndianData;
  bool _isBigEndianData = false;

  /// Flag indicating the stream is in UTF-16 format (BE or LE)
  ///
  bool get isFixedLengthShort => _isFixedLengthShort;
  bool _isFixedLengthShort = false;

  /// Flag indicating the stream is in UTF-16 or UTF-32 format (BE or LE)
  /// Will be set to false after the first chunk conversion
  ///
  bool get isFixedLength => _isFixedLength;
  var _isFixedLength = false;

  /// Character length (2 for UTF-16, and 4 for UTF-8 and UTF-32)
  ///
  int get maxCharLength => _maxCharLength;
  int _maxCharLength = 0;

  /// Associated conversion sink
  ///
  ByteConversionSink? _byteConvSink;

  /// Kind of UTF
  ///
  UtfType get type => _type;
  UtfType _type = UtfType.none;

  /// Flag indicating BOM is required to precede the actual bytes
  ///
  var _withBom = true;

  /// Default constructor
  ///
  UtfEncoderSink(this.id,
      {ByteConversionSink? byteConvSink,
      UtfType type = UtfType.none,
      bool? withBom}) {
    _init(byteConvSink, type, withBom);
  }

  /// Implementation of [close]
  ///
  @override
  void close() => _byteConvSink?.close();

  /// Implementation of [add]
  ///
  @override
  void add(String chunk) => _byteConvSink?.add(convert(chunk));

  /// Implementation of [addSlice]
  ///
  @override
  void addSlice(String chunk, int start, int end, bool isLast) {
    var length = chunk.length;
    RangeError.checkValidRange(start, end, length);

    if ((start > 0) || (end < length)) {
      add(chunk.substring(start, end));
    } else {
      add(chunk);
    }

    if (isLast) {
      close();
    }
  }

  /// Actual byte converter for any type of UTF
  ///
  Uint8List convert(String source, [int start = 0, int? end]) {
    var length = source.length;
    end ??= length;

    if ((start > 0) || (end < length)) {
      source = source.substring(start, end);
    }

    final output =
        (_withBom && (start == 0) ? _type.toBom(true) : UtfType.emptyBom)
            .toList();

    _withBom = false;

    final isFixLen = _type.isFixedLength(true);
    final isShort = _type.isFixedLengthShort(true);

    final charCodes =
        (isShort ? source.codeUnits : source.runes.toList(growable: false));

    length = charCodes.length;

    for (var cur = 0; cur < length; cur++) {
      var charCode = charCodes[cur];

      if (isShort) {
        // Swap bytes in UTF-16 if needed and write to the output
        //
        if (_isBigEndianData) {
          output.add((charCode >> 8) & 0xFF);
          output.add((charCode) & 0xFF);
        } else {
          output.add((charCode) & 0xFF);
          output.add((charCode >> 8) & 0xFF);
        }
      } else if (isFixLen) {
        // Swap bytes in UTF-32 if needed and write to the output
        //
        if (_isBigEndianData) {
          output.add((charCode >> 24) & 0xFF);
          output.add((charCode >> 16) & 0xFF);
          output.add((charCode >> 8) & 0xFF);
          output.add((charCode) & 0xFF);
        } else {
          output.add((charCode) & 0xFF);
          output.add((charCode >> 8) & 0xFF);
          output.add((charCode >> 16) & 0xFF);
          output.add((charCode >> 24) & 0xFF);
        }
      } else if (charCode <= 0x7F) {
        // 1-byte character in UTF-8
        //
        output.add(charCode);
      } else if (charCode <= 0x7FF) {
        // 2-byte character in UTF-8
        //
        output.add(0xC0 | (charCode >> 6));
        output.add(0x80 | (charCode & 0x3F));
      } else if (charCode <= 0xFFFF) {
        // 3-byte character in UTF-8
        //
        output.add(0xE0 | (charCode >> 12));
        output.add(0x80 | ((charCode >> 6) & 0x3F));
        output.add(0x80 | (charCode & 0x3F));
      } else if (charCode <= 0x10FFFF) {
        // 4-byte character in UTF-8
        //
        output.add(0xF0 | (charCode >> 18));
        output.add(0x80 | ((charCode >> 12) & 0x3F));
        output.add(0x80 | ((charCode >> 6) & 0x3F));
        output.add(0x80 | (charCode & 0x3F));
      } else {
        _fail(source);
      }
    }

    return Uint8List.fromList(output);
  }

  /// Initializer, called twice: in the beginning and once BOM found
  ///
  void _init(
      ByteConversionSink? byteConvSink, UtfType finalType, bool? withBom) {
    if (byteConvSink != null) {
      _byteConvSink = byteConvSink;
    }

    _bomLength = finalType.getBomLength(true);

    final isNone = (finalType == UtfType.none);
    _type = (isNone ? UtfConfig.fallbackForWrite : finalType);
    _withBom = withBom ?? !isNone;

    _isBigEndianData = _type.isBigEndian(true);
    _isFixedLength = _type.isFixedLength(true);
    _isFixedLengthShort = _type.isFixedLengthShort(true);
    _maxCharLength = _type.getMaxCharLength(true);
  }

  /// Central point for exception throwing
  ///
  Never _fail(String source) {
    final ending = UtfException.getEnding(source);
    throw UtfException(id, _type, ending, ending.length);
  }
}
