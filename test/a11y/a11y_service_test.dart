import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/a11y/a11y_store.dart';
import 'package:luminix_flutter/src/luminix_service_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

A11yService _service({
  A11yConfiguration configuration = const A11yConfiguration(),
}) {
  return A11yService(configuration: configuration, store: A11yStore());
}

Application _app({A11yConfiguration? a11y}) {
  return Application()
    ..withProviders([
      LuminixServiceProvider.new,
      LuminixAccessibilityServiceProvider.new,
    ])
    ..withConfiguration(AppConfiguration(a11y: a11y));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(GetIt.instance.reset);

  group('A11yService — estado', () {
    test('começa descarregado e nos padrões', () {
      final service = _service();

      expect(service.isLoaded, isFalse);
      expect(service.settings, A11ySettings.defaults);
      expect(service.profiles, isEmpty);
    });

    test('load traz o registro do aparelho', () async {
      await A11yStore().saveDevice(
        const A11yRecord().withProfiles([A11yProfile.dyslexia]),
      );

      final service = _service();
      await service.load();

      expect(service.isLoaded, isTrue);
      expect(service.profiles, [A11yProfile.dyslexia]);
      expect(service.settings.fontFamily, A11yFontFamily.openDyslexic);
    });

    test('desligado ignora o registro guardado', () async {
      await A11yStore().saveDevice(
        const A11yRecord().withProfiles([A11yProfile.lowVision]),
      );

      final service = _service(
        configuration: const A11yConfiguration(enabled: false),
      );
      await service.load();

      expect(service.settings, A11ySettings.defaults);
    });

    test('toggleProfile notifica uma vez e persiste', () async {
      final service = _service();
      await service.load();

      var avisos = 0;
      service.addListener(() => avisos++);

      await service.toggleProfile(A11yProfile.adhd);

      expect(avisos, 1);
      expect(service.profiles, [A11yProfile.adhd]);
      expect((await A11yStore().loadDevice())!.profiles, [A11yProfile.adhd]);
    });

    test('não notifica quando o registro não muda', () async {
      final service = _service();
      await service.load();
      await service.setProfiles([A11yProfile.adhd]);

      var avisos = 0;
      service.addListener(() => avisos++);

      await service.setProfiles([A11yProfile.adhd]);

      expect(avisos, 0);
    });

    test('override manual vence o perfil', () async {
      final service = _service();
      await service.load();
      await service.setProfiles([A11yProfile.lowVision]);

      await service.setOverride(A11yOverrideKey.textScale, 1.0);

      expect(service.settings.textScale, 1.0);
      expect(service.settings.contrastMode, A11yContrastMode.highContrast);
    });

    test('clearOverride devolve o campo ao perfil', () async {
      final service = _service();
      await service.load();
      await service.setProfiles([A11yProfile.lowVision]);
      await service.setOverride(A11yOverrideKey.textScale, 1.0);

      await service.clearOverride(A11yOverrideKey.textScale);

      expect(service.settings.textScale, 1.5);
    });

    test('reset limpa os ajustes e preserva o onboarding', () async {
      final service = _service();
      await service.load();
      await service.completeOnboarding();
      await service.setProfiles([A11yProfile.dyslexia]);

      await service.reset();

      expect(service.profiles, isEmpty);
      expect(service.onboardingCompleted, isTrue);
      expect(service.settings, A11ySettings.defaults);
    });

    test('persistManualOverrides desligado não grava o override', () async {
      final service = _service(
        configuration: const A11yConfiguration(persistManualOverrides: false),
      );
      await service.load();
      await service.setProfiles([A11yProfile.adhd]);
      await service.setOverride(A11yOverrideKey.textScale, 1.5);

      final guardado = await A11yStore().loadDevice();

      expect(service.settings.textScale, 1.5);
      expect(guardado!.overrides.isEmpty, isTrue);
      expect(guardado.profiles, [A11yProfile.adhd]);
    });
  });

  group('A11yService — escopo por usuário', () {
    A11yService userScoped() => _service(
      configuration: const A11yConfiguration(scope: A11yScopeMode.user),
    );

    test('escopo de aparelho ignora a identidade', () async {
      final service = _service();
      await service.load();

      await service.bindToIdentity(7);

      expect(service.identity, isNull);
    });

    test('usuário sem registro herda o do aparelho e o grava', () async {
      await A11yStore().saveDevice(
        const A11yRecord().withProfiles([A11yProfile.dyslexia]),
      );

      final service = userScoped();
      await service.load();
      await service.bindToIdentity(7);

      expect(service.identity, 7);
      expect(service.profiles, [A11yProfile.dyslexia]);
      expect((await A11yStore().loadUser(7))!.profiles, [A11yProfile.dyslexia]);
    });

    test('usuário com registro usa o dele, não o do aparelho', () async {
      final store = A11yStore();
      await store.saveDevice(
        const A11yRecord().withProfiles([A11yProfile.dyslexia]),
      );
      await store.saveUser(
        7,
        const A11yRecord().withProfiles([A11yProfile.epilepsy]),
      );

      final service = userScoped();
      await service.load();
      await service.bindToIdentity(7);

      expect(service.profiles, [A11yProfile.epilepsy]);
    });

    test(
      'depois de ligar a identidade, grava sob a chave do usuário',
      () async {
        final service = userScoped();
        await service.load();
        await service.bindToIdentity(7);

        await service.setProfiles([A11yProfile.adhd]);

        expect((await A11yStore().loadUser(7))!.profiles, [A11yProfile.adhd]);
        expect((await A11yStore().loadDevice())?.profiles ?? [], isEmpty);
      },
    );

    test('sair volta para o registro do aparelho', () async {
      await A11yStore().saveDevice(
        const A11yRecord().withProfiles([A11yProfile.dyslexia]),
      );

      final service = userScoped();
      await service.load();
      await service.bindToIdentity(7);
      await service.setProfiles([A11yProfile.adhd]);

      await service.bindToIdentity(null);

      expect(service.identity, isNull);
      expect(service.profiles, [A11yProfile.dyslexia]);
    });

    test('religar na mesma identidade não recarrega', () async {
      final service = userScoped();
      await service.load();
      await service.bindToIdentity(7);
      await service.setProfiles([A11yProfile.adhd]);

      var avisos = 0;
      service.addListener(() => avisos++);
      await service.bindToIdentity(7);

      expect(avisos, 0);
      expect(service.profiles, [A11yProfile.adhd]);
    });
  });

  group('LuminixAccessibilityServiceProvider', () {
    test('sem a11y na configuração o serviço fica inerte', () async {
      await A11yStore().saveDevice(
        const A11yRecord().withProfiles([A11yProfile.lowVision]),
      );

      final app = _app();
      await app.create();

      final service = app.make('a11y') as A11yService;

      expect(service.isLoaded, isFalse);
      expect(service.settings, A11ySettings.defaults);
    });

    test('com a11y o boot só resolve depois de carregar', () async {
      await A11yStore().saveDevice(
        const A11yRecord().withProfiles([A11yProfile.dyslexia]),
      );

      final app = _app(a11y: const A11yConfiguration());
      await app.create();

      final service = app.make('a11y') as A11yService;

      expect(service.isLoaded, isTrue);
      expect(service.profiles, [A11yProfile.dyslexia]);
    });

    test('a11y desligado explicitamente não carrega nada', () async {
      await A11yStore().saveDevice(
        const A11yRecord().withProfiles([A11yProfile.lowVision]),
      );

      final app = _app(a11y: const A11yConfiguration(enabled: false));
      await app.create();

      expect((app.make('a11y') as A11yService).isLoaded, isFalse);
    });

    test('escopo de usuário liga na identidade do auth', () async {
      final app = _app(
        a11y: const A11yConfiguration(
          scope: A11yScopeMode.user,
          awaitUserScopeOnBoot: true,
        ),
      );
      await app.create();

      final service = app.make('a11y') as A11yService;

      expect(service.isLoaded, isTrue);
      expect(service.identity, isNull);
    });

    test('dispose da Application descarta o serviço', () async {
      final app = _app(a11y: const A11yConfiguration());
      await app.create();

      final service = app.make('a11y') as A11yService;
      app.dispose();

      expect(() => service.addListener(() {}), throwsA(isA<FlutterError>()));
    });
  });
}
