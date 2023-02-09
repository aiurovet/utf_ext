extension IterableExt<T> on Iterable<T> {
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