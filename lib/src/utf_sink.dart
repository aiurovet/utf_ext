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

  /// Convert a list of strings to a sequence of UTF bytes and write those to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<void> writeUtfAsLines(String id, List<String> lines,
      {UtfType type = UtfType.none,
      UtfIoHandler? onUtfIo,
      dynamic extra,
      bool? withBom,
      bool withPosixLineBreaks = true}) async {
    final encoder = UtfEncoder(id,
        sink: this, type: type, withBom: withBom ?? (type != UtfType.none));
    final isSyncCall = (onUtfIo is UtfIoHandlerSync);
    final params = UtfIoParams(extra: extra, isSyncCall: isSyncCall);

    for (final line in lines) {
      params.current = line;

      await writeUtfChunk(encoder, line,
          onUtfIo: onUtfIo,
          params: params,
          withPosixLineBreaks: withPosixLineBreaks);
    }
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<void> writeUtfAsString(String id, String content,
      {dynamic extra,
      UtfIoHandler? onUtfIo,
      UtfType type = UtfType.none,
      bool? withBom,
      bool withPosixLineBreaks = true}) async {
    final encoder = UtfEncoder(id, sink: this, type: type, withBom: withBom ?? (type != UtfType.none));
    final params = UtfIoParams(current: content, extra: extra);

    await writeUtfChunk(encoder, content,
        onUtfIo: onUtfIo,
        params: params,
        withPosixLineBreaks: withPosixLineBreaks);
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<VisitResult> writeUtfChunk(UtfEncoder encoder, String chunk,
      {UtfIoHandler? onUtfIo,
      UtfIoParams? params,
      bool withPosixLineBreaks = true}) async {
    final isSyncCall = params?.isSyncCall ?? (onUtfIo is UtfIoHandlerSync);
    var result = VisitResult.take;

    if (!withPosixLineBreaks) {
      chunk = UtfHelper.fromPosixLineBreaks(chunk);
    }

    ++params?.currentNo;
    params?.current = chunk;

    if ((onUtfIo != null) && (params != null)) {
      result = (isSyncCall ? onUtfIo(params) : await onUtfIo(params)) as VisitResult;
    }

    if (result.isTake) {
      ++params?.takenNo;
      _addUtfChunk(encoder, chunk);
    }

    return result;
  }

  /// Convert string to a sequence of UTF bytes and write that to [sink] (non-blocking).\
  /// If [withPosixLineBreaks] is off, replace all occurrences of POSIX line breaks with
  /// the Windows-specific ones
  ///
  Future<VisitResult> writeUtfChunkSync(UtfEncoder encoder, String chunk,
      {UtfIoHandlerSync? onUtfIo,
      UtfIoParams? params,
      bool withPosixLineBreaks = true}) async {
    var result = VisitResult.take;

    if (!withPosixLineBreaks) {
      chunk = UtfHelper.fromPosixLineBreaks(chunk);
    }

    ++params?.currentNo;
    params?.current = chunk;

    if ((onUtfIo != null) && (params != null)) {
      result = onUtfIo(params);
    }

    if (result.isTake) {
      ++params?.takenNo;
      _addUtfChunk(encoder, chunk);
    }

    return result;
  }
}
