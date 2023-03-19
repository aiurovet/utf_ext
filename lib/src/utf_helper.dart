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
      var line = chunk.substring(start, endEx);

      if (onRead != null) {
        params.current = line;
        result = onRead(params);
      }

      if (result.isTake) {
        ++params.takenNo;
        pileup?.add(params.current ?? '');
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
    ++params.currentNo;

    final result = (onRead == null ? VisitResult.take : onRead(params));

    if (result.isStop) {
      return -1;
    }

    final chunk = params.current ?? '';

    if (result.isTake) {
      ++params.takenNo;
      (params.pileup as StringBuffer?)?.write(chunk);
    }

    return chunk.length;
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

    maxLength ??= UtfConfig.bufferLength;

    final bytes = List<int>.filled(maxLength, 0);
    var prev = '';
    final decoder = UtfDecoder(id, hasSink: false, onBom: onBom);

    for (var curLength = 0;; curLength = 0) {
      if (byteReader != null) {
        curLength = byteReader(bytes);
      }

      if (curLength == 0) {
        if (asLines && prev.isNotEmpty) {
          _processReadChunkAsLinesSync(
              params, onRead, withPosixLineBreaks, asLines);
        }
        break;
      }

      var chunk = decoder.convert(bytes, 0, curLength);

      if (withPosixLineBreaks) {
        chunk = toPosixLineBreaks(chunk);
      }

      chunk = prev + chunk;
      params.current = chunk;

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

      prev = chunk.substring(end);
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
  static int readAsLinesSync(String id,
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

    return pileup?.length ?? 0;
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
  static int readAsStringSync(String id,
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

    return pileup?.length ?? 0;
  }

  /// Converts a list of strings into bytes and saves those as a UTF file (non-blocking)\
  /// Every line assumed not having a line break which will be appended before write to
  /// ensure any further append to this file will start from the new line\
  /// \
  /// [id] - a string id (path or name)\
  /// [lines] - a list of strings to save
  /// [byteWriter] - function called to perform an actual writing of bytes from some source\
  /// [extra] - user-defined data\
  /// [maxLength] - limits the size of a read buffer
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [type] - UTF type\
  /// [withBom] - if true (default if [type] is defined) byte order mark is written
  /// [withPosixLineBreaks] - if true (default), replace each CR/LF with LF\
  /// [lineBreakAtEnd] - if true (default), ensure the output ends with the line break
  ///
  static void writeAsLinesSync(String id, List<String> lines,
      {ByteWriterSync? byteWriter,
      dynamic extra,
      int? maxLength,
      UtfIoHandlerSync? onWrite,
      UtfType type = UtfType.none,
      bool? withBom,
      bool withPosixLineBreaks = true,
      bool lineBreakAtEnd = true}) {
    var chunk = '';

    final encoder =
        UtfEncoder(id, hasSink: false, type: type, withBom: withBom);

    final params = UtfIoParams(extra: extra, isSyncCall: true, pileup: lines);

    for (var i = 0, n = lines.length; i < n; i++) {
      params.current = lines[i];

      if (lineBreakAtEnd) {
        chunk = params.current! + UtfConst.lineBreak;
      } else {
        chunk =
            (params.currentNo > 0 ? UtfConst.lineBreak : '') + params.current!;
      }

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
  /// [id] - a string id (path or name)\
  /// [content] - a string to write (the whole content)\
  /// [extra] - user-defined data\
  /// [maxLength] - limits the size of a read buffer
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is written
  /// [withPosixLineBreaks] - if true (default), use LF as a line break; otherwise, use CR/LF\
  /// [lineBreakAtEnd] - if true (default), ensure the output ends with the line break
  ///
  static void writeAsStringSync(String id, String content,
      {ByteWriterSync? byteWriter,
      dynamic extra,
      int? maxLength,
      UtfIoHandlerSync? onWrite,
      UtfType type = UtfType.none,
      bool? withBom,
      bool withPosixLineBreaks = true,
      bool lineBreakAtEnd = true}) {
    final encoder =
        UtfEncoder(id, hasSink: false, type: type, withBom: withBom);
    final fullLength = content.length;

    if (maxLength == null) {
      maxLength = fullLength;

      if (maxLength > UtfConfig.bufferLength) {
        maxLength = UtfConfig.bufferLength;
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

        if (lineBreakAtEnd && !chunk.endsWith(UtfConst.lineBreak)) {
          chunk += UtfConst.lineBreak;
          chunkLength += UtfConst.lineBreak.length;
        }
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

    if (!withPosixLineBreaks) {
      chunk = UtfHelper.fromPosixLineBreaks(chunk);
    }

    if (params != null) {
      ++params.currentNo;
      params.current = chunk;

      if (onWrite != null) {
        result = onWrite(params);
        chunk = params.current ?? '';
      }
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
