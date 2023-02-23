import 'dart:collection';

//=================================================//

///
///
///
class Counter<K> {
  Counter()
    : _items = SplayTreeMap()
    , _filtered = false;

  Counter.withFilter(Iterable<K> keys)
    : _items = SplayTreeMap.fromIterables(keys, List.filled(keys.length, 0))
    , _filtered = true;

  final Map<K, int> _items;
  final bool _filtered;

  ///
  void clear() => _items.clear();

  ///
  int operator [](K key) {
    final v = _items[key];
    return (v == null) ? 0 : v;
  }

  ///
  void push(K key) {
    final v = _items[key];
    if (v == null && !_filtered) {
      _items[key] = 1;
    }
    else if (v != null) {
      _items[key] = v + 1; 
    }
  }

  ///
  void pushAll(Iterable<K> keys) => keys.forEach(push);

  ///
  Iterable<int> get counts => _items.values;
  
  ///
  Iterable<K> get keys => _items.keys;
}