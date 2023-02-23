import 'package:flutter/material.dart';
import 'package:spam_chat/models/cache.dart';
import 'package:spam_chat/models/counter.dart';
//import 'package:spam_chat/models/dictionary.dart';
import 'package:spam_chat/models/transformer.dart';
//import 'package:spam_chat/models/vector_classifier.dart';
import 'package:spam_chat/utils/extensions.dart';
import 'package:spam_chat/utils/url_decision_tree.dart';

//=================================================//

//part 'url_vocabulary.dart';

//=================================================//

///
///
///
class UrlFilter {
  UrlFilter();

  //---------------------------------------//

  //const _filter = VectorClassifier<String>(logLikelihoods, UrlTransformer());
  final _filter = UrlDecisionTree(const UrlTransformer());
  final _cache = StringCache.load(r'urls.txt');
  
  static final _urlPattern = RegExp(r'(https?:\/\/)?((([^/\s.]+\.)+[^/\s.]+)(\/\S*)?)');
  static final _escChars = RegExp(r'@|\/\/');

  static const _baseTrustedDomains = <String>{
    'amazon.com',
    'apple.com',
    'bing.com',
    //'docs.google.com', // 
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
      return match.group(2);
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
      final isBad = !ttd || _filter.predict(url);
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

  String get urlWithoutProtocol {
    if (url.startsWith(_proto)) {
      return url.replaceFirst(_proto, '');
    }
    return url;
  }
}

//=================================================//

///
class UrlTransformer implements Transformer<double, String> {
  const UrlTransformer();

  static const _TOKEN_NUM   = 1;
  static const _TOKEN_JUNK  = 2;
  static const _TOKEN_OTHER = 3;
  static const _TOKEN_LWORD = 4;
  static const _TOKEN_WORD  = 5;

  static final _ip = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(:\d{1,5})?$');
  //static final _proto = RegExp(r'https?:\/\/');
  static final _split = RegExp(r'[^\w\d]');

  static final _tokenCt = Counter<int>();
  static final _specCt = Counter<String>.withFilter([':','.','@','/','%','?']);

  @override
  List<double> transform(String url) {
    //if (url.startsWith(_proto)) {
    //  url = url.replaceFirst(_proto, '');
    //}
    final ap = _splitAddressPath(url);

    _tokenCt.clear();
    _tokenCt.pushAll(ap[0].split(_split).map(_categorize));
    _specCt.clear();
    _specCt.pushAll(url.characters);

    //['%','.','/','//',':','?','@',ip,lenA,lenP,jnk,lword,num,other,word]
    return [
      _specCt['%'].toDouble(),
      _specCt['.'].toDouble(),
      _specCt['/'].toDouble(),
      ap[1].contains('//') ? 1 : 0,
      _specCt[':'].toDouble(),
      _specCt['?'].toDouble(),
      _specCt['@'].toDouble(),
      _ip.hasMatch(ap[0]) ? 1 : 0,
      ap[0].length.toDouble(),
      ap[1].length.toDouble(),
      _tokenCt[_TOKEN_JUNK].toDouble(),
      _tokenCt[_TOKEN_LWORD].toDouble(),
      _tokenCt[_TOKEN_NUM].toDouble(),
      _tokenCt[_TOKEN_OTHER].toDouble(),
      _tokenCt[_TOKEN_WORD].toDouble(),
    ];
  }

  //---------------------------------------//

  ///
  List<String> _splitAddressPath(String url) {
    var i = 0;
    while (i < url.length && url[i] != '/') { ++i; }
    if (i == url.length) {
      return [url, ''];
    }
    return [url.substring(0, i), url.substring(i)];
  }

  ///
  int _categorize(String token) {
    if (token.isdigit()) {
      return _TOKEN_NUM;
    }
    if (!token.isalpha()) {
      return _TOKEN_OTHER;
    }
    if (token.length > 4 && !token.isReadable()) {
      return _TOKEN_JUNK;
    }
    if (token.length > 15) {
      return _TOKEN_LWORD;
    }
    return _TOKEN_WORD;
  }
}