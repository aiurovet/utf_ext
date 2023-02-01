import 'dart:typed_data';

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
    none:    noBom,
    utf8:    Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF]),
    utf16be: Uint8List.fromList(<int>[0xFE, 0xFF]),
    utf16le: Uint8List.fromList(<int>[0xFF, 0xFE]),
    utf32be: Uint8List.fromList(<int>[0x00, 0x00, 0xFE, 0xFF]),
    utf32le: Uint8List.fromList(<int>[0xFF, 0xFE, 0x00, 0x00]),
  };

  /// Const: type to BOM mapping
  ///
  static final noBom = Uint8List.fromList(<int>[]);

  /// How to treat files or streams without BOM
  ///
  static var fallback = UtfType.utf8;

  /// Determine UTF type based on a sequence of bytes
  ///
  static UtfType fromBom(List<int> buffer, int length) {
    final bom = Uint8List.fromList(buffer);
    return _bomMap.keys.firstWhere((x) => _bomMap[x] == bom, orElse: () => none);
  }

  /// Get BOM length
  ///
  int getBomLength() {
    switch (this) {
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
  int getMaxCharLength() {
    switch (this == none ? fallback : this) {
      case UtfType.utf16be:
      case UtfType.utf16le:
        return 2;
      default:
        return 4;
    }
  }

  /// Get minimum number of bytes representing a character
  ///
  int getMinCharLength() {
    switch (this == none ? fallback : this) {
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
  bool isBigEndian() {
    switch (this == none ? fallback : this) {
      case utf16be:
      case utf32be:
        return true;
      default:
        return false;
    }
  }

  /// Flag separating none/UTF-8 and UTF-16/32
  ///
  bool isFixedLength() {
    switch (this == none ? fallback : this) {
      case none:
      case utf8:
        return false;
      default:
        return true;
    }
  }

  /// Check whether this is a 2-byte Unicode
  ///
  bool isShortFixedLength() {
    switch (this == none ? fallback : this) {
      case utf16be:
      case utf16le:
        return true;
      default:
        return false;
    }
  }

  /// Convert type to BOM
  ///
  Uint8List toBom({bool useFallback = false}) =>
      _bomMap[useFallback && (this == none) ? fallback : this]!;

  /// Convert type to BOM
  ///
  UtfType toFinal() => (this == none ? fallback : this);

  /// Serialize
  ///
  @override
  String toString() =>
      (this == none ? name : '${name.substring(0, 3)}-${name.substring(3)}')
          .toUpperCase();
}
