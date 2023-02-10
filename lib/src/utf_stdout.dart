// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:io';

import 'package:utf_ext/utf_ext.dart';

/// Class for the formatted output
///
extension UtfStdout on Stdout {
  bool get isPosixOS => !Platform.isWindows;

  /// Const: name for stdin
  ///
  static const name = '<stdout>';

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<void> printUtfAsLines(List<String> lines,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfWriteHandler? onWrite,
          UtfType type = UtfType.none,
          bool? withBom,
          bool withPosixLineBreaks = true}) async =>
      await writeUtfAsLines(name, lines,
          extra: extra,
          type: type,
          onWrite: onWrite,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks);

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  void printUtfAsLinesSync(List<String> lines,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfWriteHandlerSync? onWrite,
          UtfType type = UtfType.none,
          bool? withBom,
          bool withPosixLineBreaks = true}) =>
      writeUtfAsLinesSync(name, lines,
          extra: extra,
          type: type,
          onWrite: onWrite,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks);

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<void> printUtfAsString(String content,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfType type = UtfType.utf8,
          bool? withBom,
          bool? withPosixLineBreaks = true}) async =>
      await writeUtfAsString(name, content,
          extra: extra,
          type: type,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);

  /// Read the UTF file content (blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  void printUtfAsStringSync(String content,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfType type = UtfType.utf8,
          bool? withBom,
          bool? withPosixLineBreaks = true}) =>
      writeUtfAsStringSync(name, content,
          extra: extra,
          type: type,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);
}
