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
  /// Add UTF bytes
  ///
  void _addUtfChunk(UtfEncoder encoder, String chunk) {
    final bytes = encoder.convert(chunk);

    if (bytes.isNotEmpty) {
      add(bytes);
    }
  }

  /// Close the sink (blocking)
  ///
  void _closeSync() {
    var isClosed = false;
    flush().then((_) => close().then((_) => isClosed = true));
    while (!isClosed) { }
  }

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<void> writeUtfAsLines(
    String id,
    List<String> lines,
    {UtfType type = UtfType.none,
    UtfWriteHandler? onWrite,
    dynamic extra,
    bool? withBom,
    bool withPosixLineBreaks = true}) async {

    final encoder = UtfEncoder(id, sink: this, type: type, withBom: withBom ?? (type != UtfType.none));
    final isSyncCall = (onWrite is UtfWriteHandlerSync);
    final params = UtfWriteParams(extra: encoder, isSyncCall: isSyncCall);

    for (final line in lines) {
      params.current = line;
      await writeUtfChunk(encoder, line, onWrite: onWrite, params: params, withPosixLineBreaks: withPosixLineBreaks);
    }

    await flush();
    await close();
  }

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  void writeUtfAsLinesSync(
    String id,
    List<String> lines,
    {UtfType type = UtfType.none,
    UtfWriteHandlerSync? onWrite,
    dynamic extra,
    bool? withBom,
    bool withPosixLineBreaks = true}) async {

    final encoder = UtfEncoder(id, sink: this, type: type, withBom: withBom ?? (type != UtfType.none));
    final params = UtfWriteParams(extra: encoder);

    for (final line in lines) {
      params.current = line;
      writeUtfChunkSync(encoder, line, onWrite: onWrite, params: params, withPosixLineBreaks: withPosixLineBreaks);
    }

    _closeSync();
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<void> writeUtfAsString(
    String id,
    String content,
    {UtfType type = UtfType.none,
    dynamic extra,
    bool? withBom,
    bool withPosixLineBreaks = true}) async {

    final encoder = UtfEncoder(id, sink: this, type: type, withBom: withBom ?? (type != UtfType.none));
    final params = UtfWriteParams(current: content, extra: encoder);
    await writeUtfChunk(encoder, content, params: params, withPosixLineBreaks: withPosixLineBreaks);
    await flush();
    await close();
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<void> writeUtfAsStringSync(
    String id,
    String content,
    {dynamic extra,
    UtfWriteHandlerSync? onWrite,
    UtfType type = UtfType.none,
    bool? withBom,
    bool withPosixLineBreaks = true}) async {

    final encoder = UtfEncoder(id, sink: this, type: type, withBom: withBom ?? (type != UtfType.none));
    final params = UtfWriteParams(current: content, extra: encoder);
    writeUtfChunkSync(encoder, content, params: params, withPosixLineBreaks: withPosixLineBreaks);
    _closeSync();
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<VisitResult> writeUtfChunk(
      UtfEncoder encoder,
      String chunk,
      {UtfWriteHandler? onWrite,
      UtfWriteParams? params,
      bool withPosixLineBreaks = true}) async {
    final isSyncCall = params?.isSyncCall ?? (onWrite is UtfWriteHandlerSync);
    FutureOr<VisitResult> result = VisitResult.take;

    ++params?.currentNo;

    if (!withPosixLineBreaks) {
      chunk = UtfStringStream.fromPosixLineBreaks(chunk);
    }

    params?.current = chunk;

    if ((onWrite != null) && (params != null)) {
      result = (isSyncCall ? onWrite(params) : await onWrite(params));
    }

    if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
      ++params?.takenNo;
      _addUtfChunk(encoder, chunk);
    }

    return result;
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  VisitResult writeUtfChunkSync(
      UtfEncoder encoder,
      String chunk,
      {UtfWriteHandlerSync? onWrite,
      UtfWriteParams? params,
      bool withPosixLineBreaks = true}) {
    var result = VisitResult.take;

    ++params?.currentNo;

    if (!withPosixLineBreaks) {
      chunk = UtfStringStream.fromPosixLineBreaks(chunk);
    }

    params?.current = chunk;

    if ((onWrite != null) && (params != null)) {
      result = onWrite(params);
    }

    if ((result == VisitResult.take) || (result == VisitResult.takeAndStop)) {
      ++params?.takenNo;
      _addUtfChunk(encoder, chunk);
    }

    return result;
  }
}
