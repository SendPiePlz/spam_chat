import 'package:flutter_test/flutter_test.dart';

import 'package:spam_chat/utils/spam_filter.dart';

//=================================================//

void main() {
  test('SpamClassifier prediction tests', () {
    const msg1 = "Free entry in 2 a wkly comp to win FA Cup final tkts 21st May 2005. Text FA to 87121 to receive entry question(std txt rate)T&C's apply 08452810075over18's";
    const msg2 = 'Go until jurong point, crazy.. Available only in bugis n great world la e buffet... Cine there got amore wat...';
    final spam = SpamFilter();
    expect(spam.isSpam(msg1), true);
    expect(spam.isSpam(msg2), false);
  });

  test('SpamClassifier parsing tests', () {
    const msg1 = "Free entry in 2 a wkly comp to win FA Cup final tkts 21st May 2005. Text FA to 87121 to receive entry question(std txt rate)T&C's apply 08452810075over18's";
    const p_msg1 = ['free', 'entri', 'in', '{{num}}', 'a', 'wkli', 'comp', 'to', 'win', 'fa', 'cup', 'final', 'tkt', '{{num}}', 'may', '{{num}}', '{{other}}', 'text', 'fa', 'to', '{{num}}', 'to', 'receiv', 'entri', 'question', '{{other}}', 'std', 'txt', 'rate', '{{other}}', 't', 'and', 'c', 's', 'appli', '{{other}}', 's'];
    const msg2 = 'Go until jurong point, crazy.. Available only in bugis n great world la e buffet... Cine there got amore wat...';
    const p_msg2 = ['go', 'until', 'jurong', 'point', '{{other}}', 'crazi', '{{other}}', 'avail', 'onli', 'in', 'bugi', 'n', 'great', 'world', 'la', 'e', 'buffet', '{{other}}', 'cine', 'there', 'got', 'amor', 'wat', '{{other}}'];

    // TODO:
    final trans = SpamTransofmer();
    expect(trans.transform(msg1), p_msg1);
    expect(trans.transform(msg2), p_msg2);
  });
}