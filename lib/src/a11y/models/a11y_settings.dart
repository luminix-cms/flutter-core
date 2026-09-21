enum A11yFontFamily { standard, hyperlegible, lexend, openDyslexic }

extension A11yFontFamilyName on A11yFontFamily {
  String? get familyName => switch (this) {
    A11yFontFamily.standard => null,
    A11yFontFamily.hyperlegible => 'AtkinsonHyperlegible',
    A11yFontFamily.lexend => 'Lexend',
    A11yFontFamily.openDyslexic => 'OpenDyslexic',
  };
}

enum A11yLetterSpacing { normal, wide, wider }

extension A11yLetterSpacingValue on A11yLetterSpacing {
  double get emValue => switch (this) {
    A11yLetterSpacing.normal => 0.0,
    A11yLetterSpacing.wide => 0.06,
    A11yLetterSpacing.wider => 0.12,
  };
}

enum A11yContrastMode { standard, grayscale, enhancedContrast, highContrast }

extension A11yContrastModeQuery on A11yContrastMode {
  bool get isHighContrast => this == A11yContrastMode.highContrast;

  bool get boostsContrast =>
      this == A11yContrastMode.enhancedContrast ||
      this == A11yContrastMode.highContrast;

  double get minimumContrastRatio => switch (this) {
    A11yContrastMode.highContrast => 7.0,
    A11yContrastMode.enhancedContrast => 4.5,
    _ => 0.0,
  };
}

class A11ySettings {
  const A11ySettings({
    this.fontFamily = A11yFontFamily.standard,
    this.textScale = 1.0,
    this.boldText = false,
    this.letterSpacing = A11yLetterSpacing.normal,
    this.lineHeight,
    this.contrastMode = A11yContrastMode.standard,
    this.colorBlindCues = false,
    this.decorativeBackgrounds = true,
    this.reduceMotion = false,
    this.noFlashing = false,
    this.disableAutoplay = false,
    this.focusMode = false,
    this.hideTimers = false,
    this.oneItemPerScreen = false,
    this.ttsEnabled = false,
    this.readingHighlight = false,
    this.captions = false,
    this.visualCuesForSound = false,
    this.haptics = false,
    this.reducedEmphasis = false,
    this.creamReadingBackground = false,
  });

  final A11yFontFamily fontFamily;
  final double textScale;
  final bool boldText;
  final A11yLetterSpacing letterSpacing;
  final double? lineHeight;
  final A11yContrastMode contrastMode;
  final bool colorBlindCues;
  final bool decorativeBackgrounds;
  final bool reduceMotion;
  final bool noFlashing;
  final bool disableAutoplay;
  final bool focusMode;
  final bool hideTimers;
  final bool oneItemPerScreen;
  final bool ttsEnabled;
  final bool readingHighlight;
  final bool captions;
  final bool visualCuesForSound;
  final bool haptics;
  final bool reducedEmphasis;
  final bool creamReadingBackground;

  static const A11ySettings defaults = A11ySettings();

  bool get isDefault => this == defaults;

  bool get changesTypography =>
      fontFamily != A11yFontFamily.standard ||
      letterSpacing != A11yLetterSpacing.normal ||
      lineHeight != null ||
      reducedEmphasis;

  bool get changesTheme =>
      changesTypography ||
      contrastMode != A11yContrastMode.standard ||
      reduceMotion ||
      creamReadingBackground ||
      !decorativeBackgrounds;

  static A11ySettings merge(Iterable<A11ySettings> presets) {
    final list = presets.toList();
    if (list.isEmpty) return defaults;

    var fontFamily = A11yFontFamily.standard;
    for (final family in [
      A11yFontFamily.openDyslexic,
      A11yFontFamily.hyperlegible,
      A11yFontFamily.lexend,
    ]) {
      if (list.any((s) => s.fontFamily == family)) {
        fontFamily = family;
        break;
      }
    }

    var contrastMode = A11yContrastMode.standard;
    for (final mode in [
      A11yContrastMode.highContrast,
      A11yContrastMode.enhancedContrast,
      A11yContrastMode.grayscale,
    ]) {
      if (list.any((s) => s.contrastMode == mode)) {
        contrastMode = mode;
        break;
      }
    }

    return A11ySettings(
      fontFamily: fontFamily,
      textScale: list.map((s) => s.textScale).reduce((a, b) => a > b ? a : b),
      boldText: list.any((s) => s.boldText),
      letterSpacing: list
          .map((s) => s.letterSpacing)
          .reduce((a, b) => a.emValue > b.emValue ? a : b),
      lineHeight: list
          .map((s) => s.lineHeight)
          .whereType<double>()
          .fold<double?>(null, (max, v) => max == null || v > max ? v : max),
      contrastMode: contrastMode,
      colorBlindCues: list.any((s) => s.colorBlindCues),
      decorativeBackgrounds: list.every((s) => s.decorativeBackgrounds),
      reduceMotion: list.any((s) => s.reduceMotion),
      noFlashing: list.any((s) => s.noFlashing),
      disableAutoplay: list.any((s) => s.disableAutoplay),
      focusMode: list.any((s) => s.focusMode),
      hideTimers: list.any((s) => s.hideTimers),
      oneItemPerScreen: list.any((s) => s.oneItemPerScreen),
      ttsEnabled: list.any((s) => s.ttsEnabled),
      readingHighlight: list.any((s) => s.readingHighlight),
      captions: list.any((s) => s.captions),
      visualCuesForSound: list.any((s) => s.visualCuesForSound),
      haptics: list.any((s) => s.haptics),
      reducedEmphasis: list.any((s) => s.reducedEmphasis),
      creamReadingBackground: list.any((s) => s.creamReadingBackground),
    );
  }

  A11ySettings copyWith({
    A11yFontFamily? fontFamily,
    double? textScale,
    bool? boldText,
    A11yLetterSpacing? letterSpacing,
    double? lineHeight,
    A11yContrastMode? contrastMode,
    bool? colorBlindCues,
    bool? decorativeBackgrounds,
    bool? reduceMotion,
    bool? noFlashing,
    bool? disableAutoplay,
    bool? focusMode,
    bool? hideTimers,
    bool? oneItemPerScreen,
    bool? ttsEnabled,
    bool? readingHighlight,
    bool? captions,
    bool? visualCuesForSound,
    bool? haptics,
    bool? reducedEmphasis,
    bool? creamReadingBackground,
  }) {
    return A11ySettings(
      fontFamily: fontFamily ?? this.fontFamily,
      textScale: textScale ?? this.textScale,
      boldText: boldText ?? this.boldText,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      lineHeight: lineHeight ?? this.lineHeight,
      contrastMode: contrastMode ?? this.contrastMode,
      colorBlindCues: colorBlindCues ?? this.colorBlindCues,
      decorativeBackgrounds:
          decorativeBackgrounds ?? this.decorativeBackgrounds,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      noFlashing: noFlashing ?? this.noFlashing,
      disableAutoplay: disableAutoplay ?? this.disableAutoplay,
      focusMode: focusMode ?? this.focusMode,
      hideTimers: hideTimers ?? this.hideTimers,
      oneItemPerScreen: oneItemPerScreen ?? this.oneItemPerScreen,
      ttsEnabled: ttsEnabled ?? this.ttsEnabled,
      readingHighlight: readingHighlight ?? this.readingHighlight,
      captions: captions ?? this.captions,
      visualCuesForSound: visualCuesForSound ?? this.visualCuesForSound,
      haptics: haptics ?? this.haptics,
      reducedEmphasis: reducedEmphasis ?? this.reducedEmphasis,
      creamReadingBackground:
          creamReadingBackground ?? this.creamReadingBackground,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontFamily': fontFamily.name,
      'textScale': textScale,
      'boldText': boldText,
      'letterSpacing': letterSpacing.name,
      'lineHeight': lineHeight,
      'contrastMode': contrastMode.name,
      'colorBlindCues': colorBlindCues,
      'decorativeBackgrounds': decorativeBackgrounds,
      'reduceMotion': reduceMotion,
      'noFlashing': noFlashing,
      'disableAutoplay': disableAutoplay,
      'focusMode': focusMode,
      'hideTimers': hideTimers,
      'oneItemPerScreen': oneItemPerScreen,
      'ttsEnabled': ttsEnabled,
      'readingHighlight': readingHighlight,
      'captions': captions,
      'visualCuesForSound': visualCuesForSound,
      'haptics': haptics,
      'reducedEmphasis': reducedEmphasis,
      'creamReadingBackground': creamReadingBackground,
    };
  }

  factory A11ySettings.fromJson(Map<String, dynamic> json) {
    return A11ySettings(
      fontFamily: A11yFontFamily.values.firstWhere(
        (v) => v.name == json['fontFamily'],
        orElse: () => A11yFontFamily.standard,
      ),
      textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
      boldText: json['boldText'] as bool? ?? false,
      letterSpacing: A11yLetterSpacing.values.firstWhere(
        (v) => v.name == json['letterSpacing'],
        orElse: () => A11yLetterSpacing.normal,
      ),
      lineHeight: (json['lineHeight'] as num?)?.toDouble(),
      contrastMode: A11yContrastMode.values.firstWhere(
        (v) => v.name == json['contrastMode'],
        orElse: () => A11yContrastMode.standard,
      ),
      colorBlindCues: json['colorBlindCues'] as bool? ?? false,
      decorativeBackgrounds: json['decorativeBackgrounds'] as bool? ?? true,
      reduceMotion: json['reduceMotion'] as bool? ?? false,
      noFlashing: json['noFlashing'] as bool? ?? false,
      disableAutoplay: json['disableAutoplay'] as bool? ?? false,
      focusMode: json['focusMode'] as bool? ?? false,
      hideTimers: json['hideTimers'] as bool? ?? false,
      oneItemPerScreen: json['oneItemPerScreen'] as bool? ?? false,
      ttsEnabled: json['ttsEnabled'] as bool? ?? false,
      readingHighlight: json['readingHighlight'] as bool? ?? false,
      captions: json['captions'] as bool? ?? false,
      visualCuesForSound: json['visualCuesForSound'] as bool? ?? false,
      haptics: json['haptics'] as bool? ?? false,
      reducedEmphasis: json['reducedEmphasis'] as bool? ?? false,
      creamReadingBackground: json['creamReadingBackground'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A11ySettings &&
        other.fontFamily == fontFamily &&
        other.textScale == textScale &&
        other.boldText == boldText &&
        other.letterSpacing == letterSpacing &&
        other.lineHeight == lineHeight &&
        other.contrastMode == contrastMode &&
        other.colorBlindCues == colorBlindCues &&
        other.decorativeBackgrounds == decorativeBackgrounds &&
        other.reduceMotion == reduceMotion &&
        other.noFlashing == noFlashing &&
        other.disableAutoplay == disableAutoplay &&
        other.focusMode == focusMode &&
        other.hideTimers == hideTimers &&
        other.oneItemPerScreen == oneItemPerScreen &&
        other.ttsEnabled == ttsEnabled &&
        other.readingHighlight == readingHighlight &&
        other.captions == captions &&
        other.visualCuesForSound == visualCuesForSound &&
        other.haptics == haptics &&
        other.reducedEmphasis == reducedEmphasis &&
        other.creamReadingBackground == creamReadingBackground;
  }

  @override
  int get hashCode => Object.hashAll([
    fontFamily,
    textScale,
    boldText,
    letterSpacing,
    lineHeight,
    contrastMode,
    colorBlindCues,
    decorativeBackgrounds,
    reduceMotion,
    noFlashing,
    disableAutoplay,
    focusMode,
    hideTimers,
    oneItemPerScreen,
    ttsEnabled,
    readingHighlight,
    captions,
    visualCuesForSound,
    haptics,
    reducedEmphasis,
    creamReadingBackground,
  ]);
}
