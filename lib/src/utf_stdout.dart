// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'dart:io';

import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Class for the formatted output
///
extension UtfStdout on Stdout {
  bool get isPosixOS => !Platform.isWindows;

  /// Const: name for stdin
  ///
  static const name = '<stdout>';

  /// Low-level output - the actual printing
  ///
  int _onByteIo(List<int> bytes, [int start = 0, int? end]) {
    final length = (end ?? bytes.length) - start;

    if (length <= 0) {
      return length;
    }

    if ((start == 0) && ((end == null) || (end >= length))) {
      add(bytes);
    } else {
      add(bytes.sublist(start, end));
    }

    return length;
  }

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<void> printUtfAsLines(List<String> lines,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandler? onUtfIo,
          UtfType type = UtfType.none,
          bool? withBom,
          bool withPosixLineBreaks = true}) async =>
    await writeUtfAsLines(name, lines,
          extra: extra,
          type: type,
          onUtfIo: onUtfIo,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks);

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  void printUtfAsLinesSync(List<String> lines,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandlerSync? onUtfIo,
          UtfType type = UtfType.none,
          bool? withBom,
          bool withPosixLineBreaks = true}) =>
      UtfHelper.writeAsLinesSync(name, lines,
          extra: extra,
          type: type,
          onByteIo: _onByteIo,
          onUtfIo: onUtfIo,
          withPosixLineBreaks: withPosixLineBreaks);

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<void> printUtfAsString(String content,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandler? onUtfIo,
          UtfType type = UtfType.utf8,
          bool? withBom,
          bool? withPosixLineBreaks = true}) async =>
      await writeUtfAsString(name, content,
          extra: extra,
          onUtfIo: onUtfIo,
          type: type,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);

  /// Read the UTF file content (blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  void printUtfAsStringSync(String content,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandlerSync? onUtfIo,
          UtfType type = UtfType.utf8,
          bool? withBom,
          bool? withPosixLineBreaks = true}) =>
      UtfHelper.writeAsStringSync(name, content,
          extra: extra,
          onUtfIo: onUtfIo,
          type: type,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS);

  /// Read the UTF file content (blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  FutureOr<VisitResult> printUtfChunk(
          UtfEncoder encoder,
          {UtfIoHandler? onUtfIo,
          UtfIoParams? params,
          bool? withPosixLineBreaks = true}) async {
    var result = VisitResult.take;

    if (params == null) {
      return result;
    }

    if (onUtfIo != null) {
      result = (params.isSyncCall ? onUtfIo(params) : await onUtfIo(params)) as VisitResult;
    }

    if (!result.isSkip) {
      _onByteIo(encoder.convert(params.current!));
    }

    return result;
  }

  /// Read the UTF file content (blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  VisitResult printUtfChunkSync(
          UtfEncoder encoder,
          {UtfIoHandlerSync? onUtfIo,
          UtfIoParams? params,
          bool? withPosixLineBreaks = true}) {
    var result = VisitResult.take;

    if (params == null) {
      return result;
    }

    if (onUtfIo != null) {
      result = onUtfIo(params);
    }

    if (!result.isSkip) {
      _onByteIo(encoder.convert(params.current!));
    }

    return result;
  }
}
