import 'package:flutter/foundation.dart';

import '../a11y_service.dart';
import '../config/a11y_configuration.dart';
import '../models/a11y_overrides.dart';
import '../models/a11y_profile.dart';
import '../models/a11y_record.dart';
import '../models/a11y_settings.dart';

class A11yCenterController extends ChangeNotifier {
  A11yCenterController({required this.service})
    : _pending = service.record,
      _applied = service.record {
    service.addListener(_onServiceChanged);
  }

  final A11yService service;

  A11yRecord _pending;
  A11yRecord _applied;

  A11yConfiguration get configuration => service.configuration;

  A11yRecord get pending => _pending;

  A11ySettings get pendingSettings => _pending.settings;

  List<A11yProfile> get profiles => _pending.profiles;

  bool get isDirty => _pending != _applied;

  bool has(A11yProfile profile) => _pending.has(profile);

  int get textScaleStep =>
      configuration.textScaleStepOf(pendingSettings.textScale);

  void toggleProfile(A11yProfile profile) =>
      _stage(_pending.toggleProfile(profile));

  void setTextScaleStep(int step) {
    final steps = configuration.textScaleSteps;
    if (step < 0 || step >= steps.length) return;

    setOverride(A11yOverrideKey.textScale, steps[step]);
  }

  void setContrastMode(A11yContrastMode mode) =>
      setOverride(A11yOverrideKey.contrastMode, mode);

  void setOverride<T>(A11yOverrideKey<T> key, T value) =>
      _stage(_pending.copyWith(overrides: _pending.overrides.set(key, value)));

  void clearOverride(A11yOverrideKey<Object?> key) =>
      _stage(_pending.copyWith(overrides: _pending.overrides.clear(key)));

  // O padrão não é o registro vazio: quem já passou pelo onboarding não deve
  // ser levado de volta pra ele por ter tocado em "voltar ao padrão".
  void restoreDefaults() =>
      _stage(A11yRecord(onboardingCompleted: _pending.onboardingCompleted));

  void discard() => _stage(_applied);

  Future<void> apply() async {
    if (!isDirty) return;

    final next = _pending;
    _applied = next;
    notifyListeners();

    await service.applyRecord(next);
  }

  Future<void> completeOnboarding() async {
    _stage(_pending.copyWith(onboardingCompleted: true));
    await apply();
  }

  void _stage(A11yRecord next) {
    if (next == _pending) return;

    _pending = next;
    notifyListeners();
  }

  // O serviço é a fonte da verdade; enquanto ninguém mexeu na folha, ele também
  // manda no pendente — outra superfície pode ter aplicado ajustes por fora.
  void _onServiceChanged() {
    final record = service.record;
    if (record == _applied) return;

    final wasClean = !isDirty;
    _applied = record;
    if (wasClean) _pending = record;

    notifyListeners();
  }

  @override
  void dispose() {
    service.removeListener(_onServiceChanged);
    super.dispose();
  }
}
