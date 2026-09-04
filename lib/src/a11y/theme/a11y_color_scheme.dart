import 'package:flutter/material.dart';
import 'package:luminix_flutter/src/a11y/models/a11y_settings.dart';

import 'a11y_contrast.dart';

typedef A11ySchemeRoleReader = Color Function(ColorScheme scheme);
typedef A11ySchemeRoleWriter =
    ColorScheme Function(ColorScheme scheme, Color value);

class A11ySchemePair {
  const A11ySchemePair({
    required this.name,
    required this.foreground,
    required this.background,
    required this.withForeground,
  });

  final String name;
  final A11ySchemeRoleReader foreground;
  final A11ySchemeRoleReader background;
  final A11ySchemeRoleWriter withForeground;

  ColorScheme ensure(ColorScheme scheme, double minimumRatio) {
    final surface = background(scheme);
    final adjusted = a11yEnsureContrast(
      foreground(scheme),
      surface,
      minimumRatio,
    );
    return withForeground(scheme, adjusted);
  }

  double ratioIn(ColorScheme scheme) =>
      a11yContrastRatio(foreground(scheme), background(scheme));
}

abstract class A11yColorSchemeResolver {
  const A11yColorSchemeResolver();

  ColorScheme resolve(ColorScheme base, A11ySettings settings);
}

class A11yBoostedColorSchemeResolver extends A11yColorSchemeResolver {
  const A11yBoostedColorSchemeResolver();

  static final List<A11ySchemePair> pairs = List.unmodifiable([
    A11ySchemePair(
      name: 'onPrimary',
      foreground: (s) => s.onPrimary,
      background: (s) => s.primary,
      withForeground: (s, c) => s.copyWith(onPrimary: c),
    ),
    A11ySchemePair(
      name: 'onPrimaryContainer',
      foreground: (s) => s.onPrimaryContainer,
      background: (s) => s.primaryContainer,
      withForeground: (s, c) => s.copyWith(onPrimaryContainer: c),
    ),
    A11ySchemePair(
      name: 'onSecondary',
      foreground: (s) => s.onSecondary,
      background: (s) => s.secondary,
      withForeground: (s, c) => s.copyWith(onSecondary: c),
    ),
    A11ySchemePair(
      name: 'onSecondaryContainer',
      foreground: (s) => s.onSecondaryContainer,
      background: (s) => s.secondaryContainer,
      withForeground: (s, c) => s.copyWith(onSecondaryContainer: c),
    ),
    A11ySchemePair(
      name: 'onTertiary',
      foreground: (s) => s.onTertiary,
      background: (s) => s.tertiary,
      withForeground: (s, c) => s.copyWith(onTertiary: c),
    ),
    A11ySchemePair(
      name: 'onTertiaryContainer',
      foreground: (s) => s.onTertiaryContainer,
      background: (s) => s.tertiaryContainer,
      withForeground: (s, c) => s.copyWith(onTertiaryContainer: c),
    ),
    A11ySchemePair(
      name: 'onError',
      foreground: (s) => s.onError,
      background: (s) => s.error,
      withForeground: (s, c) => s.copyWith(onError: c),
    ),
    A11ySchemePair(
      name: 'onErrorContainer',
      foreground: (s) => s.onErrorContainer,
      background: (s) => s.errorContainer,
      withForeground: (s, c) => s.copyWith(onErrorContainer: c),
    ),
    A11ySchemePair(
      name: 'onSurface',
      foreground: (s) => s.onSurface,
      background: (s) => s.surface,
      withForeground: (s, c) => s.copyWith(onSurface: c),
    ),
    A11ySchemePair(
      name: 'onSurfaceVariant',
      foreground: (s) => s.onSurfaceVariant,
      background: (s) => s.surface,
      withForeground: (s, c) => s.copyWith(onSurfaceVariant: c),
    ),
    A11ySchemePair(
      name: 'onInverseSurface',
      foreground: (s) => s.onInverseSurface,
      background: (s) => s.inverseSurface,
      withForeground: (s, c) => s.copyWith(onInverseSurface: c),
    ),
    A11ySchemePair(
      name: 'outline',
      foreground: (s) => s.outline,
      background: (s) => s.surface,
      withForeground: (s, c) => s.copyWith(outline: c),
    ),
    A11ySchemePair(
      name: 'outlineVariant',
      foreground: (s) => s.outlineVariant,
      background: (s) => s.surface,
      withForeground: (s, c) => s.copyWith(outlineVariant: c),
    ),
  ]);

  @override
  ColorScheme resolve(ColorScheme base, A11ySettings settings) {
    final minimumRatio = settings.contrastMode.minimumContrastRatio;
    if (minimumRatio <= 1.0) return base;

    var scheme = base;
    for (final pair in pairs) {
      scheme = pair.ensure(scheme, minimumRatio);
    }
    return scheme;
  }
}

class A11ySeededColorSchemeResolver extends A11yColorSchemeResolver {
  const A11ySeededColorSchemeResolver({this.seedColor});

  final Color? seedColor;

  @override
  ColorScheme resolve(ColorScheme base, A11ySettings settings) {
    if (!settings.contrastMode.boostsContrast) return base;

    return ColorScheme.fromSeed(
      seedColor: seedColor ?? base.primary,
      brightness: base.brightness,
      contrastLevel: settings.contrastMode.isHighContrast ? 1.0 : 0.5,
    );
  }
}
