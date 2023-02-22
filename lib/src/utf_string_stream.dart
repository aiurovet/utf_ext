// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Helper class to manage callbacks for text files
///
extension UtfStringStream on Stream<String> {
  /// Loop through every line and call user-defined function (non-blocking)
  /// Optionally, you can get the list of all lines by passing [lines].\
  /// \
  /// Return the number of lines read.
  ///
  Future<List<String>> readUtfAsLines(
      {dynamic extra, UtfIoHandler? onLine, List<String>? pileup}) async {
    pileup?.clear();

    final isSyncCall = (onLine is UtfIoHandlerSync);
    final params =
        UtfIoParams(extra: extra, isSyncCall: isSyncCall, pileup: pileup);

    var result = VisitResult.take;

    await for (final line in this) {
      ++params.currentNo;
      params.current = line;

      if (onLine != null) {
        result = (isSyncCall ? onLine(params) : await onLine(params));
      }

      if (result.isTake) {
        ++params.takenNo;
        pileup?.add(line);
      }

      if (result.isStop) {
        break;
      }
    }

    return pileup ?? <String>[];
  }

  /// Read the UTF file content (non-blocking) and and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one.\
  /// \
  /// Return the wole content if [pileup] is null or empty string otherwise.
  ///
  Future<String> readUtfAsString(
      {dynamic extra,
      UtfIoHandler? onUtfIo,
      StringBuffer? pileup,
      bool withPosixLineBreaks = true}) async {
    pileup?.clear();

    final isSyncCall = (onUtfIo is UtfIoHandlerSync);
    final params =
        UtfIoParams(extra: extra, isSyncCall: isSyncCall, pileup: pileup);

    var result = VisitResult.take;

    await for (var buffer in this) {
      ++params.currentNo;
      params.current =
          (withPosixLineBreaks ? UtfHelper.toPosixLineBreaks(buffer) : buffer);

      if (onUtfIo != null) {
        result = (isSyncCall ? onUtfIo(params) : await onUtfIo(params));
      }

      if (result.isTake) {
        ++params.takenNo;
        pileup?.write(params.current);
      }

      if (result.isStop) {
        break;
      }
    }

    return pileup?.toString() ?? '';
  }
}
