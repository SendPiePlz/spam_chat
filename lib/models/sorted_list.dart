
///
///
///
class ListSet<T extends Comparable<T>> implements Set<T> {
  const ListSet._(this._items);
  const factory ListSet.from(List<T> items) = ListSet._;

  final List<T> _items;

  ///
  T? operator [](T key) {
    final i = _indexOf(key);
    if (i != null) {
      return _items[i];
    }
    return null;
  }

  ///
  @override
  bool add(T key) {
    final i = _indexOf(key, true)!;
    if (_items[i] == key) {
      return false;
    }
    _items.insert(i, key);
    return true;
  }

  ///
  int? _indexOf(T key, [bool returnIndex = false]) {
    var low = 0;
    var high = _items.length-1;
    while (low <= high) {
      final mid = low + (high - low) ~/ 2;
      final comp = key.compareTo(_items[mid]);
      if (comp < 0) {
        high = mid-1;
      }
      else if (comp > 0) {
        low = mid+1;
      }
      else {
        return mid;
      }
    }
    return (returnIndex) ? low : null;
  }

  @override
  void addAll(Iterable<T> elements) {
    for (final e in elements) {
      add(e);
    }
  }

  @override
  bool any(bool Function(T element) test) => _items.any(test);

  @override
  Set<R> cast<R>() => toSet().cast<R>();

  @override
  void clear() => _items.clear();

  @override
  bool contains(Object? value) => value != null && _indexOf(value as T) != null;

  @override
  bool containsAll(Iterable<Object?> other) {
    for (final o in other.cast<T?>()) {
      if (o == null || _indexOf(o) == null) {
        return false;
      }
    }
    return true;
  }

  @override
  Set<T> difference(Set<Object?> other) {
    // TODO: implement difference
    throw UnimplementedError();
  }

  @override
  T elementAt(int index) => _items[index];

  @override
  bool every(bool Function(T element) test) => _items.every(test);

  @override
  Iterable<U> expand<U>(Iterable<U> Function(T element) toElements) => _items.expand(toElements);

  @override
  T get first => _items.first;

  @override
  T firstWhere(bool Function(T element) test, {T Function()? orElse}) => _items.firstWhere(test, orElse: orElse);

  @override
  U fold<U>(U initialValue, U Function(U previousValue, T element) combine) => _items.fold(initialValue, combine);

  @override
  Iterable<T> followedBy(Iterable<T> other) => _items.followedBy(other);

  @override
  void forEach(void Function(T element) action) => _items.forEach(action);

  @override
  Set<T> intersection(Set<Object?> other) {
    final result = <T>{};
    for (final o in other.cast<T?>()) {
      if (o != null && _indexOf(o) != null) {
        result.add(o);
      }
    }
    return result;
  }

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  bool get isNotEmpty => _items.isNotEmpty;

  @override
  Iterator<T> get iterator => _items.iterator;

  @override
  String join([String separator = ""]) => _items.join(separator);

  @override
  T get last => _items.last;

  @override
  T lastWhere(bool Function(T element) test, {T Function()? orElse}) => _items.lastWhere(test, orElse: orElse);

  @override
  int get length => _items.length;

  @override
  T? lookup(Object? object) {
    // TODO: implement lookup
    throw UnimplementedError();
  }

  @override
  Iterable<U> map<U>(U Function(T e) toElement) => _items.map(toElement);

  @override
  T reduce(T Function(T value, T element) combine) => _items.reduce(combine);

  @override
  bool remove(Object? value) {
    
  }

  @override
  void removeAll(Iterable<Object?> elements) => _items.remove

  @override
  void removeWhere(bool Function(T element) test) => _items.removeWhere(test);

  @override
  void retainAll(Iterable<Object?> elements) {
    // TODO: implement retainAll
  }

  @override
  void retainWhere(bool Function(T element) test) => _items.retainWhere(test);

  @override
  T get single => _items.single;

  @override
  T singleWhere(bool Function(T element) test, {T Function()? orElse}) => _items.singleWhere(test, orElse: orElse);

  @override
  Iterable<T> skip(int count) => _items.skip(count);

  @override
  Iterable<T> skipWhile(bool Function(T value) test) => _items.skipWhile(test);

  @override
  Iterable<T> take(int count) => _items.take(count);

  @override
  Iterable<T> takeWhile(bool Function(T value) test) => _items.takeWhile(test);

  @override
  List<T> toList({bool growable = true}) => _items.toList(growable: growable);

  @override
  Set<T> toSet() => _items.toSet();

  @override
  Set<T> union(Set<T> other) => toSet().union(other);

  @override
  Iterable<T> where(bool Function(T element) test) => _items.where(test);

  @override
  Iterable<U> whereType<U>() => _items.whereType<U>();
}