// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file/file.dart' show File;
import 'package:utf_ext/utf_ext.dart';

/// Helper class to manage text files written in any
/// of the Unicode encodings: UTF-8, UTF-16, UTF-32
///
extension UtfFile on File {
  bool get isPosixFileSystem => fileSystem.path.separator == '/';

  /// Loop through every line and call user-defined function (non-blocking)
  /// Optionally, you can get the list of all lines by passing [pileup]
  ///
  Future<int> forEachUtfLine(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfReadHandler? onLine,
          List<String>? pileup}) async =>
      await openUtfRead(onBom: onBom, asLines: true)
          .forEachUtfLine(extra: extra, onLine: onLine, pileup: pileup);

  /// Loop through every line and call user-defined function (blocking)
  /// Optionally, you can get the list of all lines by passing [pileup]
  ///
  int forEachUtfLineSync(
          {dynamic extra,
          UtfBomHandlerSync? onBom,
          UtfReadHandlerSync? onLine,
          List<String>? pileup}) =>
      openUtfRead(onBom: onBom, asLines: true)
          .forEachUtfLineSync(extra: extra, onLine: onLine, pileup: pileup);

  /// Open stream (from file or stdin) for reading
  ///
  Stream<String> openUtfRead({UtfBomHandler? onBom, bool asLines = false}) {
    final source = openRead();
    final stream = source.transform(UtfDecoder(path, onBom: onBom));

    return (asLines ? stream.transform(LineSplitter()) : stream);
  }

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<String> readUtfAsString(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfReadHandler? onRead,
          StringBuffer? pileup,
          bool? withPosixLineBreaks = true}) async =>
      await openUtfRead(onBom: onBom).readUtfAsString(
          extra: extra,
          onRead: onRead,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);

  /// Read the UTF file content (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  String readUtfAsStringSync(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfReadHandlerSync? onRead,
          StringBuffer? pileup,
          bool? withPosixLineBreaks = true}) =>
      openUtfRead(onBom: onBom).readUtfAsStringSync(
          extra: extra,
          onRead: onRead,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<void> writeUtfAsLines(List<String> lines,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfWriteHandler? onWrite,
          UtfType type = UtfType.none,
          bool? withBom,
          bool withPosixLineBreaks = true}) async =>
      await openWrite(mode: mode).writeUtfAsLines(path, lines,
          extra: extra,
          type: type,
          onWrite: onWrite,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks);

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  void writeUtfAsLinesSync(List<String> lines,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfWriteHandlerSync? onWrite,
          UtfType type = UtfType.none,
          bool? withBom,
          bool withPosixLineBreaks = true}) =>
      openWrite(mode: mode).writeUtfAsLinesSync(path, lines,
          extra: extra,
          type: type,
          onWrite: onWrite,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks);

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<void> writeUtfAsString(String content,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfType type = UtfType.utf8,
          bool? withBom,
          bool? withPosixLineBreaks = true}) async =>
      await openWrite(mode: mode).writeUtfAsString(path, content,
          extra: extra,
          type: type,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);

  /// Read the UTF file content (blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  void writeUtfAsStringSync(String content,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfType type = UtfType.utf8,
          bool? withBom,
          bool? withPosixLineBreaks = true}) =>
      openWrite(mode: mode).writeUtfAsStringSync(path, content,
          extra: extra,
          type: type,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);
}
