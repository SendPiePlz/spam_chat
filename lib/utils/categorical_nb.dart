import 'dart:typed_data';

//=================================================//

///
/// Categorical Naive Bayes Binary Classifier.
///
class CategoricalNB {
  const CategoricalNB(this.featureCount, this.logLikelihoods, this.priorProbabilities);

  final int featureCount;
  final List<Float64x2List> logLikelihoods;
  final Float64x2 priorProbabilities;

  ///
  ///
  ///
  bool predict(List<int> vec) {
    assert(vec.length == featureCount);
    assert(logLikelihoods.length == featureCount);
    var probs = priorProbabilities;
    for (int i = 0; i < featureCount; ++i) {
      probs += logLikelihoods[i][vec[i]];
    }
    return probs.x < probs.y;
  }
}