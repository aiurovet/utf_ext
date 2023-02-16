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
  Future<void> forEachUtfLine(
      {dynamic extra, UtfReadHandler? onLine, List<String>? pileup}) async {
    pileup?.clear();

    final isSyncCall = (onLine is UtfReadHandlerSync);
    final params =
        UtfReadParams(extra: extra, isSyncCall: isSyncCall, pileup: pileup);

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
  }

  /// Loop through every line and call user-defined function (blocking)
  /// Optionally, you can get the list of all lines by passing [pileup]\
  /// \
  /// Return the number of lines read.
  ///
  void forEachUtfLineSync(
      {dynamic extra, UtfReadHandlerSync? onLine, List<String>? pileup}) {
    pileup?.clear();

    final isSyncCall = (onLine is UtfReadHandlerSync);
    final params =
        UtfReadParams(extra: extra, isSyncCall: isSyncCall, pileup: pileup);

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
  }

  /// Replace all occurrences of POSIX line breaks with the Windows ones
  /// without affecting the existing Windows line breaks
  ///
  static String fromPosixLineBreaks(String input) => input
      .replaceAll(UtfStringStream.lineBreakWin, '\x01')
      .replaceAll(UtfStringStream.lineBreak, UtfStringStream.lineBreakWin)
      .replaceAll('\x01', UtfStringStream.lineBreakWin);

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one.\
  /// \
  /// Return the wole content if [pileup] is null or empty string otherwise.
  ///
  Future<String> readUtfAsString(
      {dynamic extra,
      UtfReadHandler? onRead,
      StringBuffer? pileup,
      bool withPosixLineBreaks = true}) async {
    pileup?.clear();

    final isSyncCall = (onRead is UtfReadHandlerSync);
    final params =
        UtfReadParams(extra: extra, isSyncCall: isSyncCall, pileup: pileup);

    var result = VisitResult.take;

    await for (var buffer in this) {
      ++params.currentNo;
      params.current =
          (withPosixLineBreaks ? toPosixLineBreaks(buffer) : buffer);

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

    return pileup?.toString() ?? '';
  }

  /// Replace all occurrences of Windows and old Mac specific
  /// line breaks with the POSIX ones
  ///
  static String toPosixLineBreaks(String input) => input
      .replaceAll(lineBreakWin, lineBreak)
      .replaceAll(lineBreakMac, lineBreak);
}
