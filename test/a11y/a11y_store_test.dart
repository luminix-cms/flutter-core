import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luminix_flutter/accessibility.dart';
import 'package:luminix_flutter/src/a11y/a11y_store.dart';
import 'package:luminix_flutter/src/utils/prefs_file.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<FlutterErrorDetails>> _capturandoErros(
  Future<void> Function() body,
) async {
  final capturados = <FlutterErrorDetails>[];
  final anterior = FlutterError.onError;
  FlutterError.onError = capturados.add;

  try {
    await body();
  } finally {
    FlutterError.onError = anterior;
  }

  return capturados;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<String?> lerBruto(String key) async {
    return (await SharedPreferences.getInstance()).getString(key);
  }

  group('A11yStore — chaves', () {
    test('não colidem com as do base_um_app', () {
      expect(A11yStore.deviceKey, 'luminix_a11y_device');
      expect(A11yStore.userKey(42), 'luminix_a11y_user_42');
    });
  });

  group('A11yStore — ida e volta', () {
    test('registro ausente devolve nulo, não um registro vazio', () async {
      expect(await A11yStore().loadDevice(), isNull);
      expect(await A11yStore().loadUser(7), isNull);
    });

    test('grava e relê o registro do aparelho', () async {
      final store = A11yStore();
      final record = const A11yRecord(onboardingCompleted: true)
          .withProfiles([A11yProfile.dyslexia, A11yProfile.epilepsy])
          .copyWith(
            overrides: const A11yOverrides.empty().set(
              A11yOverrideKey.textScale,
              1.3,
            ),
          );

      await store.saveDevice(record);

      expect(await store.loadDevice(), record);
    });

    test('aparelho e usuário são registros independentes', () async {
      final store = A11yStore();

      await store.saveDevice(
        const A11yRecord().withProfiles([A11yProfile.lowVision]),
      );
      await store.saveUser(
        7,
        const A11yRecord().withProfiles([A11yProfile.adhd]),
      );

      expect((await store.loadDevice())!.profiles, [A11yProfile.lowVision]);
      expect((await store.loadUser(7))!.profiles, [A11yProfile.adhd]);
    });

    test('grava a versão do schema e carimba o horário', () async {
      await A11yStore().saveDevice(const A11yRecord());

      final bruto =
          jsonDecode((await lerBruto(A11yStore.deviceKey))!)
              as Map<String, dynamic>;

      expect(bruto['version'], A11yStore.schemaVersion);
      expect(DateTime.tryParse(bruto['updatedAt'] as String), isNotNull);
    });

    test('clear apaga só a chave pedida', () async {
      final store = A11yStore();
      await store.saveDevice(const A11yRecord(onboardingCompleted: true));
      await store.saveUser(7, const A11yRecord(onboardingCompleted: true));

      await store.clearUser(7);

      expect(await store.loadUser(7), isNull);
      expect(await store.loadDevice(), isNotNull);
    });
  });

  group('A11yStore — degradação', () {
    test('versão futura é descartada em silêncio', () async {
      SharedPreferences.setMockInitialValues({
        A11yStore.deviceKey: jsonEncode({
          'version': A11yStore.schemaVersion + 1,
          'profiles': ['dyslexia'],
        }),
      });

      A11yRecord? lido;
      final erros = await _capturandoErros(() async {
        lido = await A11yStore().loadDevice();
      });

      expect(lido, isNull);
      expect(erros, isEmpty);
    });

    test('versão ausente é descartada', () async {
      SharedPreferences.setMockInitialValues({
        A11yStore.deviceKey: jsonEncode({
          'profiles': ['dyslexia'],
        }),
      });

      expect(await A11yStore().loadDevice(), isNull);
    });

    test('json malformado degrada e reporta, sem lançar', () async {
      SharedPreferences.setMockInitialValues({
        A11yStore.deviceKey: 'isso não é json',
      });

      A11yRecord? lido;
      final erros = await _capturandoErros(() async {
        lido = await A11yStore().loadDevice();
      });

      expect(lido, isNull);
      expect(erros, hasLength(1));
      expect(erros.single.exception, isFormatException);
    });

    test('um array guardado no lugar do mapa não lança TypeError', () async {
      SharedPreferences.setMockInitialValues({
        A11yStore.deviceKey: jsonEncode(['dyslexia']),
      });

      A11yRecord? lido;
      final erros = await _capturandoErros(() async {
        lido = await A11yStore().loadDevice();
      });

      expect(lido, isNull);
      expect(erros, hasLength(1));
      expect(erros.single.exception, isA<TypeError>());
    });

    test('perfil desconhecido é ignorado, o resto sobrevive', () async {
      SharedPreferences.setMockInitialValues({
        A11yStore.deviceKey: jsonEncode({
          'version': 1,
          'profiles': ['dyslexia', 'telepatia'],
          'overrides': {'textScale': 1.3, 'modoTurbo': true},
          'onboardingCompleted': true,
        }),
      });

      final lido = await A11yStore().loadDevice();

      expect(lido!.profiles, [A11yProfile.dyslexia]);
      expect(lido.overrides.length, 1);
      expect(lido.onboardingCompleted, isTrue);
    });

    test('registro sem campos volta pristino', () async {
      SharedPreferences.setMockInitialValues({
        A11yStore.deviceKey: jsonEncode({'version': 1}),
      });

      final lido = await A11yStore().loadDevice();

      expect(lido, isNotNull);
      expect(lido!.isPristine, isTrue);
      expect(lido.settings, A11ySettings.defaults);
    });

    test('falha de escrita é reportada, não propagada', () async {
      final store = A11yStore(storage: (_) => _SavedMapQueFalha());

      final erros = await _capturandoErros(() async {
        await store.saveDevice(const A11yRecord());
      });

      expect(erros, hasLength(1));
      expect(erros.single.exception, isStateError);
    });
  });

  group('A11yRecord', () {
    test('resolve os ajustes combinando perfis e overrides', () async {
      final record = const A11yRecord()
          .withProfiles([A11yProfile.lowVision])
          .copyWith(
            overrides: const A11yOverrides.empty().set(
              A11yOverrideKey.textScale,
              1.0,
            ),
          );

      expect(record.settings.textScale, 1.0);
      expect(record.settings.contrastMode, A11yContrastMode.highContrast);
    });

    test('toggleProfile liga e desliga mantendo a ordem canônica', () {
      final record = const A11yRecord()
          .toggleProfile(A11yProfile.dyslexia)
          .toggleProfile(A11yProfile.colorBlindness);

      expect(record.profiles, [
        A11yProfile.colorBlindness,
        A11yProfile.dyslexia,
      ]);
      expect(record.toggleProfile(A11yProfile.dyslexia).profiles, [
        A11yProfile.colorBlindness,
      ]);
    });

    test('withProfiles descarta repetições', () {
      final record = const A11yRecord().withProfiles([
        A11yProfile.adhd,
        A11yProfile.adhd,
      ]);

      expect(record.profiles, [A11yProfile.adhd]);
    });

    test('o carimbo de horário não entra na igualdade', () {
      final agora = DateTime.utc(2026, 8, 31);
      const base = A11yRecord(onboardingCompleted: true);

      expect(base.copyWith(updatedAt: agora), base);
      expect(base.copyWith(updatedAt: agora).hashCode, base.hashCode);
    });
  });
}

class _SavedMapQueFalha implements SavedMap {
  @override
  String get name => 'falha';

  @override
  Future<Map<String, dynamic>?> load() async => throw StateError('sem disco');

  @override
  Future<void> save(Map<String, dynamic> data) async =>
      throw StateError('sem disco');

  @override
  Future<void> clear() async => throw StateError('sem disco');
}
