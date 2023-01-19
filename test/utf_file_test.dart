import 'package:file_ext/file_ext.dart';

/// A suite of tests for UtfBom
///
void main() {
  MemoryFileSystemExt.forEach((fs) {
    // final topName = fs.path.absolute('a');
    // final dirName = fs.path.join(topName, 'b');
    // final file = fs.file(fs.path.join(dirName, 'c.txt'));
    // final styleName = fs.getStyleName();

    // group('Read BOM - $styleName -', () {
    //   setUp(() async {
    //     await file.create(recursive: true);
    //   });
    //   test('empty', () async {
    //     await file.writeAsBytes([0xEF, 0xBB, 0xBF, 0x41, 0x42]);
    //     expect(await file.readBom(), UtfType.utf8);
    //   });
    //   test('too short', () async {
    //     await file.writeAsBytes([0xFE]);
    //     expect(await file.readBom(), null);
    //   });
    //   test('no BOM', () async {
    //     await file.writeAsBytes([0x41, 0x42, 0x43, 0x44]);
    //     expect(await file.readBom(), null);
    //   });
    //   test('UTF-8', () async {
    //     await file.writeAsBytes([0xEF, 0xBB, 0xBF, 0x41, 0x42]);
    //     expect(await file.readBom(), UtfType.utf8);
    //   });
    //   test('UTF-16BE', () async {
    //     await file.writeAsBytes([0xFE, 0xFF, 0x41, 0x42]);
    //     expect(await file.readBom(), UtfType.utf16be);
    //   });
    //   test('UTF-16LE', () async {
    //     await file.writeAsBytes([0xFF, 0xFE, 0x41, 0x42]);
    //     expect(await file.readBom(), UtfType.utf16le);
    //   });
    //   test('UTF-32BE', () async {
    //     await file.writeAsBytes([0x00, 0x00, 0xFE, 0xFF, 0x41, 0x42]);
    //     expect(await file.readBom(), UtfType.utf32be);
    //   });
    //   test('UTF-32LE', () async {
    //     await file.writeAsBytes([0xFF, 0xFE, 0x00, 0x00, 0x41, 0x42]);
    //     expect(await file.readBom(), UtfType.utf32le);
    //   });
    // });
  });
}
