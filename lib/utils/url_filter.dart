import 'package:flutter/material.dart';
import 'package:spam_chat/ai/transformer.dart';
import 'package:spam_chat/ai/url_decision_tree.dart';
import 'package:spam_chat/models/cache.dart';
import 'package:spam_chat/models/counter.dart';
import 'package:spam_chat/utils/extensions.dart';


//=================================================//

///
///
///
class UrlFilter {
  late final UrlDecisionTree _filter;
  late final Cache<String> _cache;

  //---------------------------------------//

  UrlFilter() {
    _filter = UrlDecisionTree(UrlTransformer());
    _initCache();
  }

  ///
  Future<void> _initCache() async {
    _cache = await Cache.load<String>(r'urls.txt', (s) => s);
  }

  //---------------------------------------//
  
  static final _urlPattern = RegExp(r'(https?:\/\/)?((([^/\s.]+\.)+[^/\s.]+)(\/\S*)?\b)');
  static final _escChars = RegExp(r'@|\/\/');

  static const _baseTrustedDomains = <String>{
    'amazon.com',
    'apple.com',
    'bing.com',
    //'docs.google.com',
    'duckduckgo.com',
    'facebook.com',
    'github.com',
    'gitlab.com',
    'google.com',
    'instagram.com',
    'linkedin.com',
    'mail.google.com',
    'maps.google.com',
    'microsoft.com',
    'open.spotify.com',
    'outlook.com',
    'outlook.live.com',
    'pinterest.com',
    'reddit.com',
    'scholar.google.com',
    'spotify.com',
    'tiktok.com',
    'translate.google.com',
    'twitter.com',
    'youtube.com',
  };

  //---------------------------------------//

  ///
  List<String> get trustedUrls => _cache.content;

  ///
  void trustUrl(String url) {
    final domain = _extractDomain(url);
    if (domain != null) {
      _cache.add(domain.replaceFirst('www.', ''));
    }
  }

  ///
  void trustAllUrl(Iterable<String> urls) => urls.forEach(trustUrl);

  void untrustUrls(Iterable<String> urls) => _cache.removeAll(urls);
  void untrustUrl(String url) => _cache.remove(url);
  void untrustAll() => _cache.clear();

  ///
  bool isSsh(String url) => url.startsWith('https://');

  ///
  String? _extractDomain(String url) {
    final match = _urlPattern.firstMatch(url);
    if (match != null) {
      return match[3];
    }
    return null;
  }

  ///
  bool _isTrusted(String address, String path) {
    final addr = address.replaceFirst('www.', '');
    final known = _cache.contains(addr) ||
                  _baseTrustedDomains.contains(addr);
    if (known) {
      return !path.contains(_escChars);
    }
    return false;
  }

  ///
  Iterable<UrlMatch> extractUrls(String msg) {
    final ms = _urlPattern.allMatches(msg);
    return ms.map((m) {
      final url   = m[2]!;
      final addr  = m[3]!;
      final path  = m[5] ?? '';
      final ttd = _isTrusted(addr, path);
      final isBad = (ttd) ? false : _filter.predict(url);
      //debugPrint('$url => ${_filter.predict(url)}');
      return UrlMatch(m[0]!, isBad, ttd, m.start, m.end);
    });
  }
}

//=================================================//

///
///
///
class UrlMatch {
  const UrlMatch(this.url, this.isBad, this.isTrusted, this.start, this.end);

  final String url;
  final bool isBad;
  final bool isTrusted;
  final int start;
  final int end;

  static final _proto = RegExp(r'https?:\/\/');

  ///
  List<String> get components {
    final wh = urlWithoutProtocol;
    var i = 0;
    while (i < wh.length && wh[i] != '/') { ++i; }
    if (i == wh.length) {
      return [wh, ''];
    }
    return [wh.substring(0, i), wh.substring(i)];
  }

  ///
  String get urlWithoutProtocol {
    if (url.startsWith(_proto)) {
      return url.replaceFirst(_proto, '');
    }
    return url;
  }
}

//=================================================//

///
class UrlTransformer implements Transformer<int, String> {
  UrlTransformer();

  static const _TOKEN_NUM   = 1;
  static const _TOKEN_JUNK  = 2;
  static const _TOKEN_OTHER = 3;
  static const _TOKEN_LONG  = 4;
  static const _TOKEN_WORD  = 5;
  static const _TOKEN_SMALL = 6;

  static final _ip = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d{1,5})?$');
  static final _split = RegExp(r'\W|[_\-]');

  final _tokenCnt = Counter<int>();
  final _specCnt  = Counter<String>.withFilter(['%','.','/',':','?','@']);

  @override
  List<int> transform(String url) {
    // NOTE: assumes the scheme has been removed
    _tokenCnt.clear();
    _tokenCnt.pushAll(url.split(_split).where((t) => t.isNotEmpty).map(categorize));
    _specCnt.clear();
    _specCnt.pushAll(url.characters);

    final ps = getPathStart(url);
    
    //['%','.','/','//',':','?','@',ip,lenA,lenP,jnk,long,num,other,small,word]
    return [
      _specCnt['%'],
      _specCnt['.'],
      _specCnt['/'], // TODO: do not count trailing
      url.contains('//') ? 1 : 0,
      _specCnt[':'],
      _specCnt['?'],
      _specCnt['@'],
      _ip.hasMatch(url.substring(0, ps)) ? 1 : 0,
      ps,
      url.length - ps,
      _tokenCnt[_TOKEN_JUNK],
      _tokenCnt[_TOKEN_LONG],
      _tokenCnt[_TOKEN_NUM],
      _tokenCnt[_TOKEN_OTHER],
      _tokenCnt[_TOKEN_SMALL],
      _tokenCnt[_TOKEN_WORD],
    ];
  }

  //---------------------------------------//

  ///
  int getPathStart(String url) {
    var i = 0;
    while (i < url.length && url[i] != '/') { ++i; }
    return i;
  }

  ///
  int categorize(String token) {
    if (token.isdigit()) {
      return _TOKEN_NUM;
    }
    if (!token.isalpha()) {
      return _TOKEN_OTHER;
    }
    if (token.length < 4) {
      return _TOKEN_SMALL;
    }
    if (!token.isReadable()) {
      return _TOKEN_JUNK;
    }
    if (token.length > 15) {
      return _TOKEN_LONG;
    }
    return _TOKEN_WORD;
  }
}