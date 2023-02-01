// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'dart:io';
import 'package:file/file.dart';
import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Helper class to manage callbacks for text files
///
extension UtfStringStream on Stream<String> {
  /// Const: line break (POSIX)
  ///
  static const lineBreak = '\n';

  /// Const: line break (MacOS)
  ///
  static const lineBreakMac = '\r';

  /// Const: line break (Windows)
  ///
  static const lineBreakWin = '\r\n';

  /// Loop through every line and call user-defined function (non-blocking)
  /// Optionally, you can get the list of all lines by passing [lines]
  ///
  Future<int> forEachUtfLine(
      {UtfReadHandler? onLine, List<String>? pileup}) async {
    pileup?.clear();

    final isSyncCall = (onLine is UtfReadHandlerSync);
    final params = UtfReadParams(isSyncCall: isSyncCall, extra: pileup);
    var result = VisitResult.take;

    await for (final line in this) {
      ++params.currentNo;
      params.current = line;

      if (onLine != null) {
        result = (isSyncCall ? onLine(params) : await onLine(params));
      }

      if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
        ++params.takenNo;
        pileup?.add(line);
      }

      if ((result == VisitResult.takeAndStop) ||
          (result == VisitResult.skipAndStop)) {
        break;
      }
    }

    return params.takenNo; // the actual number of lines
  }

  /// Loop through every line and call user-defined function (blocking)
  /// Optionally, you can get the list of all lines by passing [pileup]
  ///
  int forEachUtfLineSync({UtfReadHandlerSync? onLine, List<String>? pileup}) {
    pileup?.clear();

    final isSyncCall = (onLine is UtfReadHandlerSync);
    final params = UtfReadParams(isSyncCall: isSyncCall, extra: pileup);
    var result = VisitResult.take;

    any((line) {
      ++params.currentNo;
      params.current = line;

      if (onLine != null) {
        result = onLine(params);
      }

      if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
        ++params.takenNo;
        pileup?.add(line);
      }

      if ((result == VisitResult.takeAndStop) ||
          (result == VisitResult.skipAndStop)) {
        return true;
      }

      return false;
    });

    return params.takenNo;
  }

  /// Replace all occurrences of POSIX line breaks with the Windows ones
  ///
  static String fromPosixLineBreaks(String input) =>
    input = input.replaceAll(lineBreak, lineBreakWin);

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  Future<int> readUtfAsString(
      {UtfReadHandler? onRead,
      StringBuffer? pileup,
      bool withPosixLineBreaks = true}) async {
    final isSyncCall = (onRead is UtfReadHandlerSync);
    final params = UtfReadParams(isSyncCall: isSyncCall, extra: pileup);
    var result = VisitResult.take;

    await for (var buffer in this) {
      ++params.currentNo;
      params.current = (withPosixLineBreaks ? toPosixLineBreaks(buffer) : buffer);

      if (onRead != null) {
        result = (isSyncCall ? onRead(params) : await onRead(params));
      }

      if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
        ++params.takenNo;
        pileup?.write(params.current);
      }

      if ((result == VisitResult.takeAndStop) ||
          (result == VisitResult.skipAndStop)) {
        break;
      }
    }

    return params.takenNo;
  }

  /// Read the UTF file content (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  int readUtfAsStringSync(
      {UtfReadHandlerSync? onRead,
      StringBuffer? pileup,
      bool withPosixLineBreaks = true}) {
    final params = UtfReadParams(isSyncCall: true, extra: pileup);
    var result = VisitResult.take;

    any((chunk) {
      ++params.currentNo;
      params.current = (withPosixLineBreaks ? toPosixLineBreaks(chunk) : chunk);

      if (onRead != null) {
        result = onRead(params);
      }

      if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
        ++params.takenNo;
        pileup?.write(params.current);
      }

      if ((result == VisitResult.takeAndStop) ||
          (result == VisitResult.skipAndStop)) {
        return true;
      }

      return false;
    });

    return params.takenNo;
  }

  /// Replace all occurrences of Windows and old Mac specific
  /// line breaks with the POSIX ones
  ///
  static String toPosixLineBreaks(String input) {
    input = input.replaceAll(lineBreakWin, lineBreak);
    input = input.replaceAll(lineBreakMac, lineBreak);

    return input;
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<int> writeAsUtf(
      IOSink sink,
      UtfEncoder encoder,
      {dynamic extra,
      UtfWriteHandler? onWrite,
      bool withPosixLineBreaks = true}) async {
    final isSyncCall = (onWrite is UtfWriteHandlerSync);
    final params = UtfWriteParams(isSyncCall: isSyncCall, extra: extra);
    var result = VisitResult.take;

    await for (var buffer in this) {
      result = await writeUtfChunk(sink, encoder, buffer, params: params, withPosixLineBreaks: withPosixLineBreaks);

      if ((result == VisitResult.takeAndStop) ||
          (result == VisitResult.skipAndStop)) {
        break;
      }
    }

    return params.takenNo;
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<VisitResult> writeUtfChunk(
      IOSink sink,
      UtfEncoder encoder,
      String chunk,
      {UtfWriteHandler? onWrite,
      UtfWriteParams? params,
      bool withPosixLineBreaks = true}) async {
    final isSyncCall = params?.isSyncCall ?? (onWrite is UtfWriteHandlerSync);
    FutureOr<VisitResult> result = VisitResult.take;

    ++params?.currentNo;

    if (withPosixLineBreaks) {
      chunk = fromPosixLineBreaks(chunk);
    }

    params?.current = chunk;

    if ((onWrite != null) && (params != null)) {
      result = (isSyncCall ? onWrite(params) : await onWrite(params));
    }

    if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
      ++params?.takenNo;
      sink.write(encoder.convert(chunk));
    }

    return result;
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<VisitResult> writeUtfChunkSync(
      IOSink sink,
      UtfEncoder encoder,
      String chunk,
      {UtfWriteHandlerSync? onWrite,
      UtfWriteParams? params,
      bool withPosixLineBreaks = true}) async {
    var result = VisitResult.take;

    ++params?.currentNo;

    if (withPosixLineBreaks) {
      chunk = fromPosixLineBreaks(chunk);
    }

    params?.current = chunk;

    if ((onWrite != null) && (params != null)) {
      result = onWrite(params);
    }

    if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
      ++params?.takenNo;
      sink.write(encoder.convert(chunk));
    }

    return result;
  }
}
