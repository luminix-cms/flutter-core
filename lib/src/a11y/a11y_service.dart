import 'package:flutter/foundation.dart';

import 'a11y_store.dart';
import 'config/a11y_configuration.dart';
import 'models/a11y_overrides.dart';
import 'models/a11y_profile.dart';
import 'models/a11y_record.dart';
import 'models/a11y_settings.dart';

class A11yService extends ChangeNotifier {
  A11yService({
    this.configuration = const A11yConfiguration(),
    A11yStore? store,
  }) : _store = store ?? A11yStore();

  final A11yConfiguration configuration;
  final A11yStore _store;

  A11yRecord _record = const A11yRecord();
  Object? _identity;
  bool _loaded = false;

  A11yRecord get record => _record;

  Object? get identity => _identity;

  bool get isLoaded => _loaded;

  bool get onboardingCompleted => _record.onboardingCompleted;

  List<A11yProfile> get profiles => _record.profiles;

  A11ySettings get settings =>
      configuration.enabled ? _record.settings : A11ySettings.defaults;

  int get textScaleStep => configuration.textScaleStepOf(settings.textScale);

  Future<void> load() async {
    if (!configuration.enabled) {
      _loaded = true;
      return;
    }

    _record = await _store.loadDevice() ?? const A11yRecord();
    _loaded = true;
    notifyListeners();
  }

  Future<void> bindToIdentity(Object? id) async {
    if (!configuration.enabled) return;
    if (configuration.scope != A11yScopeMode.user) return;
    if (id == _identity) return;

    if (id == null) {
      _identity = null;
      _record = await _store.loadDevice() ?? const A11yRecord();
      notifyListeners();
      return;
    }

    final stored = await _store.loadUser(id);
    _identity = id;

    if (stored == null) {
      await _store.saveUser(id, _record);
    } else {
      _record = stored;
    }

    notifyListeners();
  }

  Future<void> toggleProfile(A11yProfile profile) =>
      _apply(_record.toggleProfile(profile));

  Future<void> setProfiles(Iterable<A11yProfile> profiles) =>
      _apply(_record.withProfiles(profiles));

  Future<void> setOverride<T>(A11yOverrideKey<T> key, T value) =>
      _apply(_record.copyWith(overrides: _record.overrides.set(key, value)));

  Future<void> clearOverride(A11yOverrideKey<Object?> key) =>
      _apply(_record.copyWith(overrides: _record.overrides.clear(key)));

  Future<void> applyRecord(A11yRecord record) => _apply(record);

  Future<void> completeOnboarding() =>
      _apply(_record.copyWith(onboardingCompleted: true));

  Future<void> reset() =>
      _apply(A11yRecord(onboardingCompleted: _record.onboardingCompleted));

  Future<void> _apply(A11yRecord next) async {
    if (next == _record) return;

    _record = next;
    notifyListeners();

    await _persist();
  }

  Future<void> _persist() {
    final persisted = configuration.persistManualOverrides
        ? _record
        : _record.copyWith(overrides: const A11yOverrides.empty());

    final id = _identity;
    return id == null
        ? _store.saveDevice(persisted)
        : _store.saveUser(id, persisted);
  }
}
