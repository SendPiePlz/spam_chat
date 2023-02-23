import 'dart:typed_data';

import 'package:spam_chat/models/transformer.dart';

//=================================================//

class Vec2 {
  const Vec2(this.x, this.y);

  final double x;
  final double y;

  Float64x2 get vector => Float64x2(x, y);
}

//=================================================//

///
///
///
class VectorClassifier<T> {
  const VectorClassifier(this.logLikelihoods, this.transformer);
    //: assert(logLikelihoods.length > 0);

    final List<Vec2> logLikelihoods;
    final Transformer<double, T> transformer;

    ///
    bool predict(T value) {
      final vec = transformer.transform(value);
      assert(logLikelihoods.length > 0);
      assert(vec.length == logLikelihoods.length);
      var probs = Float64x2.zero();
      for (int i = 0; i < logLikelihoods.length; ++i) {
        probs += logLikelihoods[i].vector * Float64x2.splat(vec[i]);
      }
      return probs.x < probs.y;
    }
}