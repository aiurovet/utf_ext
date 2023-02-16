// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Helper class to manage callbacks for text files
///
class UtfSync {
  /// Const: maximum size of a buffer
  ///
  static const maxBufferLength = 16 * 1024;

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  static String forEachLine(String id,
          {dynamic extra,
          int? maxLength,
          UtfBomHandler? onBom,
          DataHandlerSync? onData,
          UtfReadHandlerSync? onRead,
          List<String>? pileup,
          bool withPosixLineBreaks = true}) =>
      readAll(id,
          asLines: true,
          extra: extra,
          maxLength: maxLength,
          onBom: onBom,
          onData: onData,
          onRead: onRead,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks);

  /// Process chunk of data as a single block
  ///
  static int _processChunkAsBulk(
      UtfReadParams params, UtfReadHandlerSync? onRead) {
    final chunk = params.current!;
    final len = chunk.length;

    if (len <= 0) {
      return 0;
    }

    ++params.currentNo;
    params.current = chunk;
    final result = (onRead == null ? VisitResult.take : onRead(params));
    final pileup = params.pileup as StringBuffer?;

    if (result.isTake) {
      pileup?.write(chunk);
    }

    return (result.isStop ? -1 : len);
  }

  /// Process chunk of data line by line
  ///
  static int _processChunkAsLines(
      UtfReadParams params, UtfReadHandlerSync? onRead, bool withPosixLineBreaks, bool isEnd) {
    final chunk = params.current!;
    var len = chunk.length;

    if (len <= 0) {
      return 0;
    }

    final pileup = params.pileup as List<String>?;
    var result = VisitResult.take;

    for (var start = 0, end = 0; ; start = end + 1) {
      end = chunk.indexOf(UtfStringStream.lineBreak, start);

      if (end < 0) {
        if (!isEnd) {
          return end;
        }
        break;
      }

      var endEx = end;

      if ((end > start) && !withPosixLineBreaks) {
        if (chunk[end - 1] == UtfStringStream.lineBreakMac) {
          --endEx;
        }
      }

      ++params.currentNo;
      final line = chunk.substring(start, endEx);
      params.current = line;

      if (onRead != null) {
        result = onRead(params);
      }

      if (result.isTake) {
        pileup?.add(chunk);
      }

      if (result.isStop) {
        return -1;
      }
    }

    return len;
  }

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  static String readAll(String id,
      {bool asLines = false,
      dynamic extra,
      int? maxLength,
      UtfBomHandler? onBom,
      DataHandlerSync? onData,
      UtfReadHandlerSync? onRead,
      dynamic pileup,
      bool withPosixLineBreaks = true}) {
    if (onData == null) {
      return '';
    }

    final params =
        UtfReadParams(extra: extra, isSyncCall: true, pileup: pileup);
    pileup?.clear();

    maxLength ??= maxBufferLength;

    final bytes = List<int>.filled(maxLength, 0);
    var chunk = '';
    var curByte = 0;
    final decoder = UtfDecoder(id, hasSink: false, onBom: onBom);

    for (var curLength = 0; curByte != -1; curLength = 0) {
      curLength = onData(bytes);

      if (curLength == 0) {
        if (asLines && chunk.isNotEmpty) {
          _processChunkAsLines(params, onRead, withPosixLineBreaks, asLines);
        }
        break;
      }

      final next = decoder.convert(bytes, 0, curLength);

      params.current = chunk + (withPosixLineBreaks
          ? UtfStringStream.toPosixLineBreaks(next)
          : next);

      var end = 0;

      if (asLines) {
        end = _processChunkAsLines(params, onRead, withPosixLineBreaks, false);
      } else {
        end = _processChunkAsBulk(params, onRead);
      }

      if (end < 0) {
        break;
      }

      if (end > 0) {
        chunk = chunk.substring(end);
      }
    }

    if (asLines || (pileup == null)) {
      return '';
    }

    return (pileup as StringBuffer).toString();
  }

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  static String readAsString(String id,
          {dynamic extra,
          int? maxLength,
          UtfBomHandler? onBom,
          DataHandlerSync? onData,
          UtfReadHandlerSync? onRead,
          StringBuffer? pileup,
          bool withPosixLineBreaks = true}) =>
      readAll(id,
          asLines: false,
          extra: extra,
          maxLength: maxLength,
          onBom: onBom,
          onData: onData,
          onRead: onRead,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks);
}
