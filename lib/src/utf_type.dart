import 'dart:typed_data';

import 'package:utf_ext/src/iterable_ext.dart';

enum UtfType {
  /// Not defined yet (can use fallback)
  ///
  none,

  /// Up to 4 bytes per character
  ///
  utf8,

  /// 2 bytes per character, big endian
  ///
  utf16be,

  /// 2 bytes per character, little endian
  ///
  utf16le,

  /// 4 bytes per character, big endian
  ///
  utf32be,

  /// 4 bytes per character, little endian
  ///
  utf32le;

  /// Const: type to BOM mapping
  ///
  static final _bomMap = {
    none:    <int>[],
    utf8:    <int>[0xEF, 0xBB, 0xBF],
    utf16be: <int>[0xFE, 0xFF],
    utf16le: <int>[0xFF, 0xFE],
    utf32be: <int>[0x00, 0x00, 0xFE, 0xFF],
    utf32le: <int>[0xFF, 0xFE, 0x00, 0x00],
  };

  /// Const: type to BOM mapping
  ///
  static final cleanRE = RegExp(r'[_\.\-\s]+');

  /// Const: type to BOM mapping
  ///
  static final emptyBom = Uint8List.fromList([]);

  /// How to treat files or streams without BOM (for reading)
  ///
  static var fallbackForRead = UtfType.utf8;

  /// How to treat files or streams without BOM (for writing)
  ///
  static var fallbackForWrite = UtfType.utf8;

  /// Determine UTF type based on a sequence of bytes
  ///
  static UtfType fromBom(List<int> buffer) {
    return _bomMap.keys.firstWhere((x) => buffer.startsWith(_bomMap[x]!), orElse: () => none);
  }

  /// Get BOM length
  ///
  int getBomLength(bool forWrite) {
    switch (this == none ? (forWrite ? fallbackForWrite : fallbackForRead) : this) {
      case UtfType.utf8:
        return 3;
      case UtfType.utf16be:
      case UtfType.utf16le:
        return 2;
      case UtfType.utf32be:
      case UtfType.utf32le:
        return 4;
      default:
        return 0;
    }
  }

  /// Get maximum number of bytes representing a character
  ///
  int getMaxCharLength(bool forWrite) {
    switch (this == none ? (forWrite ? fallbackForWrite : fallbackForRead) : this) {
      case UtfType.utf16be:
      case UtfType.utf16le:
        return 2;
      default:
        return 4;
    }
  }

  /// Get minimum number of bytes representing a character
  ///
  int getMinCharLength(bool forWrite) {
    switch (this == none ? (forWrite ? fallbackForWrite : fallbackForRead) : this) {
      case utf16be:
      case utf16le:
        return 2;
      case utf32be:
      case utf32le:
        return 4;
      default:
        return 1;
    }
  }

  /// Check the endianness
  ///
  bool isBigEndian(bool forWrite) {
    switch (this == none ? (forWrite ? fallbackForWrite : fallbackForRead) : this) {
      case utf16be:
      case utf32be:
        return true;
      default:
        return false;
    }
  }

  /// Flag separating none/UTF-8 and UTF-16/32
  ///
  bool isFixedLength(bool forWrite) {
    switch (this == none ? (forWrite ? fallbackForWrite : fallbackForRead) : this) {
      case none:
      case utf8:
        return false;
      default:
        return true;
    }
  }

  /// Check whether this is a 2-byte Unicode
  ///
  bool isFixedLengthShort(bool forWrite) {
    switch (this == none ? (forWrite ? fallbackForWrite : fallbackForRead) : this) {
      case utf16be:
      case utf16le:
        return true;
      default:
        return false;
    }
  }

  /// Convert string to UTF type
  ///
  static UtfType parse(String? input, [UtfType defValue = none]) {
    final clean = input?.replaceAll(cleanRE, '').toLowerCase();

    if ((clean == null) || clean.isEmpty) {
      return defValue;
    }

    final value = values.firstWhere((x) => x.name == clean, orElse: () => none);

    return (value == none ? defValue : value);
  }

  /// Convert type to BOM
  ///
  List<int> toBom(bool forWrite, {bool useFallback = false}) =>
      _bomMap[useFallback && (this == none) ? (forWrite ? fallbackForWrite : fallbackForRead) : this]!;

  /// Convert type to BOM
  ///
  UtfType toFinal(bool forWrite) => (this == none ? (forWrite ? fallbackForWrite : fallbackForRead) : this);

  /// Serialize
  ///
  @override
  String toString() =>
      (this == none ? name : '${name.substring(0, 3)}-${name.substring(3)}')
          .toUpperCase();
}
