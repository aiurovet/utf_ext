## 0.3.1

- Upgraded packages

## 0.3.0

- Breaking: ditched FutureOr

## 0.2.3

- Website changed

## 0.2.2

- Ensuring onWrite is able to modify lines and chunks
- Minor bugfix for the use of onRead

## 0.2.1

- Fixed sample code

## 0.2.0

- Allowed to modify content in read and write handlers
- Renamed `maxBufferLength` to `bufferLength` in `UtfConfig`
- Added option `-b,-buf,-bufsize` for a buffer limit to `utf_cat` and `utf_conv` examples

## 0.1.9

- Fixing the pub.dev recognition of examples

## 0.1.8

- Updated documentation and upgraded packages

## 0.1.7

- Upgraded `file_ext` to version `0.5.0`

## 0.1.6

- Rename: `readAsLines*` to `readUtfAsLines*` for `UtfStdin`

## 0.1.5

- Rename: `addPendingLineBreak` to `lineBreakAtEnd`
- Bugfix: `printUtf*` of `UtfStdio` should add line break at the end

## 0.1.4

- Upgraded file_ext to 0.4.0 (dev dependency)

## 0.1.3

- Correction to examples

## 0.1.2

- Removed prefix `example_` from sample Dart files and added README.md to make examples recognisable
- Added flag `addPendingLineBreak` to manage the output ending
- Breaking: all read methods return int (the number of lines or characters read ex BOM)

## 0.1.1

- Renamed sample files to contain prefix `example_`

## 0.1.0

- Initial version.
