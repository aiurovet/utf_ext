// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:utf_ext/utf_ext.dart';

/// Simple configuration
///
class UtfConfig {
  /// How to treat files or streams without BOM (for reading)
  ///
  static var fallbackForRead = UtfType.utf8;

  /// How to treat files or streams without BOM (for writing)
  ///
  static var fallbackForWrite = UtfType.utf8;

  /// Maximum size of a buffer for synchronous (blocking) operations\
  /// Can be set in `main()`
  ///
  static var maxBufferLength = 16 * 1024;
}
