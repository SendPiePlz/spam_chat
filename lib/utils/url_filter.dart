import 'package:spam_chat/models/cache.dart';
import 'package:spam_chat/models/dictionary.dart';
import 'package:spam_chat/models/multinomial_nb.dart';

//=================================================//

part 'url_vocabulary.dart';

//=================================================//

///
///
///
class UrlFilter {
  const UrlFilter();

  //---------------------------------------//

  static final _filter = MultinomialNB(vocabulary, (s) => [s]);
  static final StringCache _cache = StringCache.load(r'urls.txt');
  
  static final RegExp urlPattern = RegExp(r'(https?:\/\/)?(([^/\s]+\.)+[^/\s]+)(\/\S*)?');
  static final RegExp _escChars = RegExp(r'@|\/\/');

  static const Set<String> _baseTrustedDomains = {
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
  void trustAllUrl(List<String> urls) => urls.forEach(trustUrl);

  void untrustUrls(Iterable<String> urls) => _cache.removeAll(urls);
  void untrustUrl(String url) => _cache.remove(url);
  void untrustAll() => _cache.clear();

  ///
  bool isUrl(String url) => urlPattern.firstMatch(url) != null;

  ///
  bool isSsh(String url) => url.startsWith('https://');

  ///
  String? _extractDomain(String url) {
    final match = urlPattern.firstMatch(url);
    if (match != null) {
      return match.group(2);
    }
    return null;
  }

  ///
  bool isTrusted(String url) {
    final match = urlPattern.firstMatch(url);
    if (match != null) {
      final domain = match.group(2)!.replaceFirst('www.', '');
      final known = _cache.contains(domain) ||
                    _baseTrustedDomains.contains(domain);
      if (match.group(3) != null) {
        return known && !match.group(3)!.contains(_escChars);
      }
      return known;
    }
    return _filter.predict(url);
  }

  ///
  bool isNotTrusted(String url) => !isTrusted(url);
}