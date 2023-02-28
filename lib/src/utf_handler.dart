// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'dart:async';

import 'package:loop_visitor/loop_visitor.dart';
import 'package:utf_ext/utf_ext.dart';

/// Called to read/write the next portion of bytes from/to file or stdin/stdout (blocking)
///
typedef ByteIoHandlerSync = int Function(List<int> bytes,
    [int start, int? end]);

/// Called while reading or writing UTF BOM (non-blocking or blocking)
///
typedef UtfBomHandler = FutureOr<void> Function(UtfType type, bool isWrite);

/// Called while reading or writing UTF BOM (non-blocking or blocking)
///
typedef UtfBomHandlerSync = void Function(UtfType type, bool isWrite);

/// Called while reading UTF (non-blocking or blocking)
///
typedef UtfIoHandler = VisitHandler<String>;

/// Called while reading UTF (blocking)
///
typedef UtfIoHandlerSync = VisitHandlerSync<String>;

/// Type for read parameters
///
typedef UtfIoParams = VisitParams<String>;
