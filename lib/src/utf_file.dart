// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'dart:convert';
import 'package:file/file.dart' show File;
import 'package:utf_ext/utf_ext.dart';

/// Helper class to manage text files written in any
/// of the Unicode encodings: UTF-8, UTF-16, UTF-32
///
extension UtfFile on File {
  /// Loop through every line and call user-defined function (non-blocking)
  /// Optionally, you can get the list of all lines by passing [pileup]
  ///
  Future<int> forEachUtfLine(
          {UtfBomHandler? onBom,
          UtfReadHandler? onLine,
          List<String>? pileup}) async =>
      await openUtfRead(onBom: onBom, asLines: true)
          .forEachUtfLine(onLine: onLine, pileup: pileup);

  /// Loop through every line and call user-defined function (blocking)
  /// Optionally, you can get the list of all lines by passing [pileup]
  ///
  int forEachUtfLineSync(
          {UtfBomHandlerSync? onBom,
          UtfReadHandlerSync? onLine,
          List<String>? pileup}) =>
      openUtfRead(onBom: onBom, asLines: true)
          .forEachUtfLineSync(onLine: onLine, pileup: pileup);

  /// Open stream (from file or stdin) for reading
  ///
  Stream<String> openUtfRead({UtfBomHandler? onBom, bool asLines = false}) {
    final source = openRead();
    final stream = source.transform(UtfDecoder(path, onBom: onBom));

    return (asLines ? stream.transform(LineSplitter()) : stream);
  }

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [hasPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<int> readUtfAsString(
          {UtfBomHandler? onBom,
          UtfReadHandler? onRead,
          StringBuffer? pileup,
          bool hasPosixLineBreaks = false}) async =>
      await openUtfRead(onBom: onBom).readUtfAsString(
          onRead: onRead, pileup: pileup, hasPosixLineBreaks: hasPosixLineBreaks);

  /// Read the UTF file content (blocking) and convert it to string.\
  /// If [hasPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  int readUtfAsStringSync(
          {UtfBomHandler? onBom,
          UtfReadHandlerSync? onRead,
          StringBuffer? pileup,
          bool hasPosixLineBreaks = false}) =>
      openUtfRead(onBom: onBom).readUtfAsStringSync(
          onRead: onRead, pileup: pileup, hasPosixLineBreaks: hasPosixLineBreaks);
}
