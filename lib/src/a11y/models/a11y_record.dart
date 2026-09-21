import 'a11y_overrides.dart';
import 'a11y_profile.dart';
import 'a11y_settings.dart';

class A11yRecord {
  const A11yRecord({
    this.profiles = const [],
    this.overrides = const A11yOverrides.empty(),
    this.onboardingCompleted = false,
    this.updatedAt,
  });

  final List<A11yProfile> profiles;
  final A11yOverrides overrides;
  final bool onboardingCompleted;
  final DateTime? updatedAt;

  A11ySettings get settings =>
      overrides.applyTo(a11ySettingsForProfiles(profiles));

  bool get isPristine =>
      profiles.isEmpty && overrides.isEmpty && !onboardingCompleted;

  bool has(A11yProfile profile) => profiles.contains(profile);

  A11yRecord withProfiles(Iterable<A11yProfile> profiles) {
    return copyWith(
      profiles: profiles.toSet().toList()
        ..sort((a, b) => a.index.compareTo(b.index)),
    );
  }

  A11yRecord toggleProfile(A11yProfile profile) {
    return withProfiles(
      has(profile)
          ? profiles.where((current) => current != profile)
          : [...profiles, profile],
    );
  }

  A11yRecord copyWith({
    List<A11yProfile>? profiles,
    A11yOverrides? overrides,
    bool? onboardingCompleted,
    DateTime? updatedAt,
  }) {
    return A11yRecord(
      profiles: profiles ?? this.profiles,
      overrides: overrides ?? this.overrides,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profiles': profiles.map((profile) => profile.name).toList(),
      'overrides': overrides.toJson(),
      'onboardingCompleted': onboardingCompleted,
      'updatedAt': updatedAt?.toUtc().toIso8601String(),
    };
  }

  factory A11yRecord.fromJson(Map<dynamic, dynamic> json) {
    final updatedAt = json['updatedAt'];

    return A11yRecord(
      profiles: a11yProfilesFromNames(json['profiles']),
      overrides: A11yOverrides.fromJson(json['overrides']),
      onboardingCompleted: json['onboardingCompleted'] == true,
      updatedAt: updatedAt is String ? DateTime.tryParse(updatedAt) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! A11yRecord ||
        other.onboardingCompleted != onboardingCompleted ||
        other.overrides != overrides ||
        other.profiles.length != profiles.length) {
      return false;
    }
    for (var i = 0; i < profiles.length; i++) {
      if (other.profiles[i] != profiles[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(profiles), overrides, onboardingCompleted);

  @override
  String toString() =>
      'A11yRecord(profiles: ${profiles.map((p) => p.name).toList()}, '
      'overrides: ${overrides.toJson()}, '
      'onboardingCompleted: $onboardingCompleted)';
}
