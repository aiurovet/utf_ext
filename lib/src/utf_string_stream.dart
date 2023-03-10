// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Helper class to manage callbacks for text files
///
extension UtfStringStream on Stream<String> {
  /// Loops through every line read from a stream and calls a user-defined function\
  /// \
  /// [extra] - user-defined data\
  /// [onRead] - a function called upon every line of text after being read\
  /// [pileup] - if not null, accumulates all lines of text\
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  Future<int> readUtfAsLines(
      {dynamic extra, UtfIoHandler? onRead, List<String>? pileup}) async {
    pileup?.clear();

    final isSyncCall = (onRead is UtfIoHandlerSync);
    final params =
        UtfIoParams(extra: extra, isSyncCall: isSyncCall, pileup: pileup);

    var result = VisitResult.take;

    await for (final line in this) {
      ++params.currentNo;
      params.current = line;

      if (onRead != null) {
        result = (isSyncCall ? onRead(params) : await onRead(params));
      }

      if (result.isTake) {
        ++params.takenNo;
        pileup?.add(line);
      }

      if (result.isStop) {
        break;
      }
    }

    return pileup?.length ?? 0;
  }

  /// Loops through every line read from a stream and calls a user-defined function\
  /// \
  /// [extra] - user-defined data\
  /// [onRead] - a function called upon every line of text after being read\
  /// [pileup] - if not null, accumulates the whole content\
  /// [withPosixLineBreaks] - if true (default) replace each CR/LF with LF
  /// \
  /// Returns [pileup] if not null or an empty string otherwise
  ///
  Future<int> readUtfAsString(
      {dynamic extra,
      UtfIoHandler? onRead,
      StringBuffer? pileup,
      bool withPosixLineBreaks = true}) async {
    pileup?.clear();

    final isSyncCall = (onRead is UtfIoHandlerSync);
    final params =
        UtfIoParams(extra: extra, isSyncCall: isSyncCall, pileup: pileup);

    var result = VisitResult.take;

    await for (var buffer in this) {
      ++params.currentNo;
      params.current =
          (withPosixLineBreaks ? UtfHelper.toPosixLineBreaks(buffer) : buffer);

      if (onRead != null) {
        result = (isSyncCall ? onRead(params) : await onRead(params));
      }

      if (result.isTake) {
        ++params.takenNo;
        pileup?.write(params.current);
      }

      if (result.isStop) {
        break;
      }
    }

    return pileup?.length ?? 0;
  }
}
