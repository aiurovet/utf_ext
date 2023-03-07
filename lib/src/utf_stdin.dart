// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:io';
import 'package:utf_ext/utf_ext.dart';

/// Class for the formatted output
///
extension UtfStdin on Stdin {
  /// Const: flag indicating the current OS is not Windows
  ///
  static bool get isPosixOS => !Platform.isWindows;

  /// Const: name for stdin
  ///
  static const name = '<stdin>';

  /// Loops through every line read from [stdin] and calls a user-defined function (non-blocking)\
  /// \
  /// [extra] - user-defined data\
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every line of text after being read\
  /// [pileup] - if not null, accumulate all lines under that\
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  Future<int> readAsLines(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandler? onRead,
          List<String>? pileup}) async =>
      await openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: true)
          .readUtfAsLines(extra: extra, onRead: onRead, pileup: pileup);

  /// Loops through every line read from [stdin] and calls a user-defined function (blocking)\
  /// \
  /// [extra] - user-defined data\
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every line of text after being read\
  /// [pileup] - if not null, accumulate all lines under that\
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  int readAsLinesSync(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandlerSync? onRead,
          List<String>? pileup}) =>
      UtfHelper.readAsLinesSync(name,
          extra: extra,
          maxLength: null,
          onBom: onBom,
          byteReader: readIntoSync,
          onRead: onRead,
          pileup: pileup,
          withPosixLineBreaks: isPosixOS);

  /// Reads the number of bytes (blocking) and returns the number of bytes read
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

  /// Reads the UTF content from [stdin] (non-blocking) and converts it to a string.\
  /// \
  /// [extra] - user-defined data\
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every chunk of text after being read\
  /// [pileup] - if not null, accumulates all lines under that\
  /// [withPosixLineBreaks] - if true (default) replace CR/LF with LF
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  Future<int> readUtfAsString(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandler? onRead,
          StringBuffer? pileup,
          bool? withPosixLineBreaks = true}) async =>
      await openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: false)
          .readUtfAsString(
              extra: extra,
              onRead: onRead,
              pileup: pileup,
              withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);

  /// Reads the UTF content from [stdin] (blocking) and converts it to a string.\
  /// \
  /// [extra] - user-defined data\
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every chunk of text after being read\
  /// [pileup] - if not null, accumulates all lines under that\
  /// [withPosixLineBreaks] - if true (default) replace CR/LF with LF
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  int readUtfAsStringSync(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandlerSync? onRead,
          StringBuffer? pileup,
          bool? withPosixLineBreaks = true}) =>
      UtfHelper.readAsStringSync(name,
          extra: extra,
          onBom: onBom,
          byteReader: readIntoSync,
          onRead: onRead,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);
}
