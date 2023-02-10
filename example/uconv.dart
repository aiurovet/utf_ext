// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'dart:io';

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

/// Command-line options
///
class Options {
  /// Const: application name
  ///
  static const appName = 'uconv';

  /// Const: application version
  ///
  static const appVersion = '0.1.0';

  /// Option flag: read file line by line synchronously
  ///
  var isSyncCall = false;

  /// Read file or stdin line by line when value != null,
  /// and limit to the number of lines when value > 0
  ///
  int? maxLineCount;

  final paths = <String>[];

  var toType = UtfType.fallbackForWrite;

  /// Primitive command-line parser
  ///
  void parse(List<String> args) {
    var optDefs = '''
      |?,h,help|q,quiet|v,verbose|l,line:?|s,sync|t,to:|::?
    ''';

    var o = parseArgs(optDefs, args);

    _logger.levelFromFlags(isQuiet: o.isSet('q'), isVerbose: o.isSet('v'));

    if (o.isSet('?')) {
      usage();
    }

    maxLineCount = o.getIntValue('l');
    isSyncCall = o.isSet('s');
    toType = UtfType.parse(o.getStrValue('t'), UtfType.fallbackForWrite);

    paths.addAll(o.getStrValues(''));
    paths.removeWhere((x) => x.trim().isEmpty);
  }
}

/// Data for writing the output in chunks upon each read
///
class OutInfo {
  /// Target sink
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

  /// Destruction (non-blocking)
  ///
  Future<void> flushAndClose() async => await sink.flushAndClose();

  /// Destruction (blocking)
  ///
  void flushAndCloseSync() => sink.flushAndClose();

  /// Write piece of data (non-blocking)
  ///
  Future<void> writeUtfChunk(UtfReadExtraParams? params) async =>
      await sink.writeUtfChunk(encoder, params!.buffer!);

  /// Write piece of data (blocking)
  ///
  void writeUtfChunkSync(UtfReadExtraParams? params) =>
      sink.writeUtfChunkSync(encoder, params!.buffer!);
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

/// Write any chunk of text to the output sink (non-blocing)
///
Future<VisitResult> convChunk(UtfReadParams params) async {
  await (params.extra as OutInfo).writeUtfChunk(params.current);

  return VisitResult.take;
}

/// Write any chunk of text to the output sink (non-blocing)
///
VisitResult convChunkSync(UtfReadParams params) {
  (params.extra as OutInfo).writeUtfChunkSync(params.current);

  return VisitResult.take;
}

/// Write a line of text to the output sink (non-blocing)
///
FutureOr<VisitResult> convLine(UtfReadParams params) async {
  final maxLineCount = _opts.maxLineCount ?? 0;
  final takenNo = params.takenNo + 1;
  final canStop = ((maxLineCount > 0) && (takenNo >= maxLineCount));

  (params.extra as OutInfo).writeUtfChunkSync(params.current);

  return (canStop ? VisitResult.takeAndStop : VisitResult.take);
}

/// Write a line of text to the output sink (non-blocing)
///
VisitResult convLineSync(UtfReadParams params) {
  final maxLineCount = _opts.maxLineCount ?? 0;
  final takenNo = params.takenNo + 1;
  final canStop = ((maxLineCount > 0) && (takenNo >= maxLineCount));

  (params.extra as OutInfo).writeUtfChunkSync(params.current);

  return (canStop ? VisitResult.takeAndStop : VisitResult.take);
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
  final isSync = _opts.isSyncCall;
  final isFound = (isSync ? inpFile.existsSync() : await inpFile.exists());
  final maxLineCount = _opts.maxLineCount;
  final toType = _opts.toType;

  if (!isFound) {
    _logger.error('File does not exist: "${inpFile.path}"');
    return;
  }

  final outFile = _fs.file(toOutPath(path));
  final outSink = outFile.openWrite();
  final outInfo = OutInfo(outFile.path, outSink, type: toType);

  if (maxLineCount == null) {
    if (isSync) {
      inpFile.readUtfAsStringSync(onRead: convChunkSync, extra: outInfo);
      outInfo.flushAndCloseSync();
    } else {
      await inpFile.readUtfAsString(onRead: convChunk, extra: outInfo);
      await outInfo.flushAndClose();
    }
  } else {
    if (isSync) {
      inpFile.forEachUtfLineSync(onLine: convLineSync, extra: outInfo);
      outInfo.flushAndCloseSync();
    } else {
      await inpFile.forEachUtfLine(onLine: convLine, extra: outInfo);
      await outInfo.flushAndClose();
    }
  }
}

/// Process stdin
///
Future<void> processStdin() async {
  final isSync = _opts.isSyncCall;
  final maxLineCount = _opts.maxLineCount;
  final toType = _opts.toType;

  final outInfo = OutInfo(UtfStdout.name, stdout, type: toType);

  if (maxLineCount == null) {
    if (isSync) {
      stdin.readUtfAsStringSync(onRead: convChunkSync, extra: outInfo);
      stdout.flushAndCloseSync();
    } else {
      await stdin.readUtfAsString(onRead: convChunk, extra: outInfo);
      await stdout.flushAndClose();
    }
  } else {
    if (isSync) {
      stdin.forEachLineSync(onLine: convLineSync, extra: outInfo);
      stdout.flushAndCloseSync();
    } else {
      await stdin.forEachLine(onLine: convLine, extra: outInfo);
      await stdout.flushAndClose();
    }
  }
}

/// Convert input path into output path
///
String toOutPath(String inpPath) {
  final fsPath = _fs.path;
  final inpDir = fsPath.dirname(inpPath);
  final inpName = fsPath.basenameWithoutExtension(inpPath);
  final inpExt = fsPath.extension(inpPath);

  return fsPath.join(inpDir, '${inpName}_${_opts.toType.name}$inpExt');
}

/// Print help
///
Never usage() {
  _logger.info('''
USAGE:

${Options.appName} [OPTIONS] [ARGUMENTS]

OPTIONS:

-?, -h[elp]      - this help screen
-l[ine] [MAXNUM] - convert line by line (default: convert chunks of text),
                   limit to MAXNUM (default: no limit)
-s[ync]          - convert synchronously
-t[o] TYPE       - convert the input into the output of the given type (default: utf8 without BOM)

ARGUMENTS:

Path(s) or name(s) of file(s) to print
If none specified, print the content of ${UtfStdin.name} to ${UtfStdout.name})
''');

  exit(1);
}
