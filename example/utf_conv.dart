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
  static const appName = 'utf_conv';

  /// Const: application version
  ///
  static const appVersion = '1.0.0';

  /// Option flag: read file line by line synchronously
  ///
  var isSyncCall = false;

  /// Read file or stdin line by line when value != null,
  /// and limit to the number of lines when value > 0
  ///
  int? maxLineCount;

  final paths = <String>[];

  var toType = UtfConfig.fallbackForWrite;

  /// Primitive command-line parser
  ///
  void parse(List<String> args) {
    var optDefs = '''
      |?,h,help|q,quiet|v,verbose|l,line:?|s,sync,synch|t,to:|::?
    ''';

    var o = parseArgs(optDefs, args);

    _logger.levelFromFlags(isQuiet: o.isSet('q'), isVerbose: o.isSet('v'));

    if (o.isSet('?')) {
      usage();
    }

    maxLineCount = o.getIntValue('l');
    isSyncCall = o.isSet('s');
    toType = UtfType.parse(o.getStrValue('t'), UtfConfig.fallbackForWrite);

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

  /// Write piece of data (non-blocking)
  ///
  Future<void> writeUtfChunk(String chunk) async =>
      await sink.writeUtfChunk(encoder, chunk);

  /// Write piece of data (blocking)
  ///
  void writeUtfChunkSync(String chunk) =>
      sink.writeUtfChunkSync(encoder, chunk);
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
FutureOr<VisitResult> convLine(UtfIoParams params) async {
  final maxLineCount = _opts.maxLineCount ?? 0;
  final takenNo = params.takenNo + 1;
  final canStop = ((maxLineCount > 0) && (takenNo >= maxLineCount));

  final buffer = '${params.current!}${UtfConst.lineBreak}';
  (params.extra as OutInfo).writeUtfChunkSync(buffer);

  return (canStop ? VisitResult.takeAndStop : VisitResult.take);
}

/// Write a line of text to the output sink (non-blocing)
///
VisitResult convLineSync(UtfIoParams params) {
  final maxLineCount = _opts.maxLineCount ?? 0;
  final takenNo = params.takenNo + 1;
  final canStop = ((maxLineCount > 0) && (takenNo >= maxLineCount));

  final buffer = '${params.current!}${UtfConst.lineBreak}';
  (params.extra as OutInfo).writeUtfChunkSync(buffer);

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
  final outInfo = OutInfo(outFile.path, outFile.openWrite(), type: toType);

  if (maxLineCount == null) {
    if (isSync) {
      inpFile.readUtfAsStringSync(onUtfIo: convChunkSync, extra: outInfo);
    } else {
      await inpFile.readUtfAsString(onUtfIo: convChunk, extra: outInfo);
    }
  } else {
    if (isSync) {
      inpFile.readUtfAsLinesSync(onLine: convLineSync, extra: outInfo);
    } else {
      await inpFile.readUtfAsLines(onLine: convLine, extra: outInfo);
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
      stdin.readUtfAsStringSync(onUtfIo: convChunkSync, extra: outInfo);
    } else {
      await stdin.readUtfAsString(onUtfIo: convChunk, extra: outInfo);
    }
  } else {
    if (isSync) {
      stdin.readAsLinesSync(onLine: convLineSync, extra: outInfo);
    } else {
      await stdin.readAsLines(onLine: convLine, extra: outInfo);
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

-?, -h[elp]    - this help screen
-l[ine] MAXNUM - convert line by line (default: convert chunks of text),
                 limit to MAXNUM (0 = no limit)
-s[ync]        - convert synchronously
-t[o] TYPE     - convert the input into the output of the given type (default: utf8 without BOM)
                 supported TYPEs: utf8 (with BOM or not), utf16le, utf16be, utf32le, utf32be

ARGUMENTS:

Path(s) or name(s) of file(s) to print
If none specified, print the content of ${UtfStdin.name} to ${UtfStdout.name})
''');

  exit(1);
}
