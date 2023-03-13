import 'dart:collection';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

//=================================================//

typedef Parser<T> = T Function(String);

//=================================================//

///
///
///
class Cache<T> {
  Cache._(this._cache, this._path);
  
  final Set<T> _cache;
  final String _path;

  //---------------------------------------//

  ///
  static Future<Cache<T>> load<T>(String fileName, Parser<T> parser) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final path = '${dir.path}/$fileName';
      final file = File(path);
      final cache = SplayTreeSet<T>();
      if (file.existsSync()) {
        final lines = await file.readAsLines();
        cache.addAll(lines.map(parser));
      }
      return Cache._(cache, path);
    }
    catch (_) {
      rethrow;
    }
  }

  //---------------------------------------//

  ///
  void _save() {
    try {
      File(_path).writeAsString(_cache.map((e) => e.toString()).join('\n'));
    }
    catch (_) {
      rethrow;
    }
  }

  //---------------------------------------//

  ///
  List<T> get content => _cache.cast<T>().toList();

  ///
  bool contains(T item) => _cache.contains(item);

  ///
  int get length => _cache.length;

  ///
  T get first => _cache.first;

  ///
  T get last => _cache.first;

  ///
  bool add(T item) {
    if (_cache.add(item)) {
      _save();
      return true;
    }
    return false;
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