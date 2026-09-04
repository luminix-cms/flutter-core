import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luminix_flutter/accessibility.dart';
import 'package:luminix_flutter/src/a11y/a11y_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

const A11yStrings _strings = A11yStrings();

const MediaQueryData _apertado = MediaQueryData(
  size: Size(320, 568),
  textScaler: TextScaler.linear(2.0),
  boldText: true,
);

Future<A11yService> _servico({
  A11yConfiguration configuration = const A11yConfiguration(),
  List<A11yProfile> perfis = const [],
}) async {
  final service = A11yService(configuration: configuration, store: A11yStore());
  await service.load();
  if (perfis.isNotEmpty) await service.setProfiles(perfis);
  return service;
}

Widget _sob({
  required A11yService service,
  required Widget child,
  MediaQueryData? media,
}) {
  final app = MaterialApp(
    builder: A11yScope.builder(service: service),
    home: Scaffold(body: child),
  );

  return media == null ? app : MediaQuery(data: media, child: app);
}

Future<void> _abrirCentral(WidgetTester tester, A11yService service) async {
  await tester.pumpWidget(
    _sob(service: service, child: const Text('conteúdo')),
  );
  A11yScopeData.of(tester.element(find.text('conteúdo'))).openCenter();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('A11yCenterController — pendente até aplicar', () {
    test('marcar perfil não mexe no serviço antes do aplicar', () async {
      final service = await _servico();
      final controller = A11yCenterController(service: service);

      controller.toggleProfile(A11yProfile.lowVision);

      expect(controller.isDirty, isTrue);
      expect(controller.pendingSettings.textScale, 1.5);
      expect(service.profiles, isEmpty);
      expect(service.settings.textScale, 1.0);

      await controller.apply();

      expect(controller.isDirty, isFalse);
      expect(service.profiles, [A11yProfile.lowVision]);
      expect(service.settings.textScale, 1.5);

      controller.dispose();
    });

    test('descartar volta ao que o serviço tem', () async {
      final service = await _servico(perfis: [A11yProfile.dyslexia]);
      final controller = A11yCenterController(service: service);

      controller.toggleProfile(A11yProfile.epilepsy);
      controller.discard();

      expect(controller.isDirty, isFalse);
      expect(controller.profiles, [A11yProfile.dyslexia]);

      controller.dispose();
    });

    test('voltar ao padrão preserva o onboarding já concluído', () async {
      final service = await _servico(perfis: [A11yProfile.lowVision]);
      await service.completeOnboarding();

      final controller = A11yCenterController(service: service);
      controller.restoreDefaults();

      expect(controller.profiles, isEmpty);
      expect(controller.pending.onboardingCompleted, isTrue);

      controller.dispose();
    });

    test('a escala de texto anda pelos passos da configuração', () async {
      final service = await _servico();
      final controller = A11yCenterController(service: service);

      controller.setTextScaleStep(3);
      expect(controller.pendingSettings.textScale, 1.5);
      expect(controller.textScaleStep, 3);

      controller.setTextScaleStep(9);
      expect(controller.pendingSettings.textScale, 1.5);

      controller.dispose();
    });

    test('ajuste vindo de fora alcança o pendente ainda limpo', () async {
      final service = await _servico();
      final controller = A11yCenterController(service: service);

      await service.toggleProfile(A11yProfile.adhd);

      expect(controller.profiles, [A11yProfile.adhd]);
      expect(controller.isDirty, isFalse);

      controller.dispose();
    });

    test('ajuste vindo de fora não atropela a seleção em curso', () async {
      final service = await _servico();
      final controller = A11yCenterController(service: service);

      controller.toggleProfile(A11yProfile.dyslexia);
      await service.toggleProfile(A11yProfile.adhd);

      expect(controller.profiles, [A11yProfile.dyslexia]);
      expect(controller.isDirty, isTrue);

      controller.dispose();
    });
  });

  group('A11yCenterSheet', () {
    testWidgets('o toque em aplicar é o que persiste a escolha', (
      tester,
    ) async {
      final service = await _servico();
      await _abrirCentral(tester, service);

      await tester.tap(find.text(_strings.lowVisionTitle));
      await tester.pump();

      expect(service.profiles, isEmpty);

      await tester.tap(find.text(_strings.applyLabel));
      await tester.pumpAndSettle();

      expect(service.profiles, [A11yProfile.lowVision]);
      expect(find.byType(A11yCenterSheet), findsNothing);
    });

    testWidgets('a prévia acompanha o pendente, não o aplicado', (
      tester,
    ) async {
      final service = await _servico();
      await _abrirCentral(tester, service);

      await tester.tap(find.text(_strings.lowVisionTitle));
      await tester.pumpAndSettle();

      final preview = tester.widget<A11yPreviewCard>(
        find.byType(A11yPreviewCard),
      );

      expect(preview.settings.textScale, 1.5);
      expect(service.settings.textScale, 1.0);
    });

    testWidgets('a prévia limita a escala em previewMaxTextScale', (
      tester,
    ) async {
      final service = await _servico();

      await tester.pumpWidget(
        _sob(service: service, media: _apertado, child: const Text('conteúdo')),
      );
      A11yScopeData.of(tester.element(find.text('conteúdo'))).openCenter();
      await tester.pumpAndSettle();

      final amostra = find.descendant(
        of: find.byType(A11yPreviewCard),
        matching: find.text(_strings.previewSample),
      );

      // A folha inteira anda em 2.0 (o teto da configuração); só a prévia é
      // contida em 1.6, senão o cartão estoura a própria caixa.
      expect(
        MediaQuery.of(
          tester.element(find.byType(A11yCenterSheet)),
        ).textScaler.scale(10),
        20.0,
      );
      expect(MediaQuery.of(tester.element(amostra)).textScaler.scale(10), 16.0);
    });

    testWidgets('em 2.0 e 320 dp a folha não estoura e o rodapé responde', (
      tester,
    ) async {
      final service = await _servico();

      await tester.pumpWidget(
        _sob(service: service, media: _apertado, child: const Text('conteúdo')),
      );
      A11yScopeData.of(tester.element(find.text('conteúdo'))).openCenter();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      await tester.tap(find.text(_strings.resetLabel));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('respeita os alvos de toque de 48 dp', (tester) async {
      final handle = tester.ensureSemantics();
      final service = await _servico();
      await _abrirCentral(tester, service);

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('o cartão de perfil anuncia botão, seleção e toque', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final service = await _servico();
      await _abrirCentral(tester, service);

      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.text(_strings.dyslexiaTitle),
            matching: find.byType(A11yProfileCard),
          ),
        ),
        isSemantics(
          label: _strings.dyslexiaTitle,
          hint: _strings.dyslexiaSubtitle,
          isButton: true,
          isSelected: false,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.text(_strings.dyslexiaTitle));
      await tester.pump();

      expect(
        tester.getSemantics(
          find.ancestor(
            of: find.text(_strings.dyslexiaTitle),
            matching: find.byType(A11yProfileCard),
          ),
        ),
        isSemantics(isSelected: true),
      );

      handle.dispose();
    });

    testWidgets('os builders da configuração substituem cartão e prévia', (
      tester,
    ) async {
      final service = await _servico(
        configuration: A11yConfiguration(
          profileCardBuilder: (context, profile, selected, onToggle) =>
              A11yLabeledButton(
                label: 'cartão ${profile.name}',
                onPressed: onToggle,
                child: Text('cartão ${profile.name}'),
              ),
          previewBuilder: (context, pending) => const Text('prévia do app'),
        ),
      );

      await _abrirCentral(tester, service);

      expect(find.byType(A11yProfileCard), findsNothing);
      expect(find.byType(A11yPreviewCard), findsNothing);
      expect(find.text('cartão lowVision'), findsOneWidget);
      expect(find.text('prévia do app'), findsOneWidget);
    });

    testWidgets('showA11yCenter abre a folha por rota', (tester) async {
      final service = await _servico();

      await tester.pumpWidget(
        _sob(
          service: service,
          child: Builder(
            builder: (context) => A11yLabeledButton(
              label: 'abrir',
              onPressed: () => showA11yCenter(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      expect(find.byType(A11yCenterSheet), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('A11yOnboardingScreen', () {
    testWidgets('continuar aplica a escolha e conclui o onboarding', (
      tester,
    ) async {
      final service = await _servico();
      var terminou = false;

      await tester.pumpWidget(
        _sob(
          service: service,
          child: A11yOnboardingScreen(
            service: service,
            onFinished: () => terminou = true,
          ),
        ),
      );

      await tester.tap(find.text(_strings.lowVisionTitle));
      await tester.pump();
      await tester.tap(find.text(_strings.onboardingContinueLabel));
      await tester.pumpAndSettle();

      expect(service.profiles, [A11yProfile.lowVision]);
      expect(service.onboardingCompleted, isTrue);
      expect(terminou, isTrue);
    });

    testWidgets('pular conclui sem levar a seleção pendente', (tester) async {
      final service = await _servico();

      await tester.pumpWidget(
        _sob(
          service: service,
          child: A11yOnboardingScreen(service: service),
        ),
      );

      await tester.tap(find.text(_strings.dyslexiaTitle));
      await tester.pump();
      await tester.tap(find.text(_strings.onboardingSkipLabel));
      await tester.pumpAndSettle();

      expect(service.profiles, isEmpty);
      expect(service.onboardingCompleted, isTrue);
    });

    testWidgets('em 2.0 e 320 dp o onboarding não estoura', (tester) async {
      final handle = tester.ensureSemantics();
      final service = await _servico();

      await tester.pumpWidget(
        _sob(
          service: service,
          media: _apertado,
          child: A11yOnboardingScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });

    testWidgets('sem fundos decorativos o padrão de pontos some', (
      tester,
    ) async {
      final service = await _servico(perfis: [A11yProfile.adhd]);

      await tester.pumpWidget(
        _sob(
          service: service,
          child: A11yOnboardingScreen(service: service),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomPaint), findsWidgets);
      expect(
        A11yThemeExtension.of(
          tester.element(find.byType(A11yOnboardingScreen)),
        ).decorativeBackgrounds,
        isFalse,
      );
    });
  });

  group('A11ySwitchTile', () {
    testWidgets('anuncia estado alternável e um único nó tocável', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var ligado = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => A11ySwitchTile(
                label: 'Reduzir animações',
                description: 'Menos movimento na tela',
                value: ligado,
                onChanged: (value) => setState(() => ligado = value),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(A11ySwitchTile)),
        isSemantics(
          label: 'Reduzir animações',
          hint: 'Menos movimento na tela',
          isButton: true,
          isToggled: false,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.byType(A11ySwitchTile));
      await tester.pumpAndSettle();

      expect(ligado, isTrue);
      expect(
        tester.getSemantics(find.byType(A11ySwitchTile)),
        isSemantics(isToggled: true),
      );

      handle.dispose();
    });
  });

  group('A11yFab', () {
    testWidgets('é um alvo de 56 dp rotulado, sem Tooltip', (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: A11yFab(onPressed: () {})),
        ),
      );

      expect(find.byType(Tooltip), findsNothing);
      expect(
        tester.getSize(find.byType(A11yFab)).height,
        greaterThanOrEqualTo(56.0),
      );
      expect(
        tester.getSemantics(find.byType(A11yFab)),
        isSemantics(
          label: _strings.openCenterLabel,
          isButton: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
    });

    // Desligar a camada é o caminho de quem não quer acessibilidade e mesmo
    // assim mantém o `builder:` na MaterialApp — remover a configuração não
    // pode deixar um botão flutuante órfão sobre o app.
    testWidgets('não aparece quando a camada está desligada', (tester) async {
      final service = await _servico(
        configuration: const A11yConfiguration(enabled: false),
      );

      await tester.pumpWidget(
        _sob(service: service, child: const Text('conteúdo')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(A11yFab), findsNothing);
    });
  });
}
