import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:utf_ext/utf_ext.dart';

/// Supplementary class for chunked conversion implementation
///
class UtfDecoderSink extends ByteConversionSinkBase {
  /// Flag indicating the CPU has big-endian architecture
  ///
  static final bool isBigEndianHost = (Endian.host == Endian.big);

  /// Length of the BOM found
  ///
  int get bomLength => _bomLength;
  int _bomLength = 0;

  /// List of bytes not forming a proper code unit because
  /// there are more data to come in the next round
  ///
  final List<int> _deferred = [];

  /// Length of the good (converted) block
  ///
  var _goodLength = 0;

  /// Last converted characters
  ///
  var _goodEnding = '';

  /// Flag indicating the stream is in big-endian format
  ///
  bool get isBigEndianData => _isBigEndianData;
  bool _isBigEndianData = false;

  /// Flag indicating the stream is in UTF-16 format (BE or LE)
  ///
  bool get isFixedLengthShort => _isFixedLengthShort;
  bool _isFixedLengthShort = false;

  /// Flag indicating the stream is UTF-8
  ///
  var _isFixedLength = false;

  /// Character length (2 for UTF-16, and 4 for UTF-8 and UTF-32)
  ///
  int get maxCharLength => _maxCharLength;
  int _maxCharLength = 0;

  /// Identifier (path, name, etc.)
  ///
  final String? id;

  /// Callback to notify about BOM identified
  ///
  UtfBomHandler? _onBom;

  /// Associated sink (actual decoder)
  ///
  Sink? _sink;

  /// Kind of UTF
  ///
  UtfType get type => _type;
  UtfType _type = UtfType.none;

  /// Default constructor
  ///
  UtfDecoderSink(
      {this.id,
      UtfBomHandler? onBom,
      Sink? sink,
      UtfType type = UtfType.none}) {
    _onBom = onBom;
    _init(sink, type);
  }

  /// Implementation of [close]
  ///
  @override
  void close() => _sink?.close();

  /// Implementation of [add]
  ///
  @override
  void add(List<int> chunk) => _sink?.add(convert(chunk));

  /// Implementation of [addSlice]
  ///
  @override
  void addSlice(List<int> chunk, int start, int end, bool isLast) {
    var length = chunk.length;
    RangeError.checkValidRange(start, end, length);

    if ((start > 0) || (end < length)) {
      add(chunk.sublist(start, end));
    } else {
      add(chunk);
    }

    if (isLast) {
      if (_deferred.isNotEmpty) {
        _fail();
      }

      close();
    }
  }

  /// Actual bytes to string converter for any type of UTF
  ///
  String convert(List<int> source, [int start = 0, int? end]) {
    if ((_goodLength == 0) && (start == 0)) {
      _init(null, UtfType.fromBom(source, source.length));
      start = _bomLength;
      _goodLength = start;
    }

    var result = _isFixedLength
        ? _convertFixLen(source, start, end)
        : _convertVarLen(source, start, end);

    _goodEnding = UtfException.getEnding(result);
    _goodLength += source.length;

    return result;
  }

  /// Actual bytes to string converter for the fixed length UTF (16 or 32)
  ///
  String _convertFixLen(List<int> source, int start, [int? end]) {
    if (_deferred.isNotEmpty) {
      source.insertAll(0, _deferred);
      _deferred.clear();
    }

    end ??= source.length;

    var output = <int>[];

    var b0 = 0, b1 = 0, b2 = 0, b3 = 0;
    final last = end - (end % _maxCharLength);

    for (var cur = start; cur < end;) {
      if (cur >= last) {
        _deferred.addAll(source.sublist(last, end));
        break;
      }

      b0 = source[cur++];
      b1 = source[cur++];

      var charCode = 0;

      if (_isFixedLengthShort) {
        if (_isBigEndianData) {
          charCode = (b0 << 8) | b1;
        } else {
          charCode = (b1 << 8) | b0;
        }
      } else {
        b2 = source[cur++];
        b3 = source[cur++];

        if (_isBigEndianData) {
          charCode = (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
        } else {
          charCode = (b3 << 24) | (b2 << 16) | (b1 << 8) | b0;
        }
      }

      _addCharCode(output, charCode, null, null);
    }

    return String.fromCharCodes(output);
  }

  /// Actual bytes to string converter for for the variable length UTF (8)
  ///
  String _convertVarLen(List<int> source, int start, [int? end]) {
    var output = <int>[];
    var b0 = 0, b1 = 0, b2 = 0, b3 = 0, charCode = 0;

    if (_deferred.isNotEmpty) {
      source.insertAll(0, _deferred);
      _deferred.clear();
    }

    end ??= source.length;

    for (var cur = start; cur < end;) {
      b0 = source[cur++];

      if (b0 < 0x80) {
        _addCharCode(output, b0, null, null);
        continue;
      }

      if (cur >= end) {
        _deferred.add(source[cur - 1]);
        break;
      }

      b1 = source[cur++];

      if (b0 < 0xE0) {
        charCode = ((b0 & 0x1F) << 6);
        charCode |= ((b1 & 0x3F));
        _addCharCode(output, charCode, 0x80, 0x7FF);
        continue;
      }

      if (cur >= end) {
        _deferred.add(source[cur - 2]);
        break;
      }

      b2 = source[cur++];

      if (b0 < 0xF0) {
        charCode = ((b0 & 0x0F) << 12);
        charCode |= ((b1 & 0x3F) << 6);
        charCode |= ((b2 & 0x3F));
        _addCharCode(output, charCode, 0x800, 0xFFFF);
        continue;
      }

      if (cur >= end) {
        _deferred.add(source[cur - 3]);
        break;
      }

      b3 = source[cur++];

      if (b0 < 0xF8) {
        charCode = ((b0 & 0x07) << 18);
        charCode |= ((b1 & 0x3F) << 12);
        charCode |= ((b2 & 0x3F) << 6);
        charCode |= ((b3 & 0x3F));
        _addCharCode(output, charCode, 0x010000, 0x10FFFF);
        continue;
      }

      _fail();
    }

    return String.fromCharCodes(output);
  }

  /// Initializer, called twice: in the beginning and once BOM found
  ///
  FutureOr<void> _init(Sink? sink, UtfType finalType) async {
    final isBomDone = ((sink == null) || (sink == _sink));

    if (!isBomDone) {
      _sink = sink;
    }

    _bomLength = finalType.getBomLength();
    _type = (finalType == UtfType.none ? UtfType.fallback : finalType);

    _isBigEndianData = _type.isBigEndian();
    _isFixedLengthShort = _type.isShortFixedLength();
    _isFixedLength = _type.isFixedLength();
    _maxCharLength = _type.getMaxCharLength();

    if (isBomDone && (_onBom != null)) {
      if (_onBom is UtfBomHandlerSync) {
        _onBom!(finalType, false);
      } else {
        await _onBom!(finalType, false);
      }
    }
  }

  /// Add code unit (rune)
  ///
  void _addCharCode(List<int> output, int charCode, int? min, int? max) {
    if (((min != null) && (charCode < min)) ||
        ((max != null) && (charCode > max))) {
      _fail();
    }

    if (charCode < 0x10000) {
      output.add(charCode);
    } else {
      charCode -= 0x10000;
      final lo = 0xD800 | ((charCode >> 10) & 0x3FF);
      final hi = 0xDC00 | (charCode & 0x3FF);

      output.add(isBigEndianHost ? hi : lo);
      output.add(isBigEndianHost ? lo : hi);
    }
  }

  /// Central point for exception throwing
  ///
  Never _fail() {
    throw UtfException(id, _type, _goodEnding, _goodLength);
  }
}
