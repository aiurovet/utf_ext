// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';
import 'dart:convert';
import 'package:utf_ext/utf_ext.dart';

/// Helper class to manage text files written in any
/// of the Unicode encodings: UTF-8, UTF-16, UTF-32
///
extension UtfByteStream on Stream<List<int>> {
  /// Open UTF string stream
  ///
  Stream<String> openUtfStringStream(UtfDecoder decoder,
      {bool asLines = false}) {
    final stream = decoder.bind(this);

    return (asLines ? LineSplitter().bind(stream) : stream);
  }
}
