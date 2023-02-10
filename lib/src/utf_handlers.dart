// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';

import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Called while reading or writing UTF BOM (non-blocking or blocking)
///
typedef UtfBomHandler = FutureOr<void> Function(UtfType type, bool isWrite);

/// Called while reading or writing UTF BOM (non-blocking or blocking)
///
typedef UtfBomHandlerSync = void Function(UtfType type, bool isWrite);

/// Type for read parameters
///
class UtfReadExtraParams {
  /// Current data
  ///
  String? buffer;

  /// Reference to an arbitrary object
  ///
  dynamic extra;

  /// Reference to an object receiving data from an input incrementally
  ///
  dynamic pileup;

  /// Default constructor
  ///
  UtfReadExtraParams({this.buffer, this.extra, this.pileup});
}

/// Called while reading UTF (non-blocking or blocking)
///
typedef UtfReadHandler = VisitHandler<UtfReadExtraParams>;

/// Called while reading UTF (blocking)
///
typedef UtfReadHandlerSync = VisitHandlerSync<UtfReadExtraParams>;

/// Type for read parameters
///
typedef UtfReadParams = VisitParams<UtfReadExtraParams>;

/// Called while writing UTF (non-blocking or blocking)
///
typedef UtfWriteHandler = VisitHandler<String>;

/// Called while writing UTF (blocking)
///
typedef UtfWriteHandlerSync = VisitHandlerSync<String>;

/// Type for write parameters
///
typedef UtfWriteParams = VisitParams<String>;
