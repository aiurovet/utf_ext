How To Use the `utf_ext` Package

## Contents

- `utf_cat.dart`  - see how to read UTF files and print to terminal, similar to `cat` (POSIX) or `type` (Windows)
- `utf_conv.dart` - see how to convert files from one UTF format to another, similar to `iconv` (POSIX)

## Sample code

```dart
import 'package:file/file.dart';
...
final data = await filterByPrefixAndToUpperCase('example.md', '-');
...
Future<List<String>> filterByPrefixAndToUpperCase(FileSystem fs, String filePath, String prefix) async {
  final pileup = <String>[];

  await fs.file(filePath).readUtfAsLines(pileup: pileup, onRead: (param) {
    final line = param.current!;

    if (!line.startsWith(prefix)) {
      return VisitResult.skip;
    }

    param.current = line.toUpperCase();

    return VisitResult.take;
  });

  return pileup;
}
```
