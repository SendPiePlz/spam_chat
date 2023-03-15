import 'dart:collection';

//=================================================//

///
///
///
class Counter<K> {
  Counter()
    : _items = HashMap.identity()
    , _filtered = false;

  Counter.withFilter(Iterable<K> keys)
    : _items = HashMap.fromIterables(keys, List.filled(keys.length, 0))
    , _filtered = true;

  final HashMap<K, int> _items;
  final bool _filtered;

  ///
  void clear() {
    if (_filtered) {
      _items.updateAll((_, __) => 0);
    }
    else {
      _items.clear();
    }
  }

  ///
  int operator [](K key) {
    final v = _items[key];
    return (v == null) ? 0 : v;
  }

  ///
  void push(K key) {
    if (_filtered && _items.containsKey(key)) {
      _items.update(key, (v) => ++v);
    }
    else {
      _items.update(key, (v) => ++v, ifAbsent: () => 1);
    }
  }

  ///
  void pushAll(Iterable<K> keys) => keys.forEach(push);

  ///
  Iterable<MapEntry<K, int>> get entries => _items.entries;

  ///
  Iterable<int> get counts => _items.values;
  
  ///
  Iterable<K> get keys => _items.keys;
}