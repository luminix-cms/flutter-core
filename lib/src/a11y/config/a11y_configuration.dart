import 'package:flutter/material.dart';

import '../models/a11y_profile.dart';
import '../models/a11y_settings.dart';
import 'a11y_icons.dart';
import 'a11y_strings.dart';

enum A11yScopeMode { device, user }

class A11yFontOverride {
  const A11yFontOverride({required this.fontFamily, this.package});

  final String fontFamily;
  final String? package;
}

typedef A11yFabBuilder =
    Widget Function(BuildContext context, VoidCallback openCenter);

typedef A11yCenterBuilder =
    Widget Function(BuildContext context, VoidCallback closeCenter);

typedef A11yProfileCardBuilder =
    Widget Function(
      BuildContext context,
      A11yProfile profile,
      bool selected,
      VoidCallback onToggle,
    );

typedef A11yProfileIconBuilder = IconData Function(A11yProfile profile);

typedef A11yPreviewBuilder =
    Widget Function(BuildContext context, A11ySettings pending);

// Component theme com cor explícita congela o valor: `colorScheme.outline` lido
// dentro do `inputDecorationTheme` vira um Color literal no ThemeData, e nenhum
// copyWith(colorScheme:) do adapter o alcança depois. Quem entrega a própria
// função de tema deixa o escopo reconstruí-lo a partir do esquema já adaptado.
typedef A11yThemeRebuilder = ThemeData Function(ColorScheme scheme);

class A11yConfiguration {
  const A11yConfiguration({
    this.enabled = true,
    this.showFab = true,
    this.fabAlignment = Alignment.bottomRight,
    this.fabPadding = const EdgeInsets.all(16),
    this.profiles = A11yProfile.values,
    this.scope = A11yScopeMode.device,
    this.persistManualOverrides = true,
    this.awaitUserScopeOnBoot = false,
    this.maxTextScale = 2.0,
    this.previewMaxTextScale = 1.6,
    this.textScaleSteps = const [1.0, 1.15, 1.3, 1.5],
    this.strings = const A11yStrings(),
    this.icons = const A11yIcons(),
    this.seedColor,
    this.fontFamilyOverrides = const {},
    this.themeRebuilder,
    this.fabBuilder,
    this.centerBuilder,
    this.profileCardBuilder,
    this.profileIconBuilder,
    this.previewBuilder,
  }) : assert(maxTextScale >= 1.0),
       assert(previewMaxTextScale >= 1.0);

  final bool enabled;
  final bool showFab;
  final AlignmentGeometry fabAlignment;
  final EdgeInsetsGeometry fabPadding;
  final List<A11yProfile> profiles;
  final A11yScopeMode scope;
  final bool persistManualOverrides;
  final bool awaitUserScopeOnBoot;
  final double maxTextScale;
  final double previewMaxTextScale;
  final List<double> textScaleSteps;
  final A11yStrings strings;
  final A11yIcons icons;
  final Color? seedColor;
  final Map<A11yFontFamily, A11yFontOverride> fontFamilyOverrides;
  final A11yThemeRebuilder? themeRebuilder;
  final A11yFabBuilder? fabBuilder;
  final A11yCenterBuilder? centerBuilder;
  final A11yProfileCardBuilder? profileCardBuilder;
  final A11yProfileIconBuilder? profileIconBuilder;
  final A11yPreviewBuilder? previewBuilder;

  IconData iconFor(A11yProfile profile) =>
      profileIconBuilder?.call(profile) ?? icons.forProfile(profile);

  int textScaleStepOf(double textScale) {
    var nearest = 0;
    for (var i = 1; i < textScaleSteps.length; i++) {
      if ((textScaleSteps[i] - textScale).abs() <
          (textScaleSteps[nearest] - textScale).abs()) {
        nearest = i;
      }
    }
    return nearest;
  }

  A11yConfiguration copyWith({
    bool? enabled,
    bool? showFab,
    AlignmentGeometry? fabAlignment,
    EdgeInsetsGeometry? fabPadding,
    List<A11yProfile>? profiles,
    A11yScopeMode? scope,
    bool? persistManualOverrides,
    bool? awaitUserScopeOnBoot,
    double? maxTextScale,
    double? previewMaxTextScale,
    List<double>? textScaleSteps,
    A11yStrings? strings,
    A11yIcons? icons,
    Color? seedColor,
    Map<A11yFontFamily, A11yFontOverride>? fontFamilyOverrides,
    A11yThemeRebuilder? themeRebuilder,
    A11yFabBuilder? fabBuilder,
    A11yCenterBuilder? centerBuilder,
    A11yProfileCardBuilder? profileCardBuilder,
    A11yProfileIconBuilder? profileIconBuilder,
    A11yPreviewBuilder? previewBuilder,
  }) {
    return A11yConfiguration(
      enabled: enabled ?? this.enabled,
      showFab: showFab ?? this.showFab,
      fabAlignment: fabAlignment ?? this.fabAlignment,
      fabPadding: fabPadding ?? this.fabPadding,
      profiles: profiles ?? this.profiles,
      scope: scope ?? this.scope,
      persistManualOverrides:
          persistManualOverrides ?? this.persistManualOverrides,
      awaitUserScopeOnBoot: awaitUserScopeOnBoot ?? this.awaitUserScopeOnBoot,
      maxTextScale: maxTextScale ?? this.maxTextScale,
      previewMaxTextScale: previewMaxTextScale ?? this.previewMaxTextScale,
      textScaleSteps: textScaleSteps ?? this.textScaleSteps,
      strings: strings ?? this.strings,
      icons: icons ?? this.icons,
      seedColor: seedColor ?? this.seedColor,
      fontFamilyOverrides: fontFamilyOverrides ?? this.fontFamilyOverrides,
      themeRebuilder: themeRebuilder ?? this.themeRebuilder,
      fabBuilder: fabBuilder ?? this.fabBuilder,
      centerBuilder: centerBuilder ?? this.centerBuilder,
      profileCardBuilder: profileCardBuilder ?? this.profileCardBuilder,
      profileIconBuilder: profileIconBuilder ?? this.profileIconBuilder,
      previewBuilder: previewBuilder ?? this.previewBuilder,
    );
  }
}
