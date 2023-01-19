import 'dart:typed_data';

enum UtfType {
  none,
  utf8,
  utf16be,
  utf16le,
  utf32be,
  utf32le;

  /// Determine UTF type based on a sequence of bytes
  ///
  static UtfType fromBom(List<int> buffer, int length) {
    if (length <= 0) {
      return UtfType.none;
    }

    final bom = Uint8List.fromList(buffer);

    switch (bom[0]) {
      case 0x00:
        if ((length < 2) || bom[1] != 0x00) {
          return UtfType.none;
        }
        if ((length >= 4) && (bom[2] == 0xFE) && (bom[3] == 0xFF)) {
          return UtfType.utf32be;
        }
        return UtfType.none;
      case 0xEF:
        if ((length < 3) || (bom[1] != 0xBB) || (bom[2] != 0xBF)) {
          return UtfType.none;
        }
        return UtfType.utf8;
      case 0xFE:
        if ((length < 2) || (bom[1] != 0xFF)) {
          return UtfType.none;
        }
        return UtfType.utf16be;
      case 0xFF:
        if ((length < 2) || (bom[1] != 0xFE)) {
          return UtfType.none;
        }
        if ((length >= 4) && (bom[2] == 0x00) && (bom[3] == 0x00)) {
          return UtfType.utf32le;
        }
        return UtfType.utf16le;
      default:
        return UtfType.none;
    }
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

  /// Get maximum character length
  ///
  int getMaxCharLength() => ((this == utf16be) || (this == utf16le) ? 2 : 4);

  /// A minimum number of bytes representing a character
  ///
  int getMinCharLength() {
    switch (this) {
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

  bool isBigEndian() => ((this == utf16be) || (this == utf32be));

  /// Flag separating null/UTF-8 and UTF-16/32
  ///
  bool isFixedLength() => (this != none) && (this != utf8);

  bool isShortFixedLength() => ((this == utf16be) || (this == utf16le));

  @override
  String toString() =>
      '${name.substring(0, 3)}-${name.substring(3)}'.toUpperCase();
}