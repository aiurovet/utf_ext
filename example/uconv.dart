// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

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
  var isSynch = false;

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
      |?,h,help|q,quiet|v,verbose|l,line:?|s,sync,synch|t,to:|::?
    ''';

    var o = parseArgs(optDefs, args);

    _logger.levelFromFlags(isQuiet: o.isSet('q'), isVerbose: o.isSet('v'));

    if (o.isSet('?')) {
      usage();
    }

    maxLineCount = o.getIntValue('l');
    isSynch = o.isSet('s');
    toType = UtfType.parse(o.getStrValue('t'), UtfType.fallbackForWrite);

    paths.addAll(o.getStrValues(''));
    paths.removeWhere((x) => x.trim().isEmpty);
  }
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

/// Print any chunk of text
///
VisitResult convChunk(UtfReadParams params) {
  return VisitResult.take;
}

/// Print any text (a block or a line)
///
VisitResult convLine(UtfReadParams params) {
  final maxLineCount = _opts.maxLineCount ?? 0;
  final takenNo = params.takenNo + 1;
  final canStop = ((maxLineCount > 0) && (takenNo >= maxLineCount));

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
Future<bool> processFile(String path) async {
  final inpFile = _fs.file(path);
  final isSynch = _opts.isSynch;
  final isFound = (isSynch ? inpFile.existsSync() : await inpFile.exists());
  final maxLineCount = _opts.maxLineCount;
  final toType = _opts.toType;

  if (!isFound) {
    _logger.error('File does not exist: "${inpFile.path}"');
    return false;
  }

  final outFile = _fs.file(toOutPath(path));

  if (maxLineCount == null) {
    final pileup = StringBuffer();

    if (isSynch) {
      inpFile.readUtfAsStringSync(onRead: convChunk, pileup: pileup);
      outFile.writeUtfAsStringSync(pileup.toString(), type: toType);
    } else {
      await inpFile.readUtfAsString(onRead: convChunk, pileup: pileup);
      await outFile.writeUtfAsString(pileup.toString(), type: toType);
    }

    pileup.clear();
  } else {
    final pileup = <String>[];

    if (isSynch) {
      inpFile.forEachUtfLineSync(onLine: convLine, pileup: pileup);
      outFile.writeUtfAsLines(pileup, type: toType);
    } else {
      await inpFile.forEachUtfLine(onLine: convLine, pileup: pileup);
      await outFile.writeUtfAsLines(pileup, type: toType);
    }

    pileup.clear();
  }

  return true;
}

/// Process stdin
///
Future<bool> processStdin() async {
  final isSynch = _opts.isSynch;
  final maxLineCount = _opts.maxLineCount;
  final toType = _opts.toType;

  if (maxLineCount == null) {
    final pileup = StringBuffer();

    if (isSynch) {
      stdin.readUtfAsStringSync(onRead: convChunk, pileup: pileup);
      stdout.printUtfAsStringSync(pileup.toString(), type: toType);
    } else {
      await stdin.readUtfAsString(onRead: convChunk, pileup: pileup);
      await stdout.printUtfAsString(pileup.toString(), type: toType);
    }

    pileup.clear();
  } else {
    final pileup = <String>[];

    if (isSynch) {
      stdin.forEachLineSync(onLine: convLine, pileup: pileup);
      stdout.printUtfAsLinesSync(pileup, type: toType);
    } else {
      await stdin.forEachLine(onLine: convLine, pileup: pileup);
      await stdout.printUtfAsLines(pileup, type: toType);
    }

    pileup.clear();
  }

  return true;
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
-s[ync[h]]       - convert synchronously
-t[o] TYPE       - convert the input into the output of the given type (default: utf8 without BOM)

ARGUMENTS:

Path(s) or name(s) of file(s) to print
If none specified, print the content of ${UtfStdin.name} to ${UtfStdout.name})
''');

  exit(1);
}
