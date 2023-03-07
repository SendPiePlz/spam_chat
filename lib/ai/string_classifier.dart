import 'dart:typed_data';

import 'package:spam_chat/ai/transformer.dart';
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
class StringClassifier {
  const StringClassifier(this.vocabulary, this.transformer);

  final Dictionary vocabulary;
  final Transformer<String, String> transformer;

  /// 
  bool predict(String str) {
    final vec = transformer.transform(str);
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