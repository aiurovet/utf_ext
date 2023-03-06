// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Common helpers
///
class UtfHelper {
  /// Replace every LF with CR/LF without affecting the existing CR/LFs
  ///
  static String fromPosixLineBreaks(String input) => input
      .replaceAll(UtfConst.lineBreakWin, '\x01')
      .replaceAll(UtfConst.lineBreak, UtfConst.lineBreakWin)
      .replaceAll('\x01', UtfConst.lineBreakWin);

  /// Process chunk of data line by line
  ///
  static int _processReadChunkAsLinesSync(UtfIoParams params,
      UtfIoHandlerSync? onRead, bool withPosixLineBreaks, bool isEnd) {
    final chunk = params.current!;
    var length = chunk.length;

    if (length <= 0) {
      return 0;
    }

    final pileup = params.pileup as List<String>?;
    var result = VisitResult.take;

    for (var start = 0, end = 0; start < length; start = end + 1) {
      end = chunk.indexOf(UtfConst.lineBreak, start);

      if (end < 0) {
        if (isEnd) {
          end = length;
        } else {
          return start;
        }
      }

      var endEx = end;

      if ((end > start) && !withPosixLineBreaks) {
        if (chunk[end - 1] == UtfConst.lineBreakMac) {
          --endEx;
        }
      }

      ++params.currentNo;
      final line = chunk.substring(start, endEx);

      if (onRead != null) {
        params.current = line;
        result = onRead(params);
        params.current = chunk;
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
      UtfIoParams params, UtfIoHandlerSync? onRead) {
    final chunk = params.current!;
    final length = chunk.length;

    ++params.currentNo;
    params.current = chunk;
    final result = (onRead == null ? VisitResult.take : onRead(params));
    final pileup = (result.isTake ? params.pileup : null);

    if ((pileup != null) && (length > 0)) {
      (pileup as StringBuffer).write(chunk);
    }

    return (result.isStop ? -1 : length);
  }

  /// Reads the content of a UTF source (blocking) and calls read handler.\
  /// \
  /// [asLines] - read as lines rather than in chunks\
  /// [byteReader] - function called to perform an actual reading of bytes from some source\
  /// [extra] - user-defined data\
  /// [maxLength] - limits the size of a read buffer
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every chunk of text after being read\
  /// [pileup] - if not null, accumulates the whole content under that\
  /// [withPosixLineBreaks] - if true (default) replace each CR/LF with LF
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  static void _readAllSync(String id,
      {bool asLines = false,
      ByteReaderSync? byteReader,
      dynamic extra,
      int? maxLength,
      UtfBomHandler? onBom,
      UtfIoHandlerSync? onRead,
      dynamic pileup,
      bool withPosixLineBreaks = true}) {
    final params = UtfIoParams(extra: extra, isSyncCall: true, pileup: pileup);
    pileup?.clear();

    maxLength ??= UtfConfig.maxBufferLength;

    final bytes = List<int>.filled(maxLength, 0);
    var chunk = '';
    final decoder = UtfDecoder(id, hasSink: false, onBom: onBom);

    for (var curLength = 0;; curLength = 0) {
      if (byteReader != null) {
        curLength = byteReader(bytes);

        if (curLength == 0) {
          if (asLines && chunk.isNotEmpty) {
            _processReadChunkAsLinesSync(
                params, onRead, withPosixLineBreaks, asLines);
          }
          break;
        }

        final next = decoder.convert(bytes, 0, curLength);

        params.current =
            chunk + (withPosixLineBreaks ? toPosixLineBreaks(next) : next);
      } else if (chunk.isEmpty) {
        break;
      } else {
        params.current = chunk;
      }

      var end = 0;

      if (asLines) {
        end = _processReadChunkAsLinesSync(
            params, onRead, withPosixLineBreaks, false);
      } else {
        end = _processReadChunkAsStringSync(params, onRead);
      }

      if (end < 0) {
        break;
      }

      chunk = params.current!;

      if (end > 0) {
        chunk = chunk.substring(end);
        params.current = chunk;
      }
    }
  }

  /// Reads the content of a UTF source (blocking) as a sequence of lines and calls read handler.\
  /// \
  /// [byteReader] - function called to perform an actual read of bytes from some source\
  /// [extra] - user-defined data\
  /// [maxLength] - limits the size of a read buffer
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every chunk of text after being read\
  /// [pileup] - if not null, accumulates the whole content under that\
  /// [withPosixLineBreaks] - if true (default) replace each CR/LF with LF
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  static List<String> readAsLinesSync(String id,
      {ByteReaderSync? byteReader,
      dynamic extra,
      int? maxLength,
      UtfBomHandler? onBom,
      UtfIoHandlerSync? onRead,
      List<String>? pileup,
      bool withPosixLineBreaks = true}) {
    _readAllSync(id,
        asLines: true,
        extra: extra,
        maxLength: maxLength,
        onBom: onBom,
        byteReader: byteReader,
        onRead: onRead,
        pileup: pileup,
        withPosixLineBreaks: withPosixLineBreaks);

    return pileup ?? <String>[];
  }

  /// Reads the content of a UTF source (blocking) as chunks of text and calls read handler.\
  /// \
  /// [byteReader] - function called to perform an actual reading of bytes from some source\
  /// [extra] - user-defined data\
  /// [maxLength] - limits the size of a read buffer
  /// [onBom] - a function called upon the read of the byte order mark\
  /// [onRead] - a function called upon every chunk of text after being read\
  /// [pileup] - if not null, accumulates the whole content under that\
  /// [withPosixLineBreaks] - if true (default) replace each CR/LF with LF
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  static String readAsStringSync(String id,
      {ByteReaderSync? byteReader,
      dynamic extra,
      int? maxLength,
      UtfBomHandler? onBom,
      UtfIoHandlerSync? onRead,
      StringBuffer? pileup,
      bool withPosixLineBreaks = true}) {
    _readAllSync(id,
        asLines: false,
        extra: extra,
        maxLength: maxLength,
        onBom: onBom,
        byteReader: byteReader,
        onRead: onRead,
        pileup: pileup,
        withPosixLineBreaks: withPosixLineBreaks);

    return pileup?.toString() ?? '';
  }

  /// Converts a list of strings into bytes and saves those as a UTF file (non-blocking)\
  /// Every line assumed not having a line break which will be appended before write to
  /// ensure any further append to this file will start from the new line
  /// \
  /// [lines] - list of strings to save
  /// [byteWriter] - function called to perform an actual writing of bytes from some source\
  /// [extra] - user-defined data\
  /// [maxLength] - limits the size of a read buffer
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [type] - UTF type\
  /// [withBom] - if true (default if [type] is defined) byte order mark is written
  /// [withPosixLineBreaks] - if true (default) replace each CR/LF with LF
  /// \
  /// Returns [pileup] if not null or an empty list otherwise
  ///
  static void writeAsLinesSync(String id, List<String> lines,
      {ByteWriterSync? byteWriter,
      dynamic extra,
      int? maxLength,
      UtfIoHandlerSync? onWrite,
      UtfType type = UtfType.none,
      bool? withBom,
      bool withPosixLineBreaks = true}) {
    var chunk = '';

    final encoder =
        UtfEncoder(id, hasSink: false, type: type, withBom: withBom);

    final params = UtfIoParams(extra: extra, isSyncCall: true, pileup: lines);

    for (var i = 0, n = lines.length; i < n; i++) {
      params.current = lines[i];
      chunk = params.current! + UtfConst.lineBreak;

      if (writeChunkSync(encoder, chunk,
              byteWriter: byteWriter,
              onWrite: onWrite,
              params: params,
              withPosixLineBreaks: withPosixLineBreaks)
          .isStop) {
        break;
      }
    }
  }

  /// Converts a list of strings into bytes and saves those as a UTF file (non-blocking)\
  /// If it does not end with a line break, that will be appended to ensure any further
  /// append to the sink will start from the new line
  /// \
  /// [content] - string to write (the whole content)\
  /// [extra] - user-defined data\
  /// [maxLength] - limits the size of a read buffer
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is written
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  static void writeAsStringSync(String id, String content,
      {ByteWriterSync? byteWriter,
      dynamic extra,
      int? maxLength,
      UtfIoHandlerSync? onWrite,
      UtfType type = UtfType.none,
      bool? withBom,
      bool withPosixLineBreaks = true}) {
    final encoder =
        UtfEncoder(id, hasSink: false, type: type, withBom: withBom);
    final fullLength = content.length;

    if (maxLength == null) {
      maxLength = fullLength;

      if (maxLength > UtfConfig.maxBufferLength) {
        maxLength = UtfConfig.maxBufferLength;
      }
    } else if (maxLength > fullLength) {
      maxLength = fullLength;
    }

    final params = UtfIoParams(extra: extra, isSyncCall: true, pileup: content);

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

      if (writeChunkSync(encoder, chunk,
              byteWriter: byteWriter,
              onWrite: onWrite,
              params: params,
              withPosixLineBreaks: withPosixLineBreaks)
          .isStop) {
        break;
      }

      start = chunkLength;
    } while (chunkLength == maxLength);
  }

  /// Converts a chunk of text into a sequence of UTF bytes and write that to the sink (non-blocking).\
  ///\
  /// [chunk] - a text chunk to write\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [params] - the current chunk info holder\
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  static VisitResult writeChunkSync(UtfEncoder encoder, String chunk,
      {ByteWriterSync? byteWriter,
      UtfIoHandlerSync? onWrite,
      UtfIoParams? params,
      bool withPosixLineBreaks = true}) {
    var result = VisitResult.take;

    ++params?.currentNo;

    if (!withPosixLineBreaks) {
      chunk = UtfHelper.fromPosixLineBreaks(chunk);
    }

    params?.current = chunk;

    if ((onWrite != null) && (params != null)) {
      result = onWrite(params);
    }

    if (result.isTake) {
      ++params?.takenNo;

      if (withPosixLineBreaks) {
        chunk = fromPosixLineBreaks(chunk);
      }

      if (byteWriter != null) {
        byteWriter(encoder.convert(chunk));
      }
    }

    return result;
  }

  /// Replaces every CR/LF and a standalone CR with LF
  ///
  static String toPosixLineBreaks(String input) => input
      .replaceAll(UtfConst.lineBreakWin, UtfConst.lineBreak)
      .replaceAll(UtfConst.lineBreakMac, UtfConst.lineBreak);
}
