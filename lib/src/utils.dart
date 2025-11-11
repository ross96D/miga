import "dart:convert";
import "dart:typed_data";

Iterable<(L, R)> zip2<L, R>((Iterable<L>, Iterable<R>) iterables) {
  return _zip2(iterables);
}

Iterable<(L, R)> _zip2<L, R>((Iterable<L>, Iterable<R>) iterables) sync* {
  final iterators = (iterables.$1.iterator, iterables.$2.iterator);
  while ([iterators.$1, iterators.$2].every((e) => e.moveNext())) {
    yield (iterators.$1.current, iterators.$2.current);
  }
}

extension Zip2<L extends Object> on Iterable<L> {
  Iterable<(L, R)> zip2<R>(Iterable<R> iterable) {
    return _zip2((this, iterable));
  }

  /// Does not throw if iterator has no elements, instead returns [defaultValue]
  L? reduceSafe(L Function(L value, L element) combine, [L? defaultValue]) {
    Iterator<L> iterator = this.iterator;
    if (!iterator.moveNext()) {
      return defaultValue;
    }
    L value = iterator.current;
    while (iterator.moveNext()) {
      value = combine(value, iterator.current);
    }
    return value;
  }

  Peekable<L> peekable() {
    return Peekable(this.iterator);
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

bool isCharBoundary(Uint8List text, int index) {
  if (index == 0) return true;

  if (index >= text.length) {
    return index == text.length;
  }
  final byte = text[index];

  /// taked from https://github.com/rust-lang/rust/blob/a7b3715826827677ca8769eb88dc8052f43e734b/library/core/src/num/mod.rs#L1078
  return byte < 128 || byte >= 192;
}

class Peekable<T extends Object> extends Iterable<T> {
  final Iterator<T> inner;
  Peekable(this.inner);

  @override
  PeekableIterator<T> get iterator => PeekableIterator(inner);
}

class PeekableIterator<T extends Object>  implements Iterator<T> {
  Iterator<T> inner;

  T? _current;
  T? _peek;

  bool hasPeek() {
    return _hasNext;
  }

  T get peek => _peek!;

  bool _hasNext;

  bool get isLast => !_hasNext;

  PeekableIterator(this.inner): _hasNext = false {
    _hasNext = inner.moveNext();
    if (_hasNext) {
      _peek = inner.current;
    }
  }

  @override
  T get current => _current!;

  @override
  bool moveNext() {
    if (_hasNext) {
      _hasNext = inner.moveNext();
      _current = _peek;
      if (_hasNext) {
        _peek = inner.current;
      }
      return true;
    } else {
      return false;
    }
  }
}
