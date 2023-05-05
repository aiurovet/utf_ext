import 'package:file_ext/file_ext.dart';
import 'package:loop_visitor/loop_visitor.dart';
import 'package:test/test.dart';
import 'package:utf_ext/utf_ext.dart';

import 'utf_abc.dart';

/// A suite of tests for UtfFile
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    final topName = fs.path.absolute('a');
    final dirName = fs.path.join(topName, 'b');
    final file = fs.file(fs.path.join(dirName, 'c.txt'));
    final styleName = fs.getStyleName();
    final buffer = StringBuffer();
    final lines = <String>[];

    group('Event handler - $styleName -', () {
      setUp(() async => await UtfAbc.init(file));

      test('onRead - bulk', () async {
        var wasCalled = false;
        await file.readUtfAsString(onReadSync: (params) {
          wasCalled = true;
          return VisitResult.take;
        });
        expect(wasCalled, true);
      });
      test('onRead - bulk - sync', () async {
        var wasCalled = false;
        file.readUtfAsStringSync(onRead: (params) {
          wasCalled = true;
          return VisitResult.take;
        });
        expect(wasCalled, true);
      });
      test('onRead - line', () async {
        var wasCalled = false;
        await file.readUtfAsLines(onReadSync: (params) {
          wasCalled = true;
          return VisitResult.take;
        });
        expect(wasCalled, true);
      });
      test('onRead - line - sync', () async {
        var wasCalled = false;
        file.readUtfAsLinesSync(onRead: (params) {
          wasCalled = true;
          return VisitResult.take;
        });
        expect(wasCalled, true);
      });
      test('onWrite - bulk', () async {
        var wasCalled = false;
        await file.writeUtfAsString('A\nB', onWrite: (params) async {
          wasCalled = true;
          return VisitResult.take;
        });
        expect(wasCalled, true);
      });
      test('onWrite - bulk - sync', () async {
        var wasCalled = false;
        file.writeUtfAsString('A\nB', onWrite: (params) async {
          wasCalled = true;
          return VisitResult.take;
        });
        expect(wasCalled, true);
      });
      test('onWrite - line', () async {
        var wasCalled = false;
        await file.writeUtfAsLines(<String>['A', 'B'], onWrite: (params) async {
          wasCalled = true;
          return VisitResult.take;
        });
        expect(wasCalled, true);
      });
      test('onWrite - line sync', () async {
        var wasCalled = false;
        file.writeUtfAsLinesSync(<String>['A', 'B'], onWrite: (params) {
          wasCalled = true;
          return VisitResult.take;
        });
        expect(wasCalled, true);
      });
    });
    group('Write/Read bulk - $styleName -', () {
      setUp(() async => await UtfAbc.init(file));

      test('for each type', () async {
        await UtfAbc.forEachType(file, (type, file) async {
          await file.writeUtfAsString(UtfAbc.complexStr,
              type: type, lineBreakAtEnd: false);
          await file.readUtfAsString(pileup: buffer);
          expect(buffer.toString(), UtfAbc.complexStr);
        });
      });
    });
    group('Write/Read - bulk - sync - $styleName -', () {
      setUp(() async => await UtfAbc.init(file));

      test('for each type', () {
        UtfAbc.forEachTypeSync(file, (type, file) async {
          file.writeUtfAsStringSync(UtfAbc.complexStr,
              type: type, lineBreakAtEnd: false);
          file.readUtfAsStringSync(pileup: buffer);
          expect(buffer.toString(), UtfAbc.complexStr);
        });
      });
    });
    group('Write/Read line - $styleName -', () {
      setUp(() async => await UtfAbc.init(file));

      test('for each type', () async {
        await UtfAbc.forEachType(file, (type, file) async {
          await file.writeUtfAsLines(<String>['A', 'Bc', 'D', ''], type: type);
          expect((await file.readUtfAsLines(pileup: lines)),
              4 - 1 + UtfConst.lineBreak.length);
        });
      });
    });
    group('Write/Read line - sync - $styleName -', () {
      setUp(() async => await UtfAbc.init(file));

      test('for each type', () {
        UtfAbc.forEachTypeSync(file, (type, file) async {
          file.writeUtfAsLinesSync(<String>['A', 'Bc', 'D', ''],
              type: type, lineBreakAtEnd: false);
          expect((file.readUtfAsLinesSync(pileup: lines)), 4 - 1);
        });
      });
    });
    group('Line breaks - $styleName -', () {
      setUp(() async => await UtfAbc.init(file));

      test('POSIX', () async {
        await file.writeUtfAsString('a\nb\nc',
            type: UtfType.utf8, withPosixLineBreaks: true);
        await file.readUtfAsString(pileup: buffer);
        final data = buffer.toString();
        expect([data.contains('\n'), data.contains('\r')], [true, false]);
      });
      test('Windows', () async {
        await file.writeUtfAsString('a\nb\nc',
            type: UtfType.utf8, withPosixLineBreaks: false);
        await file.readUtfAsString(pileup: buffer, withPosixLineBreaks: false);
        final data = buffer.toString();
        expect([data.contains('\r\n'), RegExp(r'^(|[^\r])\n').hasMatch(data)],
            [true, false]);
      });
    });
  });
}
