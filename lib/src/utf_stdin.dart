// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:io';
import 'package:utf_ext/utf_ext.dart';

/// Class for the formatted output
///
extension UtfStdin on Stdin {
  /// Const: flag indicating the current OS is not Windows
  ///
  bool get isPosixOS => !Platform.isWindows;

  /// Const: name for stdin
  ///
  static const name = '<stdin>';

  /// Loop through every line and call user-defined function (non-blocking)
  /// Optionally, you can get the list of all lines by passing [lines]
  ///
  Future<void> readAsLines(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandler? onLine,
          List<String>? pileup}) async =>
      await openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: true)
          .readUtfAsLines(extra: extra, onLine: onLine, pileup: pileup);

  /// Loop through every line and call user-defined function (blocking)
  /// Optionally, you can get the list of all lines by passing [pileup]
  ///
  void readAsLinesSync(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandlerSync? onLine,
          List<String>? pileup}) {
    UtfHelper.readAsLinesSync(name,
        extra: extra,
        maxLength: null,
        onBom: onBom,
        onByteIo: readIntoSync,
        onUtfIo: onLine,
        pileup: pileup,
        withPosixLineBreaks: isPosixOS);
  }

  /// Read the number of bytes (blocking) and return the number of bytes read
  ///
  int readIntoSync(List<int> bytes, [int start = 0, int? end]) {
    end ??= bytes.length;

    for (var i = start; i < end; i++) {
      final byte = readByteSync();

      if (byte == -1) {
        return (i - start);
      }

      bytes[i] = byte;
    }

    return end - start;
  }

  /// Read stdin content as UTF (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<void> readUtfAsString(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandler? onUtfIo,
          StringBuffer? pileup,
          bool? withPosixLineBreaks = true}) async =>
      await openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: false)
          .readUtfAsString(
              extra: extra,
              onUtfIo: onUtfIo,
              pileup: pileup,
              withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  void readUtfAsStringSync(
      {dynamic extra,
      UtfBomHandler? onBom,
      UtfIoHandlerSync? onUtfIo,
      StringBuffer? pileup,
      bool? withPosixLineBreaks = true}) =>
    UtfHelper.readAsStringSync(name,
        extra: extra,
        onBom: onBom,
        onByteIo: readIntoSync,
        onUtfIo: onUtfIo,
        pileup: pileup,
        withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);
}
