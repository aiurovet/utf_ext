// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:io';

import 'package:utf_ext/utf_ext.dart';

/// Class for the formatted output
///
extension UtfStdin on Stdin {
  bool get isPosixOS => !Platform.isWindows;

  /// Const: name for stdin
  ///
  static const name = '<stdin>';

  /// Loop through every line and call user-defined function (non-blocking)
  /// Optionally, you can get the list of all lines by passing [lines]
  ///
  Future<int> forEachLine(
          {UtfBomHandler? onBom,
          UtfReadHandler? onLine,
          List<String>? pileup}) async =>
      await openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: true)
          .forEachUtfLine(onLine: onLine, pileup: pileup);

  /// Loop through every line and call user-defined function (blocking)
  /// Optionally, you can get the list of all lines by passing [pileup]
  ///
  int forEachLineSync(
          {UtfBomHandler? onBom,
          UtfReadHandlerSync? onLine,
          List<String>? pileup}) =>
      openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: true)
          .forEachUtfLineSync(onLine: onLine, pileup: pileup);

  /// Read stdin content as UTF (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<String> readUtfAsString(
          {UtfBomHandler? onBom,
          UtfReadHandler? onRead,
          StringBuffer? pileup,
          bool? withPosixLineBreaks = true}) async =>
      await openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: false)
          .readUtfAsString(
              onRead: onRead, pileup: pileup, withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  String readUtfAsStringSync(
          {UtfBomHandler? onBom,
          UtfReadHandlerSync? onRead,
          StringBuffer? pileup,
          bool? withPosixLineBreaks = true}) =>
      openUtfStringStream(UtfDecoder(name, onBom: onBom), asLines: false)
          .readUtfAsStringSync(
              onRead: onRead, pileup: pileup, withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);
}
