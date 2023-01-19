// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

import 'package:utf_ext/utf_ext.dart';

/// Base UTF exception (optional)
///
class UtfException implements Exception {
  /// Const: length of a tail preceding the error character
  ///
  static const tailLength = 16;

  /// Default explanation
  ///
  String get description => getDescription();

  /// Identifier of the entity which threw the exception (can be file path)
  ///
  late final String callerId;

  /// Ending of successfully converted text
  ///
  final String? goodEnding;

  /// Length of successfully converted text
  ///
  final int goodLength;

  /// Type of UTF
  ///
  late final UtfType type;

  /// Explanation prefix
  ///
  String get prefix => 'Malformed ${type.toString()}';

  UtfException(
      String? callerId, UtfType? type, this.goodEnding, this.goodLength) {
    callerId = callerId?.trim() ?? '';
    this.callerId = (callerId.isEmpty ? '' : ' in $callerId');
    this.type = type ?? UtfType.utf8;
  }

  /// Take the last minimum piece of successfully converted text
  ///
  static String getEnding({String? text, int? maxTailLength}) {
    final end = text?.length ?? 0;

    if (end <= 0) {
      return '';
    }

    var start = end - (maxTailLength ?? UtfException.tailLength);
    start = (start < 0 ? 0 : start);

    return text!.substring(start, end);
  }

  /// Actual description
  ///
  String getDescription() {
    var ending = UtfException.getEnding(text: goodEnding);

    if (ending.isEmpty) {
      return '$prefix in the beginning';
    }

    return '$prefix at offset $goodLength after the text: $ending';
  }

  /// Serializer
  ///
  @override
  String toString() => 'Error$callerId: $description';
}
