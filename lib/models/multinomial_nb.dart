import 'dart:typed_data';

import 'package:spam_chat/models/dictionary.dart';

//=================================================//

///
/// Multinomial Naive Bayes String Binary Classifier.
///
/// The caller is expected to provide pre-fitted log-likelihoods
/// and feature `vocabulary`.
/// The `preprocessor` field is a conveniant way to tie-in the string
/// processing steps with the actual prediction step.
///
class MultinomialNB {
  const MultinomialNB(this.vocabulary, this.preprocessor);

  final Dictionary vocabulary;
  final List<String> Function(String) preprocessor;

  /// 
  bool predict(String str) {
    final vec = preprocessor(str);
    var probs = Float64x2.zero();
    for (int i = 0; i < vec.length; ++i) {
      final p = vocabulary[vec[i]];
      if (p != null) {
        probs += p;
      }
    }
    return probs.x < probs.y;
  }
}