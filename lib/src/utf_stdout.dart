// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'dart:io';

import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Class for the formatted output
///
extension UtfStdout on Stdout {
  /// Flag indicating the current OS is POSIX-compliant
  ///
  static bool get isPosixOS => !Platform.isWindows;

  /// Const: name for stdin
  ///
  static const name = '<stdout>';

  /// Low-level output - the actual printing
  ///
  int _byteWriter(List<int> bytes, [int start = 0, int? end]) {
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

  /// Converts a sequence of strings into bytes and prints those (non-blocking)\
  /// \
  /// [lines] - the whole content broken into lines with no line break
  /// [extra] - user-defined data\
  /// [mode] - write (default) or append\
  /// [onWrite] - a function called upon every chunk of text before being written (non-blocking)\
  /// [onWriteSync] - a function called upon every chunk of text before being written (blocking)\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is printed
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  Future<void> printUtfAsLines(List<String> lines,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandler? onWrite,
          UtfIoHandlerSync? onWriteSync,
          UtfType type = UtfType.none,
          bool? withBom,
          bool withPosixLineBreaks = true}) async =>
      await writeUtfAsLines(name, lines,
          extra: extra,
          type: type,
          onWrite: onWrite,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks,
          lineBreakAtEnd: true);

  /// Converts a sequence of strings into bytes and prints those (blocking)\
  /// \
  /// [lines] - the whole content broken into lines with no line break
  /// [extra] - user-defined data\
  /// [mode] - write (default) or append\
  /// [onWrite] - a function called upon every chunk of text before being written (non-blocking)\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is printed
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  void printUtfAsLinesSync(List<String> lines,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandlerSync? onWrite,
          UtfType type = UtfType.none,
          bool? withBom,
          bool withPosixLineBreaks = true}) =>
      UtfHelper.writeAsLinesSync(name, lines,
          byteWriter: _byteWriter,
          extra: extra,
          type: type,
          onWrite: onWrite,
          withPosixLineBreaks: withPosixLineBreaks,
          lineBreakAtEnd: true);

  /// Converts a strings into bytes and prints those (non-blocking)\
  /// \
  /// [content] - the whole text to print
  /// [extra] - user-defined data\
  /// [mode] - write (default) or append\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [onWriteSync] - a function called upon every chunk of text before being written (blocking)\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is printed
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  Future<void> printUtfAsString(String content,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandler? onWrite,
          UtfIoHandlerSync? onWriteSync,
          UtfType type = UtfType.none,
          bool? withBom,
          bool? withPosixLineBreaks = true}) async =>
      await writeUtfAsString(name, content,
          extra: extra,
          onWrite: onWrite,
          onWriteSync: onWriteSync,
          type: type,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS,
          lineBreakAtEnd: true);

  /// Converts a strings into bytes and prints those (blocking)\
  /// \
  /// [content] - the whole text to print
  /// [extra] - user-defined data\
  /// [mode] - write (default) or append\
  /// [onWrite] - a function called upon every chunk of text before being written (non-blocking)\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is printed
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  void printUtfAsStringSync(String content,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandlerSync? onWrite,
          UtfType type = UtfType.none,
          bool? withBom,
          bool? withPosixLineBreaks = true}) =>
      UtfHelper.writeAsStringSync(name, content,
          extra: extra,
          onWrite: onWrite,
          type: type,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixOS,
          lineBreakAtEnd: true);

  /// Converts a chunk of text into bytes and prints those (non-blocking), can be called sequentially\
  /// \
  /// [encoder] - UTF encoder
  /// [chunk] - chunk of text to print
  /// [onWrite] - a function called upon every chunk of text before being written (non-blocking)\
  /// [onWriteSync] - a function called upon every chunk of text before being written (blocking)\
  /// [params] - current chunk info holder
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  Future<VisitResult> printUtfChunk(UtfEncoder encoder, String chunk,
      {UtfIoHandler? onWrite,
      UtfIoHandlerSync? onWriteSync,
      UtfIoParams? params,
      bool? withPosixLineBreaks = true}) async {
    var result = VisitResult.take;

    if (params == null) {
      return result;
    }

    ++params.currentNo;
    params.current = chunk;

    if (onWrite != null) {
      result = await onWrite(params);
    } else if (onWriteSync != null) {
      result = onWriteSync(params);
    }

    chunk = params.current ?? '';

    if (result.isTake) {
      _byteWriter(encoder.convert(chunk));
    }

    return result;
  }

  /// Converts a chunk of text into bytes and prints those (non-blocking), can be called sequentially\
  /// \
  /// [encoder] - UTF encoder
  /// [chunk] - chunk of text to print
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [params] - current chunk info holder
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  VisitResult printUtfChunkSync(UtfEncoder encoder, String chunk,
      {UtfIoHandlerSync? onWrite,
      UtfIoParams? params,
      bool? withPosixLineBreaks = true}) {
    var result = VisitResult.take;

    if (params == null) {
      return result;
    }

    ++params.currentNo;
    params.current = chunk;

    if (onWrite != null) {
      result = onWrite(params);
      chunk = params.current ?? '';
    }

    if (result.isTake) {
      _byteWriter(encoder.convert(chunk));
    }

    return result;
  }
}
