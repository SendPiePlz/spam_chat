import 'dart:typed_data';

//=================================================//

///
///
///
class Region {
  const Region(this.start, this.end)
    : assert(start <= end)
    , assert(start >= 0)
    , assert(end >= 0);

  final int start;
  final int end;
}

//=================================================//

///
///
///
class DictEntry {
  const DictEntry(this.key, this.x, this.y);

  final String key;
  final double x;
  final double y;

  Float64x2 get values => Float64x2(x, y);
}

//=================================================//

///
///
///
class Dictionary {
  const Dictionary(this._regions, this._items);

  final Map<String, Region> _regions;
  final List<DictEntry> _items;

  // Binary search over a [Region] for a specific [DictEntry].
  Float64x2? operator [](String key) {
    final r = _regions[key[0]];
    if (r != null) {
      assert(r.start < _items.length);
      assert(r.end < _items.length);
      var low  = r.start;
      var high = r.end;
      while (low <= high) {
        final mid = low + (high - low) ~/ 2;
        final cmp = key.compareTo(_items[mid].key);
        if (cmp < 0) {
          high = mid-1;
        }
        else if (cmp > 0) {
          low = mid+1;
        }
        else { // found value
          return _items[mid].values;
        }
      }
      //final item = _items[low];
      //return (item.key == key) ? item.values : null;
    }
    return null;
  }
}