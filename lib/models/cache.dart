import 'dart:collection';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

//=================================================//

typedef InParser<T> = T Function(String);
typedef OutParser<T> = String Function(T);

//=================================================//

///
///
///
class Cache<T> {
  
  final Set<T> _cache = SplayTreeSet();
  final OutParser<T> _outParser;
  late String _path;

  //---------------------------------------//

  ///
  Cache.load(String fileName, InParser<T> inParser, this._outParser) {
    try {
      getApplicationSupportDirectory().then((dir) {
        _path = '${dir.path}/$fileName';
        final file = File(_path);
        if (file.existsSync()) {
          file.readAsLines().then(
            (ls) => _cache.addAll(ls.map(inParser))
          );
        }
      },
      onError: (e, s) {
        throw Exception(e);
      });
    }
    catch (_) {
      rethrow;
    }
  }

  //---------------------------------------//

  ///
  Future<void> _save() async {
    try {
      File(_path).writeAsString(_cache.map(_outParser).join('\n'));
    }
    catch (_) {
      rethrow;
    }
  }

  //---------------------------------------//

  ///
  List<T> get content => _cache.cast<T>().toList(growable: false);

  ///
  bool contains(T item) => _cache.contains(item);

  ///
  void add(T item) {
    if (_cache.add(item)) {
      _save();
    }
  }

  ///
  void addAll(Iterable<T> items) {
    final pal = _cache.length;
    _cache.addAll(items);
    if (_cache.length != pal) {
      _save();
    }
  }

  ///
  void clear() {
    _cache.clear();
    _save();
  }

  ///
  void remove(T item) {
    _cache.remove(item);
    _save();
  }

  ///
  void removeAll(Iterable<T> items) {
    _cache.removeAll(items);
    _save();
  }

}

//=================================================//

///
/// Wrapper class around to [Cache] class.
///
class StringCache extends Cache<String> {
  StringCache.loadWithParsers(String fileName, InParser<String> inParser, OutParser<String> outParser) : super.load(fileName, inParser, outParser);

  factory StringCache.load(String fileName) => StringCache.loadWithParsers(fileName, (s) => s, (s) => s);
}