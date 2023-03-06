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
  /// Flag indicating the file system this file belongs to is POSIX-compliant
  ///
  bool get isPosixFileSystem => fileSystem.path.separator == '/';

  /// Opens file stream for reading in non-blocking mode
  ///
  Stream<String> openUtfRead({UtfBomHandler? onBom, bool asLines = false}) {
    final source = openRead();
    final stream = UtfDecoder(path, onBom: onBom).bind(source);

    return (asLines ? stream.transform(LineSplitter()) : stream);
  }

  /// Loops through every line read from a file and calls a user-defined function (non-blocking)\
  /// \
  /// [extra] - user-defined data\
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every line of text after being read\
  /// [pileup] - if not null, accumulate all lines under that\
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  Future<List<String>> readUtfAsLines(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandler? onRead,
          List<String>? pileup}) async =>
      await openUtfRead(onBom: onBom, asLines: true)
          .readUtfAsLines(extra: extra, onRead: onRead, pileup: pileup);

  /// Loops through every line read from a file and calls a user-defined function (blocking)\
  /// \
  /// [extra] - user-defined data\
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every line of text after being read\
  /// [pileup] - if not null, accumulates all lines of text\
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  List<String> readUtfAsLinesSync(
      {dynamic extra,
      UtfBomHandlerSync? onBom,
      UtfIoHandlerSync? onRead,
      List<String>? pileup}) {
    final input = openSync(mode: FileMode.read);

    try {
      return UtfHelper.readAsLinesSync(path,
          byteReader: input.readIntoSync,
          extra: extra,
          maxLength: input.lengthSync(),
          onBom: onBom,
          onRead: onRead,
          pileup: pileup,
          withPosixLineBreaks: isPosixFileSystem);
    } finally {
      input.flushSync();
      input.closeSync();
    }
  }

  /// Reads the UTF file content (non-blocking) and converts it to a string.\
  /// \
  /// [extra] - user-defined data\
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every chunk of text after being read\
  /// [pileup] - if not null, accumulates the whole content under that\
  /// [withPosixLineBreaks] - if true (default) replace each CR/LF with LF
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  Future<String> readUtfAsString(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandler? onRead,
          StringBuffer? pileup,
          bool? withPosixLineBreaks = true}) async =>
      await openUtfRead(onBom: onBom).readUtfAsString(
          extra: extra,
          onRead: onRead,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);

  /// Reads the UTF file content (blocking) and converts it to a string.\
  /// \
  /// [extra] - user-defined data\
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every chunk of text after being read\
  /// [pileup] - if not null, accumulates the whole content under that\
  /// [withPosixLineBreaks] - if true (default) replace each CR/LF with LF
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  String readUtfAsStringSync(
      {dynamic extra,
      UtfBomHandler? onBom,
      UtfIoHandlerSync? onRead,
      StringBuffer? pileup,
      bool? withPosixLineBreaks = true}) {
    final input = openSync(mode: FileMode.read);

    try {
      return UtfHelper.readAsStringSync(path,
          byteReader: input.readIntoSync,
          extra: extra,
          maxLength: input.lengthSync(),
          onBom: onBom,
          onRead: onRead,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);
    } finally {
      input.flushSync();
      input.closeSync();
    }
  }

  /// Converts a sequence of strings into bytes and saves those as a UTF file (non-blocking)\
  /// \
  /// [lines] - the whole content broken into lines with no line break
  /// [extra] - user-defined data\
  /// [mode] - write or append\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is printed
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  Future<void> writeUtfAsLines(List<String> lines,
      {dynamic extra,
      FileMode mode = FileMode.write,
      UtfIoHandler? onWrite,
      UtfType type = UtfType.none,
      bool? withBom,
      bool withPosixLineBreaks = true}) async {
    final output = openWrite(mode: mode);

    try {
      await output.writeUtfAsLines(path, lines,
          extra: extra,
          type: type,
          onWrite: onWrite,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks);
    } finally {
      await output.flush();
      await output.close();
    }
  }

  /// Converts a sequence of strings into bytes and saves those as a UTF file (blocking)\
  /// \
  /// [lines] - the whole content broken into lines with no line break
  /// [extra] - user-defined data\
  /// [mode] - write or append\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is written
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  void writeUtfAsLinesSync(List<String> lines,
      {dynamic extra,
      FileMode mode = FileMode.write,
      UtfIoHandlerSync? onWrite,
      UtfType type = UtfType.none,
      bool? withBom,
      bool withPosixLineBreaks = true}) {
    final output = openSync(mode: mode);

    try {
      UtfHelper.writeAsLinesSync(path, lines,
          byteWriter: output.writeFromSync,
          extra: extra,
          onWrite: onWrite,
          type: type,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks);
    } finally {
      output.flushSync();
      output.closeSync();
    }
  }

  /// Converts a strings into bytes and saves those as a UTF file (non-blocking)\
  /// \
  /// [content] - string to write (the whole content)\
  /// [mode] - write or append\
  /// [extra] - user-defined data\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is written
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  Future<void> writeUtfAsString(String content,
      {dynamic extra,
      FileMode mode = FileMode.write,
      UtfIoHandler? onWrite,
      UtfType type = UtfType.none,
      bool? withBom,
      bool? withPosixLineBreaks = true}) async {
    final output = openWrite(mode: mode);

    try {
      await output.writeUtfAsString(path, content,
          extra: extra,
          onWrite: onWrite,
          type: type,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);
    } finally {
      await output.flush();
      await output.close();
    }
  }

  /// Converts a strings into bytes and saves those as a UTF file (blocking)\
  /// \
  /// [content] - string to write (the whole content)\
  /// [mode] - write or append\
  /// [extra] - user-defined data\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is printed
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  void writeUtfAsStringSync(String content,
      {dynamic extra,
      FileMode mode = FileMode.write,
      UtfIoHandlerSync? onWrite,
      UtfType type = UtfType.none,
      bool? withBom,
      bool? withPosixLineBreaks = true}) {
    final output = openSync(mode: FileMode.write);

    try {
      UtfHelper.writeAsStringSync(
          path,
          byteWriter: output.writeFromSync,
          content,
          extra: extra,
          maxLength: null,
          onWrite: onWrite,
          type: type,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);
    } finally {
      output.flushSync();
      output.closeSync();
    }
  }

  /// Converts a strings into bytes and writes those to a UTF file (blocking),\
  /// can be called sequentially\
  /// \
  /// [output] - opened file\
  /// [encoder] - UTF encoder\
  /// [chunk] - a chunk of text to write
  /// [extra] - user-defined data\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [params] - current chunk info holder\
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  void writeUtfChunkSync(
      RandomAccessFile output, UtfEncoder encoder, String chunk,
      {dynamic extra,
      UtfIoHandlerSync? onWrite,
      UtfIoParams? params,
      bool? withPosixLineBreaks = true}) {
    UtfHelper.writeChunkSync(
        encoder,
        byteWriter: output.writeFromSync,
        chunk,
        onWrite: onWrite,
        params: params,
        withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);
  }
}
