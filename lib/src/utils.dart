import "dart:convert";

Iterable<(L, R)> zip2<L, R>((Iterable<L>, Iterable<R>) iterables) {
  return _zip2(iterables);
}

Iterable<(L, R)> _zip2<L, R>((Iterable<L>, Iterable<R>) iterables) sync* {
  final iterators = (iterables.$1.iterator, iterables.$2.iterator);
  while ([iterators.$1, iterators.$2].every((e) => e.moveNext())) {
    yield (iterators.$1.current, iterators.$2.current);
  }
}

extension Zip2<L> on Iterable<L> {
  Iterable<(L, R)> zip2<R>(Iterable<R> iterable) {
    return _zip2((this, iterable));
  }
}

extension Cyle<T> on List<T> {
  Iterable<T> cycle() sync* {
    while (true) {
      for (final e in this) {
        yield e;
      }
    }
  }
}

extension Utf8ByteLength on int {
  int utf8ByteLength() {
    if (this < 128) return 1;
    final list = utf8.encode(String.fromCharCode(this));
    return list.length;
  }
}
