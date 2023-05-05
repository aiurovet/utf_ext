// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'dart:io';

/// This example depends on the following packages:
///
/// - loop_visitor
/// - parse_args
/// - thin_logger

import 'package:file/local.dart';
import 'package:loop_visitor/loop_visitor.dart';
import 'package:parse_args/parse_args.dart';
import 'package:thin_logger/thin_logger.dart';
import 'package:utf_ext/utf_ext.dart';

/// Singleton: file system
///
final _fs = LocalFileSystem();

/// Singleton: options
///
final _logger = Logger();

/// Singleton: options
///
final _opts = Options();

/// Internal class for convLine/Sync()
///
class ConvLineInfo {
  /// Flag indicating the end of loop
  ///
  var canStop = false;

  /// I/O buffer
  ///
  var buffer = '';
}

/// Command-line options
///
class Options {
  /// Const: application name
  ///
  static const appName = 'utf_conv';

  /// Const: application version
  ///
  static const appVersion = '1.0.0';

  /// Option flag: to stdout rather than to file
  ///
  var isStdOut = false;

  /// Option flag: read file line by line synchronously
  ///
  var isSyncCall = false;

  /// Read file or stdin line by line when value != null,
  /// and limit to the number of lines when value > 0
  ///
  int? maxLineCount;

  final paths = <String>[];

  var toType = UtfConfig.fallbackForWrite;

  /// Simple command-line parser using `parse_args` package
  ///
  void parse(List<String> args) {
    var optDefs = '''
      |?,h,help|q,quiet|v,verbose
      |b,buf,bufsize:|l,line:?|s,sync,synch
      |t,to:|u,stdout|::?
    ''';

    var o = parseArgs(optDefs, args);

    _logger.levelFromFlags(isQuiet: o.isSet('q'), isVerbose: o.isSet('v'));

    if (o.isSet('?')) {
      usage();
    }

    _setBufferLength(o.getIntValue('b'));

    maxLineCount = o.getIntValue('l');
    isStdOut = o.isSet('u');
    isSyncCall = o.isSet('s');
    toType = UtfType.parse(o.getStrValue('t'), UtfConfig.fallbackForWrite);

    paths.addAll(o.getStrValues(''));
    paths.removeWhere((x) => x.trim().isEmpty);
  }

  /// Set the buffer size
  ///
  void _setBufferLength(int? value) {
    if ((value != null) && (value > 0)) {
      UtfConfig.bufferLength = value;
    }
  }
}

/// Helper class for writing the output in chunks upon each read
///
class OutInfo {
  /// Output sink
  ///
  final IOSink sink;

  /// Encoder
  ///
  late final UtfEncoder encoder;

  /// Default constructor
  ///
  OutInfo(String id, this.sink, {UtfType type = UtfType.none}) {
    encoder = UtfEncoder(id, sink: sink, type: type);
  }

  /// Write piece of data (non-blocking)
  ///
  Future<void> writeUtfChunk(String chunk) async =>
      await sink.writeUtfChunk(encoder, chunk);

  /// Write piece of data (blocking)
  ///
  void writeUtfChunkSync(String chunk) =>
      sink.writeUtfChunkSync(encoder, chunk);
}

/// Write any chunk of text to the output sink (non-blocing)
///
Future<VisitResult> convChunk(UtfIoParams params) async {
  await (params.extra as OutInfo).writeUtfChunk(params.current!);

  return VisitResult.take;
}

/// Write any chunk of text to the output sink (non-blocing)
///
VisitResult convChunkSync(UtfIoParams params) {
  (params.extra as OutInfo).writeUtfChunkSync(params.current!);

  return VisitResult.take;
}

/// Write a line of text to the output sink (non-blocing)
///
Future<VisitResult> convLine(UtfIoParams params) async {
  final info = _convLine(params);
  await (params.extra as OutInfo).writeUtfChunk(info.buffer);

  return (info.canStop ? VisitResult.takeAndStop : VisitResult.take);
}

/// Write a line of text to the output sink (blocking)
///
VisitResult convLineSync(UtfIoParams params) {
  final info = _convLine(params);
  (params.extra as OutInfo).writeUtfChunkSync(info.buffer);

  return (info.canStop ? VisitResult.takeAndStop : VisitResult.take);
}

/// Write a line of text to the output sink (blocking)
///
ConvLineInfo _convLine(UtfIoParams params) {
  final maxLineCount = _opts.maxLineCount ?? 0;
  final takenNo = params.takenNo + 1;
  final result = ConvLineInfo();

  result.canStop = ((maxLineCount > 0) && (takenNo >= maxLineCount));
  result.buffer = '${params.current!}${UtfConst.lineBreak}';

  return result;
}

/// Entry point
///
Future<void> main(List<String> args) async {
  try {
    _opts.parse(args);

    if (_opts.paths.isEmpty) {
      await processStdin();
    } else {
      for (var path in _opts.paths) {
        await processFile(path);
      }
    }
  } on Error catch (e) {
    onFailure(e);
  } on Exception catch (e) {
    onFailure(e);
  }
}

/// Error handler
///
Never onFailure(dynamic e) {
  _logger.error(e.toString());
  exit(1);
}

/// Process single file
///
Future<void> processFile(String path) async {
  final inpFile = _fs.file(path);
  final isFound =
      (_opts.isSyncCall ? inpFile.existsSync() : await inpFile.exists());
  final toType = _opts.toType;

  if (!isFound) {
    _logger.error('File does not exist: "${inpFile.path}"');
    return;
  }

  final outFile = _fs.file(toOutPath(path));

  final outInfo = (_opts.isStdOut
      ? OutInfo(UtfStdout.name, stdout, type: toType)
      : OutInfo(outFile.path, outFile.openWrite(), type: toType));

  if (_opts.maxLineCount == null) {
    if (_opts.isSyncCall) {
      inpFile.readUtfAsStringSync(onRead: convChunkSync, extra: outInfo);
    } else {
      await inpFile.readUtfAsString(onRead: convChunk, extra: outInfo);
    }
  } else {
    if (_opts.isSyncCall) {
      inpFile.readUtfAsLinesSync(onRead: convLineSync, extra: outInfo);
    } else {
      await inpFile.readUtfAsLines(onRead: convLine, extra: outInfo);
    }
  }
}

/// Process stdin
///
Future<void> processStdin() async {
  final outInfo = OutInfo(UtfStdout.name, stdout, type: _opts.toType);

  if (_opts.maxLineCount == null) {
    if (_opts.isSyncCall) {
      stdin.readUtfAsStringSync(onRead: convChunkSync, extra: outInfo);
    } else {
      await stdin.readUtfAsString(onRead: convChunk, extra: outInfo);
    }
  } else {
    if (_opts.isSyncCall) {
      stdin.readUtfAsLinesSync(onRead: convLineSync, extra: outInfo);
    } else {
      await stdin.readUtfAsLines(onRead: convLine, extra: outInfo);
    }
  }
}

/// Convert input path into output path
///
String toOutPath(String inpPath) {
  final fsPath = _fs.path;
  final inpDir = fsPath.dirname(inpPath);

  return fsPath.join(inpDir, 'write_${_opts.toType.name}.txt');
}

/// Print help
///
Never usage() {
  _logger.info('''
A tool to convert file or ${UtfStdin.name} content from one UTF format to another

USAGE:

${Options.appName} [OPTIONS] [ARGUMENTS]

OPTIONS:

-?, -h[elp]      - this help screen
-b[uf[size]] LEN - set the buffer length
-l[ine]      NUM - convert line by line (default: convert chunks of text),
                   limit to the first NUM lines (0 = no limit)
-s[ync]          - convert synchronously
-t[o] TYPE       - convert the input into the output of the given type (default: utf8 without BOM)
                   supported TYPEs: utf8 (with BOM or not), utf16le, utf16be, utf32le, utf32be

ARGUMENTS:

Path(s) or name(s) of file(s) to print
If none specified, print the content of ${UtfStdin.name} to ${UtfStdout.name})
''');

  exit(1);
}
