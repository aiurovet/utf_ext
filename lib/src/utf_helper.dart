// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Common helpers
///
class UtfHelper {
  /// Replace all occurrences of POSIX line breaks with the Windows ones
  /// without affecting the existing Windows line breaks
  ///
  static String fromPosixLineBreaks(String input) => input
      .replaceAll(UtfConst.lineBreakWin, '\x01')
      .replaceAll(UtfConst.lineBreak, UtfConst.lineBreakWin)
      .replaceAll('\x01', UtfConst.lineBreakWin);


  /// Process chunk of data line by line
  ///
  static int _processReadChunkAsLinesSync(
      UtfIoParams params, UtfIoHandlerSync? onUtfIo, bool withPosixLineBreaks, bool isEnd) {
    final chunk = params.current!;
    var length = chunk.length;

    if (length <= 0) {
      return 0;
    }

    final pileup = params.pileup as List<String>?;
    var result = VisitResult.take;

    for (var start = 0, end = 0; ; start = end + 1) {
      end = chunk.indexOf(UtfConst.lineBreak, start);

      if (end < 0) {
        if (!isEnd) {
          return end;
        }
        break;
      }

      var endEx = end;

      if ((end > start) && !withPosixLineBreaks) {
        if (chunk[end - 1] == UtfConst.lineBreakMac) {
          --endEx;
        }
      }

      ++params.currentNo;
      final line = chunk.substring(start, endEx);
      params.current = line;

      if (onUtfIo != null) {
        result = onUtfIo(params);
      }

      if (result.isTake) {
        pileup?.add(chunk);
      }

      if (result.isStop) {
        return -1;
      }
    }

    return length;
  }

  /// Process chunk of data as a single block for the read operation
  ///
  static int _processReadChunkAsStringSync(
      UtfIoParams params, UtfIoHandlerSync? onUtfIo) {
    final chunk = params.current!;
    final length = chunk.length;

    ++params.currentNo;
    params.current = chunk;
    final result = (onUtfIo == null ? VisitResult.take : onUtfIo(params));
    final pileup = (result.isTake ? params.pileup : null);

    if ((pileup != null) && (length > 0)) {
      (pileup as StringBuffer).write(chunk);
    }

    return (result.isStop ? -1 : length);
  }

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  static void _readAllSync(String id,
      {bool asLines = false,
      dynamic extra,
      int? maxLength,
      UtfBomHandler? onBom,
      ByteIoHandlerSync? onByteIo,
      UtfIoHandlerSync? onUtfIo,
      dynamic pileup,
      bool withPosixLineBreaks = true}) {
    final params =
        UtfIoParams(extra: extra, isSyncCall: true, pileup: pileup);
    pileup?.clear();

    maxLength ??= UtfConfig.maxBufferLength;

    final bytes = List<int>.filled(maxLength, 0);
    var chunk = '';
    final decoder = UtfDecoder(id, hasSink: false, onBom: onBom);

    for (var curLength = 0; ; curLength = 0) {
      if (onByteIo != null) {
        curLength = onByteIo(bytes);

        if (curLength == 0) {
          if (asLines && chunk.isNotEmpty) {
            _processReadChunkAsLinesSync(params, onUtfIo, withPosixLineBreaks, asLines);
          }
          break;
        }

        final next = decoder.convert(bytes, 0, curLength);

        params.current = chunk + (withPosixLineBreaks
            ? toPosixLineBreaks(next)
            : next);
      } else if (chunk.isEmpty) {
        break;
      } else {
        params.current = chunk;
      }

      var end = 0;

      if (asLines) {
        end = _processReadChunkAsLinesSync(params, onUtfIo, withPosixLineBreaks, false);
      } else {
        end = _processReadChunkAsStringSync(params, onUtfIo);
      }

      if (end < 0) {
        break;
      }
  
      if (end > 0) {
        chunk = params.current!.substring(end);
      }
    }
  }

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  static List<String> readAsLinesSync(String id,
          {dynamic extra,
          int? maxLength,
          UtfBomHandler? onBom,
          ByteIoHandlerSync? onByteIo,
          UtfIoHandlerSync? onUtfIo,
          List<String>? pileup,
          bool withPosixLineBreaks = true}) {
      _readAllSync(id,
          asLines: true,
          extra: extra,
          maxLength: maxLength,
          onBom: onBom,
          onByteIo: onByteIo,
          onUtfIo: onUtfIo,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks);

      return pileup ?? <String>[];
  }

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  static String readAsStringSync(String id,
          {dynamic extra,
          int? maxLength,
          UtfBomHandler? onBom,
          ByteIoHandlerSync? onByteIo,
          UtfIoHandlerSync? onUtfIo,
          StringBuffer? pileup,
          bool withPosixLineBreaks = true}) {
      _readAllSync(id,
          asLines: false,
          extra: extra,
          maxLength: maxLength,
          onBom: onBom,
          onByteIo: onByteIo,
          onUtfIo: onUtfIo,
          pileup: pileup,
          withPosixLineBreaks: withPosixLineBreaks);

      return pileup?.toString() ?? '';
  }

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  static void writeAsLinesSync(String id,
          List<String> lines,
          {dynamic extra,
          int? maxLength,
          ByteIoHandlerSync? onByteIo,
          UtfIoHandlerSync? onUtfIo,
          UtfType type = UtfType.none,
          bool withBom = true,
          bool withPosixLineBreaks = true}) {
    var chunk = '';

    final encoder = UtfEncoder(id, hasSink: false, type: type, withBom: withBom);

    final params =
        UtfIoParams(extra: extra, isSyncCall: true, pileup: lines);

    for (var i = 0, n = lines.length; i < n; i++) {
      if (i > 0) {
        chunk = UtfConst.lineBreak;
      }

      params.current = lines[i];
      chunk += params.current!;

      if (writeChunkSync(encoder, chunk, onByteIo: onByteIo, onUtfIo: onUtfIo,
            params: params, withPosixLineBreaks: withPosixLineBreaks).isStop) {
        break;
      }
    }
  }

  /// Read stdin content as UTF (blocking) and convert it to string.\
  /// If [withPosixLineBreaks] is true, replace all occurrences of
  /// Windows- and Mac-specific line break with the UNIX one
  ///
  static void writeAsStringSync(String id,
          String content,
          {dynamic extra,
          int? maxLength,
          ByteIoHandlerSync? onByteIo,
          UtfIoHandlerSync? onUtfIo,
          UtfType type = UtfType.none,
          bool withBom = true,
          bool withPosixLineBreaks = true}) {
    final encoder = UtfEncoder(id, hasSink: false, type: type, withBom: withBom);
    final fullLength = content.length;

    if (maxLength == null) {
      maxLength = fullLength;

      if (maxLength > UtfConfig.maxBufferLength) {
        maxLength = UtfConfig.maxBufferLength;
      }
    } else if (maxLength > fullLength) {
      maxLength = fullLength;
    }

    final params =
        UtfIoParams(extra: extra, isSyncCall: true, pileup: content);

    var chunk = '';
    var chunkLength = maxLength;
    var start = 0;

    do {
      if ((start + maxLength) >= fullLength) {
        chunk = (start == 0 ? content : content.substring(start));
        chunkLength = (fullLength - start);
      } else {
        chunk = content.substring(start, maxLength);
        chunkLength = maxLength;
      }

      if (writeChunkSync(encoder, chunk, onByteIo: onByteIo, onUtfIo: onUtfIo,
            params: params, withPosixLineBreaks: withPosixLineBreaks).isStop) {
        break;
      }
    } while (chunkLength == maxLength);
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  static VisitResult writeChunkSync(
      UtfEncoder encoder,
      String chunk,
      {ByteIoHandlerSync? onByteIo,
      UtfIoHandlerSync? onUtfIo,
      UtfIoParams? params,
      bool withPosixLineBreaks = true}) {
    var result = VisitResult.take;

    ++params?.currentNo;

    if (!withPosixLineBreaks) {
      chunk = UtfHelper.fromPosixLineBreaks(chunk);
    }

    params?.current = chunk;

    if ((onUtfIo != null) && (params != null)) {
      result = onUtfIo(params);
    }

    if (result.isTake) {
      ++params?.takenNo;

      if (withPosixLineBreaks) {
        chunk = fromPosixLineBreaks(chunk);
      }

      if (onByteIo != null) {
        onByteIo(encoder.convert(chunk));
      }
    }

    return result;
  }

  /// Replace all occurrences of Windows and old Mac specific
  /// line breaks with the POSIX ones
  ///
  static String toPosixLineBreaks(String input) => input
    .replaceAll(UtfConst.lineBreakWin, UtfConst.lineBreak)
    .replaceAll(UtfConst.lineBreakMac, UtfConst.lineBreak);
}