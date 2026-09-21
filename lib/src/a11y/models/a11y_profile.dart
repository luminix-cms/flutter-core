import 'a11y_settings.dart';

enum A11yProfile {
  lowVision,
  colorBlindness,
  epilepsy,
  adhd,
  dyslexia,
  hearingImpairment,
}

extension A11yProfilePreset on A11yProfile {
  A11ySettings get preset => switch (this) {
    A11yProfile.lowVision => const A11ySettings(
      fontFamily: A11yFontFamily.hyperlegible,
      textScale: 1.5,
      boldText: true,
      letterSpacing: A11yLetterSpacing.wide,
      lineHeight: 1.5,
      contrastMode: A11yContrastMode.highContrast,
      colorBlindCues: true,
      decorativeBackgrounds: false,
      ttsEnabled: true,
      haptics: true,
    ),
    A11yProfile.colorBlindness => const A11ySettings(colorBlindCues: true),
    A11yProfile.epilepsy => const A11ySettings(
      decorativeBackgrounds: false,
      reduceMotion: true,
      noFlashing: true,
      disableAutoplay: true,
    ),
    A11yProfile.adhd => const A11ySettings(
      textScale: 1.15,
      decorativeBackgrounds: false,
      reduceMotion: true,
      disableAutoplay: true,
      focusMode: true,
      hideTimers: true,
      oneItemPerScreen: true,
    ),
    A11yProfile.dyslexia => const A11ySettings(
      fontFamily: A11yFontFamily.openDyslexic,
      textScale: 1.15,
      letterSpacing: A11yLetterSpacing.wider,
      lineHeight: 1.8,
      decorativeBackgrounds: false,
      focusMode: true,
      hideTimers: true,
      ttsEnabled: true,
      readingHighlight: true,
      reducedEmphasis: true,
    ),
    A11yProfile.hearingImpairment => const A11ySettings(
      captions: true,
      visualCuesForSound: true,
      haptics: true,
    ),
  };
}

A11yProfile? a11yProfileFromName(Object? name) {
  for (final profile in A11yProfile.values) {
    if (profile.name == name) return profile;
  }
  return null;
}

List<A11yProfile> a11yProfilesFromNames(Object? names) {
  if (names is! Iterable) return const [];
  return names
      .map(a11yProfileFromName)
      .whereType<A11yProfile>()
      .toSet()
      .toList()
    ..sort((a, b) => a.index.compareTo(b.index));
}

A11ySettings a11ySettingsForProfiles(Iterable<A11yProfile> profiles) {
  return A11ySettings.merge(profiles.map((profile) => profile.preset));
}
