import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:luminix_flutter/src/a11y/models/a11y_settings.dart';

class A11yThemeExtension extends ThemeExtension<A11yThemeExtension> {
  const A11yThemeExtension({
    this.contrastMode = A11yContrastMode.standard,
    this.reduceMotion = false,
    this.decorativeBackgrounds = true,
    this.borderWidth = 1.0,
    this.focusRingColor = const Color(0xFF1A73E8),
    this.focusHaloColor = const Color(0xFFFFFFFF),
    this.focusRingWidth = 2.0,
    this.focusHaloWidth = 0.0,
    this.minTapTarget = 48.0,
  });

  final A11yContrastMode contrastMode;
  final bool reduceMotion;
  final bool decorativeBackgrounds;
  final double borderWidth;
  final Color focusRingColor;
  final Color focusHaloColor;
  final double focusRingWidth;
  final double focusHaloWidth;
  final double minTapTarget;

  static const A11yThemeExtension fallback = A11yThemeExtension();

  bool get isHighContrast => contrastMode.isHighContrast;

  bool get boostsContrast => contrastMode.boostsContrast;

  static A11yThemeExtension of(BuildContext context) =>
      maybeOf(context) ?? fallback;

  static A11yThemeExtension? maybeOf(BuildContext context) =>
      Theme.of(context).extension<A11yThemeExtension>();

  @override
  A11yThemeExtension copyWith({
    A11yContrastMode? contrastMode,
    bool? reduceMotion,
    bool? decorativeBackgrounds,
    double? borderWidth,
    Color? focusRingColor,
    Color? focusHaloColor,
    double? focusRingWidth,
    double? focusHaloWidth,
    double? minTapTarget,
  }) {
    return A11yThemeExtension(
      contrastMode: contrastMode ?? this.contrastMode,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      decorativeBackgrounds:
          decorativeBackgrounds ?? this.decorativeBackgrounds,
      borderWidth: borderWidth ?? this.borderWidth,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      focusHaloColor: focusHaloColor ?? this.focusHaloColor,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      focusHaloWidth: focusHaloWidth ?? this.focusHaloWidth,
      minTapTarget: minTapTarget ?? this.minTapTarget,
    );
  }

  @override
  A11yThemeExtension lerp(
    covariant ThemeExtension<A11yThemeExtension>? other,
    double t,
  ) {
    if (other is! A11yThemeExtension) return this;

    final snapped = t < 0.5 ? this : other;

    return A11yThemeExtension(
      contrastMode: snapped.contrastMode,
      reduceMotion: snapped.reduceMotion,
      decorativeBackgrounds: snapped.decorativeBackgrounds,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t)!,
      focusRingColor: Color.lerp(focusRingColor, other.focusRingColor, t)!,
      focusHaloColor: Color.lerp(focusHaloColor, other.focusHaloColor, t)!,
      focusRingWidth: lerpDouble(focusRingWidth, other.focusRingWidth, t)!,
      focusHaloWidth: lerpDouble(focusHaloWidth, other.focusHaloWidth, t)!,
      minTapTarget: lerpDouble(minTapTarget, other.minTapTarget, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A11yThemeExtension &&
        other.contrastMode == contrastMode &&
        other.reduceMotion == reduceMotion &&
        other.decorativeBackgrounds == decorativeBackgrounds &&
        other.borderWidth == borderWidth &&
        other.focusRingColor == focusRingColor &&
        other.focusHaloColor == focusHaloColor &&
        other.focusRingWidth == focusRingWidth &&
        other.focusHaloWidth == focusHaloWidth &&
        other.minTapTarget == minTapTarget;
  }

  @override
  int get hashCode => Object.hash(
    contrastMode,
    reduceMotion,
    decorativeBackgrounds,
    borderWidth,
    focusRingColor,
    focusHaloColor,
    focusRingWidth,
    focusHaloWidth,
    minTapTarget,
  );
}
