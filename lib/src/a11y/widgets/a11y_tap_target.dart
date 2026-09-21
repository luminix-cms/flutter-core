import 'package:flutter/widgets.dart';

import '../theme/a11y_theme_extension.dart';

class A11yTapTarget extends StatelessWidget {
  const A11yTapTarget({
    super.key,
    required this.child,
    this.minSize,
    this.margin = const EdgeInsets.all(4),
  });

  final Widget child;
  final double? minSize;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final size = minSize ?? A11yThemeExtension.of(context).minTapTarget;

    return Padding(
      padding: margin,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        child: Center(widthFactor: 1, heightFactor: 1, child: child),
      ),
    );
  }
}
