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

  /// Open file stream for reading in non-blocking mode
  ///
  Stream<String> openUtfRead({UtfBomHandler? onBom, bool asLines = false}) {
    final source = openRead();
    final stream = source.transform(UtfDecoder(path, onBom: onBom));

    return (asLines ? stream.transform(LineSplitter()) : stream);
  }

  /// Loop through every line and call user-defined function (non-blocking).\
  /// Optionally, you can get the list of all lines by passing [pileup].\
  /// Returns [pileup] if not null, or an empty list otherwise.
  ///
  Future<List<String>> readUtfAsLines(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandler? onLine,
          List<String>? pileup}) async =>
    await openUtfRead(onBom: onBom, asLines: true).readUtfAsLines(
      extra: extra, onLine: onLine, pileup: pileup);

  /// Loop through every line and call user-defined function (blocking)
  /// Optionally, you can get the list of all lines by passing [pileup]
  /// Returns [pileup].toString() if not null, or an empty string otherwise.
  ///
  List<String> readUtfAsLinesSync(
          {dynamic extra,
          UtfBomHandlerSync? onBom,
          UtfIoHandlerSync? onLine,
          List<String>? pileup}) {
    final input = openSync(mode: FileMode.read);

    try {
      return UtfHelper.readAsLinesSync(path,
          extra: extra,
          maxLength: input.lengthSync(),
          onBom: onBom,
          onByteIo: input.readIntoSync,
          onUtfIo: onLine,
          pileup: pileup,
          withPosixLineBreaks: isPosixFileSystem);
    } finally {
      input.flushSync();
      input.closeSync();
    }
  }

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<String> readUtfAsString(
          {dynamic extra,
          UtfBomHandler? onBom,
          UtfIoHandler? onUtfIo,
          StringBuffer? pileup,
          bool? withPosixLineBreaks = true}) async =>
      await openUtfRead(onBom: onBom).readUtfAsString(
          extra: extra,
          onUtfIo: onUtfIo,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);

  /// Read the UTF file content (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  String readUtfAsStringSync(
      {dynamic extra,
      UtfBomHandler? onBom,
      UtfIoHandlerSync? onUtfIo,
      StringBuffer? pileup,
      bool? withPosixLineBreaks = true}) {
    final input = openSync(mode: FileMode.read);

    try {
      return UtfHelper.readAsStringSync(path,
          extra: extra,
          maxLength: input.lengthSync(),
          onBom: onBom,
          onByteIo: input.readIntoSync,
          onUtfIo: onUtfIo,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);
    } finally {
      input.flushSync();
      input.closeSync();
    }
  }

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<void> writeUtfAsLines(List<String> lines,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandler? onUtfIo,
          UtfType type = UtfType.none,
          bool? withBom,
          bool withPosixLineBreaks = true}) async {
      final output = openWrite(mode: mode);

      try {
        await output.writeUtfAsLines(path, lines,
            extra: extra,
            type: type,
            onUtfIo: onUtfIo,
            withBom: withBom,
            withPosixLineBreaks: withPosixLineBreaks);
      } finally {
        await output.flush();
        await output.close();
      }
  }

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  void writeUtfAsLinesSync(List<String> lines,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandlerSync? onUtfIo,
          UtfType type = UtfType.none,
          bool withBom = true,
          bool withPosixLineBreaks = true}) {
    final output = openSync(mode: mode);

    try {
      UtfHelper.writeAsLinesSync(path, lines,
          extra: extra,
          onByteIo: output.writeFromSync as ByteIoHandlerSync,
          onUtfIo: onUtfIo,
          type: type,
          withBom: withBom,
          withPosixLineBreaks: withPosixLineBreaks);
    } finally {
      output.flushSync();
      output.closeSync();
    }
  }

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<void> writeUtfAsString(String content,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandler? onUtfIo,
          UtfType type = UtfType.utf8,
          bool? withBom,
          bool? withPosixLineBreaks = true}) async {
    final output = openWrite(mode: mode);

    try {
      await output.writeUtfAsString(path, content,
        extra: extra,
        onUtfIo: onUtfIo,
        type: type,
        withBom: withBom,
        withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);
    } finally {
      await output.flush();
      await output.close();
    }
  }

  /// Read the UTF file content (blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  void writeUtfAsStringSync(String content,
          {dynamic extra,
          FileMode mode = FileMode.write,
          UtfIoHandlerSync? onUtfIo,
          UtfType type = UtfType.utf8,
          bool? withBom,
          bool? withPosixLineBreaks = true}) {
    final output = openSync(mode: FileMode.write);

    try {
      UtfHelper.writeAsStringSync(path,
          content,
          extra: extra,
          maxLength: null,
          onByteIo: output.writeByteSync as ByteIoHandlerSync,
          onUtfIo: onUtfIo,
          type: type,
          withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);
    } finally {
      output.flushSync();
      output.closeSync();
    }
  }

  /// Read the UTF file content (blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  void writeUtfChunkSync(
          RandomAccessFile output,
          UtfEncoder encoder,
          String chunk,
          {dynamic extra,
          UtfIoHandlerSync? onUtfIo,
          UtfIoParams? params,
          bool? withPosixLineBreaks = true}) {
    UtfHelper.writeChunkSync(
        encoder,
        chunk,
        onByteIo: output.writeByteSync as ByteIoHandlerSync,
        onUtfIo: onUtfIo,
        params: params,
        withPosixLineBreaks: withPosixLineBreaks ?? isPosixFileSystem);
  }
}
