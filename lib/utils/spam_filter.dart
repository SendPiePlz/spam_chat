import 'package:spam_chat/models/dictionary.dart';
import 'package:spam_chat/models/transformer.dart';
import 'package:spam_chat/models/string_classifier.dart';
import 'package:spam_chat/utils/extensions.dart';
import 'package:stemmer/PorterStemmer.dart';

//=================================================//

part 'spam_vocabulary.dart';

//=================================================//

///
///
///
class SpamFilter {
  SpamFilter();

  final _filter = StringClassifier(vocabulary, SpamTransofmer());


  // TODO: check for other meta-parameters
  bool isSpam(String msg) => _filter.predict(msg);
  bool isHam(String msg) => !isSpam(msg);
}

//=================================================//

///
class SpamTransofmer implements Transformer<String, String> {
  SpamTransofmer();

  final _stemmer = PorterStemmer();

  static final _split = RegExp(r'\s');
  static final _url = RegExp(r'^(https?:\/\/)?(([^/\s]+\.)+[^/\s]+)(\/\S*)?$');
  static final _num = RegExp(r'^\d+(\.\d+)?\w{0,3}$');

  // Pre-stemmed written numbers
  static const _txtNum = <String>{'zero','one','two','three','four','five','six','seven','eight','nine',
    'ten','eleven','twelve','thirteen','fourteen','fifteen','sixteen','seventeen','eighteen','nineteen',
    'twenti','thirti','forti','fifti','sixti','seventi','eighti','nineti',
    'hundrend','thousand','million','billion','trillion'};

  //---------------------------------------//

  @override
  List<String> transform(String msg) {
    return msg.split(_split)
      .map((w) => _categorize(_normalize(_stemmer.stem(w))))
      .where((w) => w.isNotEmpty)
      .toList(growable: false);
  }

  //---------------------------------------//

  ///
  String _removeAccents(String word) {
    var result = StringBuffer();
    for (var r in word.runes) {
      if (r >= 0xe0 && r <= 0xe5) {
        result.write('a');
      }
      else if (r == 0xe7) {
        result.write('c');
      }
      else if (r >= 0xe8 && r <= 0xeb) {
        result.write('e');
      }
      else if (r >= 0xec && r <= 0xef) {
        result.write('i');
      }
      else if (r == 0xf1) {
        result.write('n');
      }
      else if ((r >= 0xf2 && r <= 0xf6) || r == 0xf8) {
        result.write('o');
      }
      else if (r >= 0xf9 && r <= 0xfc) {
        result.write('u');
      }
      else if (r == 0xfd || r == 0xff) {
        result.write('y');
      }
      else {
        result.writeCharCode(r);
      }
    }
    return result.toString();
  }

  ///
  String _removeExtraChars(String word) {
    final result = StringBuffer(word[0]);
    var cc       = word[0]; // current char
    var ccc      = 1;       // current char count
    for (int i = 1; i < word.length; ++i) {
      if (word[i] == cc) {
        if (ccc == 1) {
          result.write(cc);
          ccc += 1;
        }
      }
      else {
        cc = word[i];
        result.write(word[i]);
        ccc = 1; 
      }
    }
    return result.toString();
  }

  ///
  String _removeWrappingPunc(String word) {
    var s = 0;
    var e = word.length-1;
    while (s < word.length && !word[s].isalnum()) { ++s; }
    while (e > s && !word[e].isalnum()) { --e; }
    return word.substring(s, e+1);
  }

  ///
  String _normalize(String word) {
    if (word.isEmpty) return word;
    word = _removeExtraChars(word);
    word = _removeAccents(word);
    word = _removeWrappingPunc(word);
    // TODO: replacements?
    return word;
  }  

  //---------------------------------------//

  ///
  String _categorize(String word) {
    if (word.isEmpty) {
      return word;
    }
    else if (_num.hasMatch(word) || _txtNum.contains(word)) {
      return '{{num}}';
    }
    else if (_url.hasMatch(word)) {
      return '{{url}}';
    }
    else if (!word.isalpha()) {
      return '{{other}}';
    }
    else {
      return word;
    }
  }
}