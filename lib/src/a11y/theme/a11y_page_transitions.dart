import 'package:flutter/material.dart';

class A11yNoTransitionsBuilder extends PageTransitionsBuilder {
  const A11yNoTransitionsBuilder();

  // Um builder que só devolve o child ainda segura a rota pelos 300 ms do
  // transitionDuration herdado.
  // packages/flutter/lib/src/widgets/page_transitions_builder.dart
  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

final PageTransitionsTheme a11yNoPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: const A11yNoTransitionsBuilder(),
  },
);
