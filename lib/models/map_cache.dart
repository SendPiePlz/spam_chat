import 'dart:io';

import 'package:path_provider/path_provider.dart';

//=================================================//

typedef Parser<T> = T Function(String);

//=================================================//

///
///
///
class MapCache<T> {
  MapCache._(this._cache, this._path);

  final Map<String, T> _cache;
  final String _path;

  //---------------------------------------//

  ///
  static Future<MapCache<T>> load<T>(String fileName, Parser<T> parser) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final path = '${dir.path}/$fileName';
      final file = File(path);
      final cache = <String, T>{};
      if (file.existsSync()) {
        final lines = await file.readAsLines();
        cache.addEntries(lines.map((s) {
          var i = 0;
          while (i < s.length && s[i] != '\t') { ++i; }
          return MapEntry(s.substring(0, i), parser(s.substring(i)));
        }));
      }
      return MapCache<T>._(cache, path);
    }
    catch (_) {
      rethrow;
    }
  }

  //---------------------------------------//

  ///
  void _save() {
    try {
      File(_path).writeAsString(_cache.entries.map((e) => '${e.key}\t${e.value}').join('\n'));
    }
    catch (_) {
      rethrow;
    }
  }

  //---------------------------------------//

  ///
  T? operator [](String key) => _cache[key];

  ///
  void operator []=(String key, T item) {
    if (!key.contains('\t')) _cache[key] = item;
  }

  ///
  bool contains(String key) => _cache.containsKey(key);

  ///
  void update(String key, T Function(T) update) {
    if (contains(key)) {
      _cache.update(key, update);
      _save();
    }
  }

  ///
  void clear() {
    _cache.clear();
    _save();
  }
}