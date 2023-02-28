// Copyright (c) 2023, Alexander Iurovetski
// All rights reserved under MIT license (see LICENSE file)

/// Extension for Iterable with some helper methods
///
extension IterableExt<T> on Iterable<T> {
  /// Returns true if [this] starts with [that]
  ///
  bool startsWith(Iterable<T> that) {
    final thatLength = that.length;

    if ((thatLength <= 0) || (thatLength > length)) {
      return false;
    }

    final thisIter = iterator;
    final thatIter = that.iterator;

    for (var i = 0; i < thatLength; i++) {
      thisIter.moveNext();
      thatIter.moveNext();

      if (thisIter.current != thatIter.current) {
        return false;
      }
    }

    return true;
  }
}
