import 'package:flutter/painting.dart';

class A11yTextScaler extends TextScaler {
  const A11yTextScaler({required this.inner, required this.factor})
    : assert(factor > 0);

  final TextScaler inner;
  final double factor;

  // O ajuste do sistema operacional é a base, não algo a descartar: compor e
  // só então limitar mantém quem já aumentou a fonte no aparelho.
  static TextScaler resolve({
    required TextScaler platform,
    required double factor,
    double maxScaleFactor = double.infinity,
  }) {
    final composed = factor == 1.0
        ? platform
        : A11yTextScaler(inner: platform, factor: factor);
    return composed.clamp(maxScaleFactor: maxScaleFactor);
  }

  @override
  double scale(double fontSize) => inner.scale(fontSize * factor);

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => inner.textScaleFactor * factor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A11yTextScaler &&
        other.inner == inner &&
        other.factor == factor;
  }

  @override
  int get hashCode => Object.hash(inner, factor);

  @override
  String toString() => 'A11yTextScaler($inner x $factor)';
}
