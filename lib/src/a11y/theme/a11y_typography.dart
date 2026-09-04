import 'package:flutter/material.dart';
import 'package:luminix_flutter/src/a11y/config/a11y_configuration.dart';
import 'package:luminix_flutter/src/a11y/models/a11y_settings.dart';

const String a11yFontPackage = 'luminix_flutter';

const String _hyperlegible = 'AtkinsonHyperlegible';

const double _fallbackFontSize = 14.0;

const int _reducedEmphasisCeiling = 600;

class A11yResolvedFont {
  const A11yResolvedFont({
    required this.family,
    this.package,
    this.fallback = const [],
  });

  final String family;
  final String? package;
  final List<String> fallback;
}

A11yResolvedFont? a11yResolveFont(
  A11ySettings settings, {
  Map<A11yFontFamily, A11yFontOverride> fontFamilyOverrides = const {},
}) {
  if (settings.fontFamily == A11yFontFamily.standard) return null;

  final override = fontFamilyOverrides[settings.fontFamily];
  if (override != null) {
    return A11yResolvedFont(
      family: override.fontFamily,
      package: override.package,
    );
  }

  final family = settings.fontFamily.familyName;
  if (family == null) return null;

  return A11yResolvedFont(
    family: family,
    package: a11yFontPackage,
    fallback: family == _hyperlegible ? const [] : const [_hyperlegible],
  );
}

TextStyle a11yStyleWithFont(TextStyle base, A11yResolvedFont font) {
  // TextStyle.fontFamilyFallback prefixa cada item com o `package` do estilo:
  // uma cadeia herdada da base viraria packages/luminix_flutter/<fonte do app>.
  // packages/flutter/lib/src/painting/text_style.dart
  return base.copyWith(
    fontFamily: font.family,
    package: font.package,
    fontFamilyFallback: font.fallback,
  );
}

TextTheme applyA11yTypography(
  TextTheme base,
  A11ySettings settings, {
  Map<A11yFontFamily, A11yFontOverride> fontFamilyOverrides = const {},
}) {
  if (!settings.changesTypography) return base;

  final font = a11yResolveFont(
    settings,
    fontFamilyOverrides: fontFamilyOverrides,
  );

  TextStyle? adapt(TextStyle? style) {
    if (style == null) return null;
    return a11yAdaptTextStyle(style, settings, font: font);
  }

  return TextTheme(
    displayLarge: adapt(base.displayLarge),
    displayMedium: adapt(base.displayMedium),
    displaySmall: adapt(base.displaySmall),
    headlineLarge: adapt(base.headlineLarge),
    headlineMedium: adapt(base.headlineMedium),
    headlineSmall: adapt(base.headlineSmall),
    titleLarge: adapt(base.titleLarge),
    titleMedium: adapt(base.titleMedium),
    titleSmall: adapt(base.titleSmall),
    bodyLarge: adapt(base.bodyLarge),
    bodyMedium: adapt(base.bodyMedium),
    bodySmall: adapt(base.bodySmall),
    labelLarge: adapt(base.labelLarge),
    labelMedium: adapt(base.labelMedium),
    labelSmall: adapt(base.labelSmall),
  );
}

TextStyle a11yAdaptTextStyle(
  TextStyle style,
  A11ySettings settings, {
  A11yResolvedFont? font,
}) {
  var adapted = font == null ? style : a11yStyleWithFont(style, font);

  final em = settings.letterSpacing.emValue;
  if (em > 0) {
    final fontSize = adapted.fontSize ?? _fallbackFontSize;
    adapted = adapted.copyWith(
      letterSpacing: (adapted.letterSpacing ?? 0) + em * fontSize,
    );
  }

  if (settings.lineHeight != null) {
    adapted = adapted.copyWith(height: settings.lineHeight);
  }

  if (settings.reducedEmphasis) {
    final weight = adapted.fontWeight ?? FontWeight.normal;
    adapted = adapted.copyWith(
      fontStyle: FontStyle.normal,
      fontWeight: weight.value > _reducedEmphasisCeiling
          ? FontWeight.w600
          : weight,
    );
  }

  return adapted;
}
