// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:loop_visitor/loop_visitor.dart';

/// Called while reading UTF (non-blocking or blocking)
///
typedef UtfReadHandler = VisitHandler<String>;

/// Called while reading UTF (blocking)
///
typedef UtfReadHandlerSync = VisitHandlerSync<String>;

/// Type for parameters
///
typedef UtfReadParams = VisitParams<String>;
