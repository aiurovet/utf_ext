// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

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

/// Command-line options
///
class Options {
  /// Const: application name
  ///
  static const appName = 'utf_cat';

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

  /// Simple command-line parser using `parse_args` package
  ///
  void parse(List<String> args) {
    var optDefs = '''
      |?,h,help|q,quiet|v,verbose|b,buf,bufsize:|l,line:?|s,sync,synch|::?
    ''';

    var o = parseArgs(optDefs, args);

    _logger.levelFromFlags(isQuiet: o.isSet('q'), isVerbose: o.isSet('v'));

    if (o.isSet('?')) {
      usage();
    }

    _setBufferLength(o.getIntValue('b'));

    maxLineCount = o.getIntValue('l');
    isSyncCall = o.isSet('s');

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

/// Print byte order mark
///
void catBom(UtfType type, bool isWrite) {
  final newLine = (_opts.paths.isEmpty ? '\n' : '');
  stdout.write('Byte Order Mark: $type$newLine');
}

/// Print any chunk of text
///
Future<VisitResult> catChunk(UtfIoParams params) async => catChunkSync(params);

/// Print any chunk of text
///
VisitResult catChunkSync(UtfIoParams params) {
  stdout.write(params.current);

  return VisitResult.take;
}

/// Print any text (a block or a line)
///
Future<VisitResult> catLine(UtfIoParams params) async => catLineSync(params);

/// Print any text (a block or a line)
///
VisitResult catLineSync(UtfIoParams params) {
  stdout.writeln(params.current);

  final maxLineCount = _opts.maxLineCount ?? 0;
  final takenNo = params.takenNo + 1;
  final canStop = ((maxLineCount > 0) && (takenNo >= maxLineCount));

  return (canStop ? VisitResult.takeAndStop : VisitResult.take);
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
Future<bool> processFile(String path) async {
  final file = _fs.file(path);

  if (!await file.exists()) {
    _logger.error('File does not exist: "${file.path}"');
    return false;
  }

  if (_opts.maxLineCount == null) {
    if (_opts.isSyncCall) {
      file.readUtfAsStringSync(onBom: catBom, onRead: catChunkSync);
    } else {
      await file.readUtfAsString(onBom: catBom, onRead: catChunk);
    }
  } else {
    if (_opts.isSyncCall) {
      file.readUtfAsLinesSync(onBom: catBom, onRead: catLineSync);
    } else {
      await file.readUtfAsLines(onBom: catBom, onRead: catLine);
    }
  }

  return true;
}

/// Process stdin
///
Future<bool> processStdin() async {
  if (_opts.maxLineCount == null) {
    if (_opts.isSyncCall) {
      stdin.readUtfAsStringSync(onBom: catBom, onRead: catChunkSync);
    } else {
      await stdin.readUtfAsString(onBom: catBom, onRead: catChunk);
    }
  } else {
    if (_opts.isSyncCall) {
      stdin.readUtfAsLinesSync(onBom: catBom, onRead: catLineSync);
    } else {
      await stdin.readUtfAsLines(onBom: catBom, onRead: catLine);
    }
  }

  return true;
}

/// Print help
///
Never usage() {
  _logger.info('''
A tool to print a file or ${UtfStdin.name} content in any major UTF format

USAGE:

${Options.appName} [OPTIONS] [ARGUMENTS]

OPTIONS:

-?, -h[elp]      - this help screen
-b[uf[size]] LEN - set the buffer length
-l[ine]      NUM - convert line by line (default: convert chunks of text),
                   limit to the first NUM lines (0 = no limit)
-s[ync[h]]       - cat synchronously

ARGUMENTS:

Path(s) or name(s) of file(s) to print (if none then print the content of ${UtfStdin.name})
''');

  exit(1);
}
