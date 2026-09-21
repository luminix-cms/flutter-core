import 'dart:ui';

const Color _black = Color(0xFF000000);
const Color _white = Color(0xFFFFFFFF);

const int _searchSteps = 12;

double a11yContrastRatio(Color foreground, Color background) {
  final a = foreground.computeLuminance();
  final b = background.computeLuminance();
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

bool a11yMeetsContrast(
  Color foreground,
  Color background,
  double minimumRatio,
) {
  return a11yContrastRatio(foreground, background) >= minimumRatio;
}

Color a11yContrastPoleFor(Color background) {
  return a11yContrastRatio(_black, background) >=
          a11yContrastRatio(_white, background)
      ? _black
      : _white;
}

Color a11yEnsureContrast(
  Color foreground,
  Color background,
  double minimumRatio,
) {
  if (minimumRatio <= 1.0) return foreground;
  if (a11yMeetsContrast(foreground, background, minimumRatio)) {
    return foreground;
  }

  final pole = a11yContrastPoleFor(background).withValues(alpha: foreground.a);

  if (!a11yMeetsContrast(pole, background, minimumRatio)) return pole;

  var unmet = 0.0;
  var met = 1.0;
  for (var step = 0; step < _searchSteps; step++) {
    final middle = (unmet + met) / 2;
    if (a11yMeetsContrast(
      Color.lerp(foreground, pole, middle)!,
      background,
      minimumRatio,
    )) {
      met = middle;
    } else {
      unmet = middle;
    }
  }

  return Color.lerp(foreground, pole, met)!;
}
