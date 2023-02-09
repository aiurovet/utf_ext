import 'dart:async';
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

  /// Associated sink (actual encoder)
  ///
  Sink? _sink;

  /// Kind of UTF
  ///
  UtfType get type => _type;
  UtfType _type = UtfType.none;

  /// Flag indicating BOM is required to precede the actual bytes
  ///
  var _withBom = true;

  /// Default constructor
  ///
  UtfEncoderSink(
      {this.id,
      Sink? sink,
      UtfType type = UtfType.none,
      bool withBom = true}) {
    _init(sink, type, withBom);
  }

  /// Implementation of [close]
  ///
  @override
  void close() => _sink?.close();

  /// Implementation of [add]
  ///
  @override
  void add(String chunk) => _sink?.add(convert(chunk));

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
    var len = source.length;
    end ??= len;

    if ((start > 0) || (end < len)) {
      source = source.substring(start, end);
    }

    final output = (_withBom && (start == 0) ? _type.toBom(true) : UtfType.emptyBom).toList();

    _withBom = false;

    final isFixLen = _type.isFixedLength(true);
    final isShort = _type.isFixedLengthShort(true);

    final charCodes = (isShort
      ? source.codeUnits
      : source.runes.toList(growable: false));

    if (_isFixedLengthShort && (_isBigEndianData == isBigEndianHost)) {
      output.addAll(charCodes);
      return Uint8List.fromList(output);
    }

    len = charCodes.length;

    for (var cur = 0; cur < len; cur++) {
      var charCode = charCodes[cur];

      if (isShort) {
        // Swap bytes in UTF-16
        //
        charCode = (charCode >> 8) | ((charCode & 0xFF) << 8);
        output.add(charCode);
      } else if (isFixLen) {
        // Swap bytes in UTF-32
        //
        charCode = (charCode >> 24) | (((charCode >> 16) & 0xFF) << 8) | (((charCode >> 8) & 0xFF) << 16) | ((charCode & 0xFF) << 24);
        output.add(charCode);
      } else if ((charCode & 0x800000000) == 0) {
        // 1-byte character in UTF-8
        //
        output.add(charCode >> 24);
      } else if ((charCode & 0xC080) == 0xC080) {
        // 2-byte character in UTF-8
        //
        output.add((charCode >> 24) & 0x1F);
        output.add((charCode >> 16) & 0x3F);
      } else if ((charCode & 0xE08080) == 0xE08080) {
        // 3-byte character in UTF-8
        //
        output.add((charCode >> 24) & 0x0F);
        output.add((charCode >> 16) & 0x3F);
        output.add((charCode >>  8) & 0x3F);
      } else if ((charCode & 0xF0808080) == 0xF0808080) {
        // 4-byte character in UTF-8
        //
        output.add((charCode >> 24) & 0x07);
        output.add((charCode >> 16) & 0x3F);
        output.add((charCode >>  8) & 0x3F);
        output.add(charCode & 0x3F);
      } else {
        _fail(source);
      }
    }

    return Uint8List.fromList(output);
  }

  /// Initializer, called twice: in the beginning and once BOM found
  ///
  FutureOr<void> _init(Sink? sink, UtfType finalType, bool withBom) async {
    if (sink != null) {
      _sink = sink;
    }

    _bomLength = finalType.getBomLength(true);
    _type = (finalType == UtfType.none ? UtfType.fallbackForWrite : finalType);
    _withBom = withBom;

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
