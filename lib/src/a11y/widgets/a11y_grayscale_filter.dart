import 'package:flutter/widgets.dart';

const List<double> _grayscale = [
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
];

const List<double> _identity = [
  1, 0, 0, 0, 0, //
  0, 1, 0, 0, 0, //
  0, 0, 1, 0, 0, //
  0, 0, 0, 1, 0, //
];

class A11yGrayscaleFilter extends StatelessWidget {
  const A11yGrayscaleFilter({
    super.key,
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Montar e desmontar o ColorFiltered ao vivo remonta a subárvore inteira do
    // app durante um build e dispara '!_debugDoingUpdate': is not true.
    // packages/flutter/lib/src/services/restoration.dart
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(enabled ? _grayscale : _identity),
      child: child,
    );
  }
}
