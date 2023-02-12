// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
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
  /// Optionally, you can get the list of all lines by passing [lines].\
  /// \
  /// Return the number of lines read.
  ///
  Future<int> forEachUtfLine(
      {dynamic extra, UtfReadHandler? onLine, List<String>? pileup}) async {
    pileup?.clear();

    final isSyncCall = (onLine is UtfReadHandlerSync);
    final params = UtfReadParams(
        isSyncCall: isSyncCall,
        extra: extra);

    params.current = UtfReadExtraParams(pileup: pileup);

    var result = VisitResult.take;

    await for (final line in this) {
      ++params.currentNo;
      params.current!.buffer = line;

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
  /// Optionally, you can get the list of all lines by passing [pileup]\
  /// \
  /// Return the number of lines read.
  ///
  int forEachUtfLineSync(
      {dynamic extra, UtfReadHandlerSync? onLine, List<String>? pileup}) {
    pileup?.clear();

    final isSyncCall = (onLine is UtfReadHandlerSync);
    final params = UtfReadParams(
        isSyncCall: isSyncCall,
        extra: extra);

    params.current = UtfReadExtraParams(pileup: pileup);

    var result = VisitResult.take;

    any((line) {
      ++params.currentNo;
      params.current!.buffer = line;

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
  /// without affecting the existing Windows line breaks
  ///
  static String fromPosixLineBreaks(String input) => input
      .replaceAll(UtfStringStream.lineBreakWin, '\x01')
      .replaceAll(UtfStringStream.lineBreak, UtfStringStream.lineBreakWin)
      .replaceAll('\x01', UtfStringStream.lineBreakWin);

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one.\
  /// \
  /// Return the wole content if [pileup] is null or empty string otherwise.
  ///
  Future<String> readUtfAsString(
      {dynamic extra,
      UtfReadHandler? onRead,
      StringBuffer? pileup,
      bool withPosixLineBreaks = true}) async {
    var output = (pileup ?? StringBuffer())..clear();

    final isSyncCall = (onRead is UtfReadHandlerSync);
    final params = UtfReadParams(isSyncCall: isSyncCall, extra: extra);
    params.current = UtfReadExtraParams(pileup: output);

    var result = VisitResult.take;

    await for (var buffer in this) {
      ++params.currentNo;
      params.current!.buffer =
          (withPosixLineBreaks ? toPosixLineBreaks(buffer) : buffer);

      if (onRead != null) {
        result = (isSyncCall ? onRead(params) : await onRead(params));
      }

      if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
        ++params.takenNo;
        output.write(params.current);
      }

      if ((result == VisitResult.takeAndStop) ||
          (result == VisitResult.skipAndStop)) {
        break;
      }
    }

    return (pileup == null ? output.toString() : '');
  }

  /// Read the UTF file content (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is set, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one\
  /// \
  /// Return the wole content if [pileup] is null or empty string otherwise.
  ///
  String readUtfAsStringSync(
      {dynamic extra,
      UtfReadHandlerSync? onRead,
      StringBuffer? pileup,
      bool withPosixLineBreaks = true}) {
    var output = (pileup ?? StringBuffer())..clear();

    final params = UtfReadParams(
        isSyncCall: true,
        extra: UtfReadExtraParams(extra: extra, pileup: output));
    params.current = UtfReadExtraParams(pileup: output);

    var result = VisitResult.take;

    output.clear();

    any((chunk) {
      ++params.currentNo;
      params.current!.buffer =
          (withPosixLineBreaks ? toPosixLineBreaks(chunk) : chunk);

      if (onRead != null) {
        result = onRead(params);
      }

      if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
        ++params.takenNo;
        output.write(params.current);
      }

      if ((result == VisitResult.takeAndStop) ||
          (result == VisitResult.skipAndStop)) {
        return true;
      }

      return false;
    });

    return (pileup == null ? output.toString() : '');
  }

  /// Replace all occurrences of Windows and old Mac specific
  /// line breaks with the POSIX ones
  ///
  static String toPosixLineBreaks(String input) => input
      .replaceAll(lineBreakWin, lineBreak)
      .replaceAll(lineBreakMac, lineBreak);
}
