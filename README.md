A library for reading / writing text files in any major Unicode format (UTF-8, UTF-16LE, UTF-16BE, UTF-32LE, UTF-32BE).

## Features

- Asynchronous extension methods to read from and write to UTF streams including as the whole buffer of text or as a list of lines.
- Similar asynchronous and synchronous methods to read from and write to UTF files as well as from _stdin_ and to _stdout_.
- Ability to specify a callback (closure) acting on every chunk of text or a line of text being read or written. This allows to avoid loading the whole content of a large file into memory before starting any processing. It also allows to avoid format conversions of large block of data after reading or before writing the result.

## Usage

The same can be found in `example/utf_cat.dart`

```dart
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
  static const appName = 'utf_cat';

  /// Const: application version
  ///
  static const appVersion = '1.0.0';

  /// Option flag: read file line by line synchronously
  ///
  var isSynch = false;

  /// Read file or stdin line by line when value != null,
  /// and limit to the number of lines when value > 0
  ///
  int? maxLineCount;

  final paths = <String>[];

  /// Simple command-line parser using `parse_args` package
  ///
  void parse(List<String> args) {
    var optDefs = '''
      |?,h,help|q,quiet|v,verbose|l,line:?|s,sync,synch|::?
    ''';

    var o = parseArgs(optDefs, args);

    _logger.levelFromFlags(isQuiet: o.isSet('q'), isVerbose: o.isSet('v'));

    if (o.isSet('?')) {
      usage();
    }

    maxLineCount = o.getIntValue('l');
    isSynch = o.isSet('s');

    paths.addAll(o.getStrValues(''));
    paths.removeWhere((x) => x.trim().isEmpty);
  }
}

/// Print byte order mark
///
void catBom(UtfType type, bool isWrite) {
  print('Byte Order Mark: $type');
}

/// Print any chunk of text
///
VisitResult catChunk(UtfIoParams params) {
  stdout.write(params.current);

  return VisitResult.take;
}

/// Print any text (a block or a line)
///
VisitResult catLine(UtfIoParams params) {
  print(params.current);

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
    if (_opts.isSynch) {
      file.readUtfAsStringSync(onBom: catBom, onRead: catChunk);
    } else {
      await file.readUtfAsString(onBom: catBom, onRead: catChunk);
    }
  } else {
    if (_opts.isSynch) {
      file.readUtfAsLinesSync(onBom: catBom, onRead: catLine);
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
    if (_opts.isSynch) {
      stdin.readUtfAsStringSync(onBom: catBom, onRead: catChunk);
    } else {
      await stdin.readUtfAsString(onBom: catBom, onRead: catChunk);
    }
  } else {
    if (_opts.isSynch) {
      stdin.readAsLinesSync(onBom: catBom, onRead: catLine);
    } else {
      await stdin.readAsLines(onBom: catBom, onRead: catLine);
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

-?, -h[elp]    - this help screen
-l[ine] MAXNUM - cat line by line (default: cat chunks of text),
                 limit to MAXNUM (use 0 for no limit)
-s[ync[h]]     - cat synchronously

ARGUMENTS:

Path(s) or name(s) of file(s) to print (if none then print the content of ${UtfStdin.name})
''');

  exit(1);
}
```
