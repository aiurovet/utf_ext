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
  Future<void> forEachLine(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfReadHandler? onLine,
          List<String>? pileup}) async =>
      await openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: true)
          .forEachUtfLine(extra: extra, onLine: onLine, pileup: pileup);

  /// Loop through every line and call user-defined function (blocking)
  /// Optionally, you can get the list of all lines by passing [pileup]
  ///
  void forEachLineSync(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfReadHandlerSync? onLine,
          List<String>? pileup}) =>
      openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: true)
          .forEachUtfLineSync(extra: extra, onLine: onLine, pileup: pileup);

  /// Read stdin content as UTF (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<String> readUtfAsString(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfReadHandler? onRead,
          StringBuffer? pileup,
          bool? withPosixLineBreaks = true}) async =>
      await openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: false)
          .readUtfAsString(
              extra: extra,
              onRead: onRead,
              pileup: pileup,
              withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  String readUtfAsStringSync(
      {dynamic extra,
      UtfBomHandler? onBom,
      UtfReadHandlerSync? onRead,
      StringBuffer? pileup,
      bool? withPosixLineBreaks = true}) {
    var curByte = 0;

    return UtfSync.readAsString(name,
        extra: extra,
        onBom: onBom,
        onRead: onRead,
        pileup: pileup,
        withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS, onData: (bytes) {
      if (curByte == -1) {
        return 0;
      }

      var curLength = 0;
      var maxLength = bytes.length;

      for (; curLength < maxLength; ++curLength) {
        curByte = readByteSync();

        if (curByte == -1) {
          break;
        }

        bytes[curLength] = curByte;
      }

      return curLength;
    });
  }
}
