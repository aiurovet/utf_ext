// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'dart:io';
import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Helper class to manage text files written in any
/// of the Unicode encodings: UTF-8, UTF-16, UTF-32
///
extension UtfSink on IOSink {
  /// Converts [chunk] of text to bytes and adds that to IOSink
  ///
  void _addUtfChunk(UtfEncoder encoder, String chunk) {
    final bytes = encoder.convert(chunk);

    if (bytes.isNotEmpty) {
      add(bytes);
    }
  }

  /// Converts a sequence of strings into bytes and adds those to IOSink (non-blocking)\
  /// \
  /// [id] - a string id (path or name)\
  /// [lines] - the whole content broken into lines with no line break
  /// [extra] - user-defined data\
  /// [type] - UTF type\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [withBom] - if true (default if [type] is defined) byte order mark is printed\
  /// [withPosixLineBreaks] - if true (default), use LF as a line break; otherwise, use CR/LF\
  /// [lineBreakAtEnd] - if true (default), ensure the output ends with the line break
  ///
  Future<void> writeUtfAsLines(String id, List<String> lines,
      {dynamic extra,
      UtfIoHandler? onWrite,
      UtfType type = UtfType.none,
      bool? withBom,
      bool withPosixLineBreaks = true,
      bool lineBreakAtEnd = true}) async {
    final encoder = UtfEncoder(id,
        sink: this, type: type, withBom: withBom ?? (type != UtfType.none));
    final isSyncCall = (onWrite is UtfIoHandlerSync);
    final params = UtfIoParams(extra: extra, isSyncCall: isSyncCall);

    for (final line in lines) {
      params.current = line;

      String chunk;

      if (lineBreakAtEnd) {
        chunk = params.current! + UtfConst.lineBreak;
      } else {
        chunk =
            (params.currentNo > 0 ? UtfConst.lineBreak : '') + params.current!;
      }

      await writeUtfChunk(encoder, chunk,
          onWrite: onWrite,
          params: params,
          withPosixLineBreaks: withPosixLineBreaks);
    }
  }

  /// Converts a sequence of strings into bytes and adds those to IOSink (blocking)\
  /// \
  /// [id] - id of this sink (a file path or <stdout>)
  /// [content] - the whole content to write\
  /// [maxLength] - maximum buffer length (when null, use [UtfConfig.maxBufferLength])\
  /// [extra] - user-defined data\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [type] - UTF type
  /// [withBom] - if true (default if [type] is defined) byte order mark is printed\
  /// [withPosixLineBreaks] - if true (default), use LF as a line break; otherwise, use CR/LF\
  /// [lineBreakAtEnd] - if true (default), ensure the output ends with the line break
  ///
  Future<void> writeUtfAsString(String id, String content,
      {dynamic extra,
      int? maxLength,
      UtfIoHandler? onWrite,
      UtfType type = UtfType.none,
      bool? withBom,
      bool withPosixLineBreaks = true,
      bool lineBreakAtEnd = true}) async {
    final encoder = UtfEncoder(id,
        sink: this, type: type, withBom: withBom ?? (type != UtfType.none));
    final fullLength = content.length;

    if (maxLength == null) {
      maxLength = fullLength;

      if (maxLength > UtfConfig.maxBufferLength) {
        maxLength = UtfConfig.maxBufferLength;
      }
    } else if (maxLength > fullLength) {
      maxLength = fullLength;
    }

    final isSyncCall = onWrite is UtfIoHandlerSync;
    final params =
        UtfIoParams(extra: extra, isSyncCall: isSyncCall, pileup: content);

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

      if ((await writeUtfChunk(encoder, chunk,
              onWrite: onWrite,
              params: params,
              withPosixLineBreaks: withPosixLineBreaks))
          .isStop) {
        break;
      }

      start = chunkLength;
    } while (chunkLength == maxLength);
  }

  /// Converts a [chunk] of text into bytes and adds those to IOSink (non-blocking),\
  /// can be called sequentially\
  /// \
  /// [encoder] - the UTF ecoder\
  /// [chunk] - a chunk of text to convert and write\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [params] - current cvhunk info holder
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  Future<VisitResult> writeUtfChunk(UtfEncoder encoder, String chunk,
      {UtfIoHandler? onWrite,
      UtfIoParams? params,
      bool withPosixLineBreaks = true}) async {
    final isSyncCall = params?.isSyncCall ?? (onWrite is UtfIoHandlerSync);
    var result = VisitResult.take;

    if (!withPosixLineBreaks) {
      chunk = UtfHelper.fromPosixLineBreaks(chunk);
    }

    ++params?.currentNo;
    params?.current = chunk;

    if ((onWrite != null) && (params != null)) {
      result =
          (isSyncCall ? onWrite(params) : await onWrite(params)) as VisitResult;
    }

    if (result.isTake) {
      ++params?.takenNo;
      _addUtfChunk(encoder, chunk);
    }

    return result;
  }

  /// Converts a [chunk] of text into bytes and adds those to IOSink (blocking),\
  /// can be called sequentially\
  /// \
  /// [encoder] - UTF encoder\
  /// [chunk] - chunk of text\
  /// [onWrite] - a function called upon every chunk of text before being written\
  /// [params] - current chunk info holder\
  /// [withPosixLineBreaks] - if true (default) use LF as a line break; otherwise, use CR/LF
  ///
  Future<VisitResult> writeUtfChunkSync(UtfEncoder encoder, String chunk,
      {UtfIoHandlerSync? onWrite,
      UtfIoParams? params,
      bool withPosixLineBreaks = true}) async {
    var result = VisitResult.take;

    if (!withPosixLineBreaks) {
      chunk = UtfHelper.fromPosixLineBreaks(chunk);
    }

    ++params?.currentNo;
    params?.current = chunk;

    if ((onWrite != null) && (params != null)) {
      result = onWrite(params);
    }

    if (result.isTake) {
      ++params?.takenNo;
      _addUtfChunk(encoder, chunk);
    }

    return result;
  }
}
