import 'package:flutter/material.dart';
import 'package:luminix_flutter/src/a11y/config/a11y_configuration.dart';
import 'package:luminix_flutter/src/a11y/models/a11y_settings.dart';

import 'a11y_color_scheme.dart';
import 'a11y_contrast.dart';
import 'a11y_page_transitions.dart';
import 'a11y_theme_extension.dart';
import 'a11y_typography.dart';

const Color a11yCreamSurface = Color(0xFFFAF3E3);

const double _minimumFocusRingRatio = 3.0;

class A11yThemeAdapter {
  const A11yThemeAdapter({
    this.colorSchemeResolver = const A11yBoostedColorSchemeResolver(),
    this.fontFamilyOverrides = const {},
    this.themeRebuilder,
  });

  final A11yColorSchemeResolver colorSchemeResolver;
  final Map<A11yFontFamily, A11yFontOverride> fontFamilyOverrides;
  final A11yThemeRebuilder? themeRebuilder;

  ThemeData adapt(ThemeData base, A11ySettings settings) {
    if (!settings.changesTheme) return base;

    final scheme = resolveColorScheme(base.colorScheme, settings);

    var theme = scheme == base.colorScheme ? base : rebuild(base, scheme);
    theme = applyTypography(theme, settings);

    if (settings.reduceMotion) theme = applyReducedMotion(theme);

    return theme.copyWith(
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [...base.extensions.values, buildExtension(scheme, settings)],
    );
  }

  // adapt devolve a base intacta quando nada muda; sob o escopo a extensão
  // precisa existir mesmo assim, senão os primitivos caem no fallback const.
  ThemeData attachExtension(ThemeData base, A11ySettings settings) {
    if (base.extension<A11yThemeExtension>() != null) return base;

    return base.copyWith(
      extensions: [
        ...base.extensions.values,
        buildExtension(base.colorScheme, settings),
      ],
    );
  }

  A11yThemeAdapter copyWith({
    A11yColorSchemeResolver? colorSchemeResolver,
    Map<A11yFontFamily, A11yFontOverride>? fontFamilyOverrides,
    A11yThemeRebuilder? themeRebuilder,
  }) {
    return A11yThemeAdapter(
      colorSchemeResolver: colorSchemeResolver ?? this.colorSchemeResolver,
      fontFamilyOverrides: fontFamilyOverrides ?? this.fontFamilyOverrides,
      themeRebuilder: themeRebuilder ?? this.themeRebuilder,
    );
  }

  // O esquema adaptado alcança os papéis, nunca as cores que o app já
  // materializou nos component themes. Com themeRebuilder o app refaz o próprio
  // tema a partir dele; sem, resta forçar o esquema e os derivados legados.
  //
  // Não se re-resolve o esquema do tema reconstruído: a11yEnsureContrast
  // devolve a cor intacta quando a razão já basta, mas o app pode ter derivado
  // papéis novos do esquema recebido, e adaptá-los de novo empilharia contraste.
  @protected
  ThemeData rebuild(ThemeData base, ColorScheme scheme) {
    final rebuilt = themeRebuilder?.call(scheme);

    return applyColorScheme(rebuilt ?? base, scheme);
  }

  @protected
  ColorScheme resolveColorScheme(ColorScheme base, A11ySettings settings) {
    final surfaced =
        settings.creamReadingBackground && base.brightness == Brightness.light
        ? base.copyWith(surface: a11yCreamSurface)
        : base;

    return colorSchemeResolver.resolve(surfaced, settings);
  }

  // ThemeData.copyWith(colorScheme:) não refaz os derivados legados; eles só
  // existem no construtor.
  // packages/flutter/lib/src/material/theme_data.dart
  @protected
  ThemeData applyColorScheme(ThemeData base, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;

    return base.copyWith(
      colorScheme: scheme,
      primaryColor: isDark ? scheme.surface : scheme.primary,
      canvasColor: scheme.surface,
      scaffoldBackgroundColor: scheme.surface,
      cardColor: scheme.surface,
      dividerColor: scheme.outline,
    );
  }

  @protected
  ThemeData applyTypography(ThemeData base, A11ySettings settings) {
    if (!settings.changesTypography) return base;

    return base.copyWith(
      textTheme: applyA11yTypography(
        base.textTheme,
        settings,
        fontFamilyOverrides: fontFamilyOverrides,
      ),
      primaryTextTheme: applyA11yTypography(
        base.primaryTextTheme,
        settings,
        fontFamilyOverrides: fontFamilyOverrides,
      ),
    );
  }

  @protected
  ThemeData applyReducedMotion(ThemeData base) {
    return base.copyWith(
      pageTransitionsTheme: a11yNoPageTransitionsTheme,
      splashFactory: NoSplash.splashFactory,
    );
  }

  @protected
  A11yThemeExtension buildExtension(ColorScheme scheme, A11ySettings settings) {
    final (
      double ringWidth,
      double haloWidth,
    ) = switch (settings.contrastMode) {
      A11yContrastMode.highContrast => (3.0, 4.0),
      A11yContrastMode.enhancedContrast => (2.0, 3.0),
      _ => (2.0, 0.0),
    };

    final borderWidth = switch (settings.contrastMode) {
      A11yContrastMode.highContrast => 2.0,
      A11yContrastMode.enhancedContrast => 1.5,
      _ => 1.0,
    };

    final ringRatio =
        settings.contrastMode.minimumContrastRatio > _minimumFocusRingRatio
        ? settings.contrastMode.minimumContrastRatio
        : _minimumFocusRingRatio;

    return A11yThemeExtension(
      contrastMode: settings.contrastMode,
      reduceMotion: settings.reduceMotion,
      decorativeBackgrounds: settings.decorativeBackgrounds,
      borderWidth: borderWidth,
      focusRingColor: a11yEnsureContrast(
        scheme.primary,
        scheme.surface,
        ringRatio,
      ),
      focusHaloColor: scheme.surface,
      focusRingWidth: ringWidth,
      focusHaloWidth: haloWidth,
    );
  }
}
