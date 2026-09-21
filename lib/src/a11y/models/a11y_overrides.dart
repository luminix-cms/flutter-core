import 'a11y_settings.dart';

class _A11yDecoded<T> {
  const _A11yDecoded(this.value);
  final T value;
}

class A11yOverrideKey<T> {
  const A11yOverrideKey._(this.name, this._encode, this._decode);

  final String name;
  final Object? Function(Object? value) _encode;
  final _A11yDecoded<T>? Function(Object? raw) _decode;

  static A11yOverrideKey<T> _enumKey<T extends Enum>(
    String name,
    List<T> values,
  ) {
    return A11yOverrideKey<T>._(name, (value) => (value as Enum).name, (raw) {
      for (final value in values) {
        if (value == raw || value.name == raw) return _A11yDecoded(value);
      }
      return null;
    });
  }

  static A11yOverrideKey<bool> _boolKey(String name) {
    return A11yOverrideKey<bool>._(
      name,
      (value) => value,
      (raw) => raw is bool ? _A11yDecoded(raw) : null,
    );
  }

  static A11yOverrideKey<double> _doubleKey(String name) {
    return A11yOverrideKey<double>._(
      name,
      (value) => value,
      (raw) => raw is num ? _A11yDecoded(raw.toDouble()) : null,
    );
  }

  static A11yOverrideKey<double?> _nullableDoubleKey(String name) {
    return A11yOverrideKey<double?>._(
      name,
      (value) => value,
      (raw) => switch (raw) {
        null => const _A11yDecoded(null),
        num() => _A11yDecoded(raw.toDouble()),
        _ => null,
      },
    );
  }

  static final fontFamily = _enumKey('fontFamily', A11yFontFamily.values);
  static final textScale = _doubleKey('textScale');
  static final boldText = _boolKey('boldText');
  static final letterSpacing = _enumKey(
    'letterSpacing',
    A11yLetterSpacing.values,
  );
  static final lineHeight = _nullableDoubleKey('lineHeight');
  static final contrastMode = _enumKey('contrastMode', A11yContrastMode.values);
  static final colorBlindCues = _boolKey('colorBlindCues');
  static final decorativeBackgrounds = _boolKey('decorativeBackgrounds');
  static final reduceMotion = _boolKey('reduceMotion');
  static final noFlashing = _boolKey('noFlashing');
  static final disableAutoplay = _boolKey('disableAutoplay');
  static final focusMode = _boolKey('focusMode');
  static final hideTimers = _boolKey('hideTimers');
  static final oneItemPerScreen = _boolKey('oneItemPerScreen');
  static final ttsEnabled = _boolKey('ttsEnabled');
  static final readingHighlight = _boolKey('readingHighlight');
  static final captions = _boolKey('captions');
  static final visualCuesForSound = _boolKey('visualCuesForSound');
  static final haptics = _boolKey('haptics');
  static final reducedEmphasis = _boolKey('reducedEmphasis');
  static final creamReadingBackground = _boolKey('creamReadingBackground');

  static final List<A11yOverrideKey<Object?>> values = [
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
  ];

  @override
  String toString() => 'A11yOverrideKey($name)';
}

class A11yOverrides {
  const A11yOverrides._(this._values);

  const A11yOverrides.empty() : _values = const {};

  final Map<String, Object?> _values;

  bool get isEmpty => _values.isEmpty;

  bool get isNotEmpty => _values.isNotEmpty;

  int get length => _values.length;

  Iterable<String> get keys => _values.keys;

  bool has(A11yOverrideKey<Object?> key) => _values.containsKey(key.name);

  T? read<T>(A11yOverrideKey<T> key) => _values[key.name] as T?;

  A11yOverrides set<T>(A11yOverrideKey<T> key, T value) {
    return A11yOverrides._({..._values, key.name: value});
  }

  A11yOverrides clear(A11yOverrideKey<Object?> key) {
    if (!has(key)) return this;
    return A11yOverrides._({..._values}..remove(key.name));
  }

  A11yOverrides mergedWith(A11yOverrides other) {
    if (other.isEmpty) return this;
    return A11yOverrides._({..._values, ...other._values});
  }

  A11ySettings applyTo(A11ySettings base) {
    if (isEmpty) return base;
    return A11ySettings.fromJson({...base.toJson(), ...toJson()});
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    for (final key in A11yOverrideKey.values) {
      if (!_values.containsKey(key.name)) continue;
      json[key.name] = key._encode(_values[key.name]);
    }
    return json;
  }

  factory A11yOverrides.fromJson(Object? json) {
    if (json is! Map) return const A11yOverrides.empty();

    final values = <String, Object?>{};
    for (final key in A11yOverrideKey.values) {
      if (!json.containsKey(key.name)) continue;
      final decoded = key._decode(json[key.name]);
      if (decoded == null) continue;
      values[key.name] = decoded.value;
    }
    return A11yOverrides._(values);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! A11yOverrides || other._values.length != _values.length) {
      return false;
    }
    for (final entry in _values.entries) {
      if (!other._values.containsKey(entry.key)) return false;
      if (other._values[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAllUnordered(
    _values.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );

  @override
  String toString() => 'A11yOverrides(${toJson()})';
}
