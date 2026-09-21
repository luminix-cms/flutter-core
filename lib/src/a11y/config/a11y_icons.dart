import 'package:flutter/material.dart';

import '../models/a11y_profile.dart';
import '../models/a11y_settings.dart';

class A11yIcons {
  const A11yIcons({
    this.center = Icons.accessibility_new,
    this.close = Icons.close,
    this.selected = Icons.check_circle,
    this.unselected = Icons.circle_outlined,
    this.lowVision = Icons.visibility_outlined,
    this.colorBlindness = Icons.palette_outlined,
    this.epilepsy = Icons.bolt_outlined,
    this.adhd = Icons.psychology_outlined,
    this.dyslexia = Icons.menu_book_outlined,
    this.hearingImpairment = Icons.hearing_outlined,
    this.contrastStandard = Icons.contrast,
    this.contrastGrayscale = Icons.filter_b_and_w,
    this.contrastEnhanced = Icons.exposure_plus_1,
    this.contrastHigh = Icons.exposure_plus_2,
  });

  final IconData center;
  final IconData close;
  final IconData selected;
  final IconData unselected;
  final IconData lowVision;
  final IconData colorBlindness;
  final IconData epilepsy;
  final IconData adhd;
  final IconData dyslexia;
  final IconData hearingImpairment;
  final IconData contrastStandard;
  final IconData contrastGrayscale;
  final IconData contrastEnhanced;
  final IconData contrastHigh;

  IconData forProfile(A11yProfile profile) => switch (profile) {
    A11yProfile.lowVision => lowVision,
    A11yProfile.colorBlindness => colorBlindness,
    A11yProfile.epilepsy => epilepsy,
    A11yProfile.adhd => adhd,
    A11yProfile.dyslexia => dyslexia,
    A11yProfile.hearingImpairment => hearingImpairment,
  };

  IconData forContrast(A11yContrastMode mode) => switch (mode) {
    A11yContrastMode.standard => contrastStandard,
    A11yContrastMode.grayscale => contrastGrayscale,
    A11yContrastMode.enhancedContrast => contrastEnhanced,
    A11yContrastMode.highContrast => contrastHigh,
  };

  A11yIcons copyWith({
    IconData? center,
    IconData? close,
    IconData? selected,
    IconData? unselected,
    IconData? lowVision,
    IconData? colorBlindness,
    IconData? epilepsy,
    IconData? adhd,
    IconData? dyslexia,
    IconData? hearingImpairment,
    IconData? contrastStandard,
    IconData? contrastGrayscale,
    IconData? contrastEnhanced,
    IconData? contrastHigh,
  }) {
    return A11yIcons(
      center: center ?? this.center,
      close: close ?? this.close,
      selected: selected ?? this.selected,
      unselected: unselected ?? this.unselected,
      lowVision: lowVision ?? this.lowVision,
      colorBlindness: colorBlindness ?? this.colorBlindness,
      epilepsy: epilepsy ?? this.epilepsy,
      adhd: adhd ?? this.adhd,
      dyslexia: dyslexia ?? this.dyslexia,
      hearingImpairment: hearingImpairment ?? this.hearingImpairment,
      contrastStandard: contrastStandard ?? this.contrastStandard,
      contrastGrayscale: contrastGrayscale ?? this.contrastGrayscale,
      contrastEnhanced: contrastEnhanced ?? this.contrastEnhanced,
      contrastHigh: contrastHigh ?? this.contrastHigh,
    );
  }
}
