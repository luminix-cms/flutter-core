import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luminix_flutter/accessibility.dart';
import 'package:luminix_flutter/src/a11y/a11y_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MarcaDoApp extends ThemeExtension<_MarcaDoApp> {
  const _MarcaDoApp(this.destaque);

  final Color destaque;

  @override
  _MarcaDoApp copyWith({Color? destaque}) =>
      _MarcaDoApp(destaque ?? this.destaque);

  @override
  _MarcaDoApp lerp(_MarcaDoApp? other, double t) => this;
}

Future<A11yService> _servico({
  A11yConfiguration configuration = const A11yConfiguration(),
  List<A11yProfile> perfis = const [],
}) async {
  final service = A11yService(configuration: configuration, store: A11yStore());
  await service.load();
  if (perfis.isNotEmpty) await service.setProfiles(perfis);
  return service;
}

A11yConfiguration _comCentral({
  bool showFab = true,
  A11yScopeMode scope = A11yScopeMode.device,
}) {
  return A11yConfiguration(
    showFab: showFab,
    scope: scope,
    fabBuilder: (context, abrir) => A11yLabeledButton(
      label: 'Abrir acessibilidade',
      onPressed: abrir,
      child: const Icon(Icons.accessibility_new),
    ),
    centerBuilder: (context, fechar) => Material(
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: A11yLabeledButton(
          label: 'Fechar central',
          onPressed: fechar,
          child: const Text('Central'),
        ),
      ),
    ),
  );
}

Widget _app({
  required A11yService service,
  Widget? home,
  ThemeData? theme,
  MediaQueryData? media,
}) {
  final app = MaterialApp(
    theme: theme,
    builder: A11yScope.builder(service: service),
    home: home ?? const Scaffold(body: Center(child: Text('conteúdo'))),
  );

  return media == null ? app : MediaQuery(data: media, child: app);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('A11yLabeledButton', () {
    testWidgets('anuncia rótulo, papel de botão e ação de toque', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: A11yLabeledButton(
                label: 'Aumentar fonte',
                onPressed: _nada,
                child: Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Aumentar fonte')),
        matchesSemantics(
          label: 'Aumentar fonte',
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          isFocusable: true,
        ),
      );

      semantics.dispose();
    });

    testWidgets('o duplo-toque do leitor chega ao onPressed', (tester) async {
      final semantics = tester.ensureSemantics();
      var toques = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: A11yLabeledButton(
                label: 'Aplicar',
                onPressed: () => toques++,
                child: const Text('Aplicar'),
              ),
            ),
          ),
        ),
      );

      tester.semantics.tap(find.semantics.byLabel('Aplicar'));

      expect(toques, 1);
      semantics.dispose();
    });

    testWidgets('desabilitado não expõe ação de toque', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: A11yLabeledButton(
                label: 'Aplicar',
                onPressed: null,
                child: Text('Aplicar'),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Aplicar')),
        matchesSemantics(
          label: 'Aplicar',
          isButton: true,
          hasEnabledState: true,
        ),
      );

      semantics.dispose();
    });

    testWidgets('um ícone de 16 dp ainda cumpre o alvo do Android', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: A11yLabeledButton(
                label: 'Fechar',
                onPressed: _nada,
                child: Icon(Icons.close, size: 16),
              ),
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      final caixa = tester.getSize(find.byType(GestureDetector));
      expect(caixa.width, greaterThanOrEqualTo(48));
      expect(caixa.height, greaterThanOrEqualTo(48));

      semantics.dispose();
    });

    testWidgets('sinaliza seleção para o leitor', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: A11yLabeledButton(
                label: 'Dislexia',
                selected: true,
                onPressed: _nada,
                child: Text('Dislexia'),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Dislexia')),
        isSemantics(label: 'Dislexia', isSelected: true, isButton: true),
      );

      semantics.dispose();
    });
  });

  group('A11yTapTarget', () {
    testWidgets('estica o conteúdo miúdo até o mínimo do tema', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: A11yTapTarget(child: SizedBox(width: 8, height: 8)),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(ConstrainedBox).last),
        const Size(48, 48),
      );
    });

    testWidgets('a margem separa alvos vizinhos', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: A11yTapTarget(child: SizedBox(width: 8, height: 8)),
            ),
          ),
        ),
      );

      expect(tester.getSize(find.byType(A11yTapTarget)), const Size(56, 56));
    });
  });

  group('A11yFocusRing', () {
    setUp(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional,
    );
    tearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );

    testWidgets('o anel só aparece com o foco de teclado', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: A11yFocusRing(
                focusNode: node,
                onActivate: _nada,
                child: const Text('Aplicar'),
              ),
            ),
          ),
        ),
      );

      final anel = find.descendant(
        of: find.byType(A11yFocusRing),
        matching: find.byType(DecoratedBox),
      );

      expect(anel, findsNothing);

      node.requestFocus();
      await tester.pump();

      expect(anel, findsOneWidget);
    });

    testWidgets('Enter e Espaço ativam pelo ActivateIntent', (tester) async {
      var ativacoes = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: A11yFocusRing(
                autofocus: true,
                onActivate: () => ativacoes++,
                child: const Text('Aplicar'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);

      expect(ativacoes, 2);
    });

    testWidgets('sem onActivate a ação não é habilitada', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: A11yFocusRing(autofocus: true, child: Text('Aplicar')),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);

      expect(tester.takeException(), isNull);
    });
  });

  group('A11yGrayscaleFilter', () {
    testWidgets('fica montado com matriz identidade quando desligado', (
      tester,
    ) async {
      await tester.pumpWidget(
        const A11yGrayscaleFilter(
          enabled: false,
          child: SizedBox(width: 10, height: 10),
        ),
      );

      final filtro = tester.widget<ColorFiltered>(find.byType(ColorFiltered));

      expect(
        filtro.colorFilter,
        const ColorFilter.matrix([
          1, 0, 0, 0, 0, //
          0, 1, 0, 0, 0, //
          0, 0, 1, 0, 0, //
          0, 0, 0, 1, 0, //
        ]),
      );
    });

    testWidgets('alternar não remonta o ColorFiltered', (tester) async {
      await tester.pumpWidget(
        const A11yGrayscaleFilter(
          enabled: false,
          child: SizedBox(width: 10, height: 10),
        ),
      );
      final antes = tester.element(find.byType(ColorFiltered));

      await tester.pumpWidget(
        const A11yGrayscaleFilter(
          enabled: true,
          child: SizedBox(width: 10, height: 10),
        ),
      );

      expect(tester.element(find.byType(ColorFiltered)), same(antes));
      expect(tester.takeException(), isNull);
    });
  });

  group('A11ySemanticsHeader', () {
    testWidgets('marca o nó como cabeçalho', (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: A11ySemanticsHeader(child: Text('Ajustes'))),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Ajustes')),
        isSemantics(label: 'Ajustes', isHeader: true),
      );

      semantics.dispose();
    });
  });

  group('A11yScope — seam', () {
    testWidgets('sem serviço o app renderiza intocado', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('conteúdo'))),
        ),
      );
      final semService = tester.widget<DefaultTextStyle>(
        find.byType(DefaultTextStyle).last,
      );

      await tester.pumpWidget(
        MaterialApp(
          builder: A11yScope.builder(),
          home: const Scaffold(body: Center(child: Text('conteúdo'))),
        ),
      );

      expect(find.text('conteúdo'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(
        tester
            .widget<DefaultTextStyle>(find.byType(DefaultTextStyle).last)
            .style
            .fontSize,
        semService.style.fontSize,
      );
    });

    testWidgets('R10 — a extensão existe mesmo com os ajustes no padrão', (
      tester,
    ) async {
      late A11yThemeExtension extensao;

      await tester.pumpWidget(
        _app(
          service: await _servico(),
          home: Builder(
            builder: (context) {
              extensao = A11yThemeExtension.of(context);
              return const SizedBox.shrink(key: Key('alvo'));
            },
          ),
        ),
      );

      expect(
        Theme.of(tester.element(find.byKey(const Key('alvo')))),
        isNotNull,
      );
      expect(extensao.contrastMode, A11yContrastMode.standard);
      expect(extensao.minTapTarget, 48.0);
    });

    testWidgets('a ThemeExtension do app sobrevive ao escopo', (tester) async {
      late ThemeData tema;

      await tester.pumpWidget(
        _app(
          service: await _servico(perfis: [A11yProfile.lowVision]),
          theme: ThemeData(extensions: const [_MarcaDoApp(Color(0xFF00FF00))]),
          home: Builder(
            builder: (context) {
              tema = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tema.extension<_MarcaDoApp>()?.destaque, const Color(0xFF00FF00));
      expect(tema.extension<A11yThemeExtension>()?.isHighContrast, isTrue);
    });

    testWidgets('R8 — compõe com a escala do sistema em vez de descartá-la', (
      tester,
    ) async {
      late TextScaler escala;

      await tester.pumpWidget(
        _app(
          service: await _servico(perfis: [A11yProfile.lowVision]),
          media: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          home: Builder(
            builder: (context) {
              escala = MediaQuery.textScalerOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(escala.scale(10), closeTo(19.5, 0.001));
    });

    testWidgets('R8 — o teto da configuração vence a composição', (
      tester,
    ) async {
      late TextScaler escala;

      await tester.pumpWidget(
        _app(
          service: await _servico(perfis: [A11yProfile.lowVision]),
          media: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          home: Builder(
            builder: (context) {
              escala = MediaQuery.textScalerOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(escala.scale(10), 20.0);
    });

    testWidgets('R7 — reduceMotion zera as transições de rota', (tester) async {
      late ThemeData tema;

      await tester.pumpWidget(
        _app(
          service: await _servico(perfis: [A11yProfile.epilepsy]),
          home: Builder(
            builder: (context) {
              tema = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      final construtor =
          tema.pageTransitionsTheme.builders[TargetPlatform.android]!;

      expect(construtor.transitionDuration, Duration.zero);
      expect(construtor.reverseTransitionDuration, Duration.zero);
      expect(tema.splashFactory, NoSplash.splashFactory);
    });

    testWidgets('grayscale monta o filtro sem remontar a subárvore', (
      tester,
    ) async {
      final service = await _servico();

      await tester.pumpWidget(_app(service: service));
      final antes = tester.element(find.byType(A11yGrayscaleFilter));

      await service.setOverride(
        A11yOverrideKey.contrastMode,
        A11yContrastMode.grayscale,
      );
      await tester.pump();

      expect(tester.element(find.byType(A11yGrayscaleFilter)), same(antes));
      expect(
        tester
            .widget<A11yGrayscaleFilter>(find.byType(A11yGrayscaleFilter))
            .enabled,
        isTrue,
      );
    });

    testWidgets('o builder do app roda dentro do escopo', (tester) async {
      late ThemeData tema;

      await tester.pumpWidget(
        MaterialApp(
          builder: A11yScope.builder(
            service: await _servico(perfis: [A11yProfile.lowVision]),
            next: (context, child) {
              tema = Theme.of(context);
              return child!;
            },
          ),
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );

      expect(tema.extension<A11yThemeExtension>()?.isHighContrast, isTrue);
    });

    testWidgets('enquanto o serviço não carregou valem os padrões', (
      tester,
    ) async {
      final service = A11yService(store: A11yStore());
      late A11ySettings ajustes;

      await tester.pumpWidget(
        _app(
          service: service,
          home: Builder(
            builder: (context) {
              ajustes = A11yScopeData.of(context).settings;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(service.isLoaded, isFalse);
      expect(ajustes, A11ySettings.defaults);
      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('A11yCenterHost — R9', () {
    testWidgets('abrir a central pelo FAB não lança sem Navigator ancestral', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(service: await _servico(configuration: _comCentral())),
      );

      expect(find.text('Central'), findsNothing);

      await tester.tap(find.byIcon(Icons.accessibility_new));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Central'), findsOneWidget);
    });

    testWidgets('a barreira fecha a central', (tester) async {
      await tester.pumpWidget(
        _app(service: await _servico(configuration: _comCentral())),
      );

      await tester.tap(find.byIcon(Icons.accessibility_new));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(400, 60));
      await tester.pumpAndSettle();

      expect(find.text('Central'), findsNothing);
      expect(find.byIcon(Icons.accessibility_new), findsOneWidget);
    });

    testWidgets('o voltar do sistema fecha a central antes de sair', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(service: await _servico(configuration: _comCentral())),
      );

      await tester.tap(find.byIcon(Icons.accessibility_new));
      await tester.pumpAndSettle();

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();

      expect(find.text('Central'), findsNothing);
      expect(await tester.binding.handlePopRoute(), isFalse);
    });

    testWidgets('com a central aberta o app sai da árvore de semântica', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        _app(
          service: await _servico(configuration: _comCentral()),
          home: const Scaffold(body: Center(child: Text('tela do app'))),
        ),
      );

      expect(_rotulosAnunciados(tester), contains('tela do app'));

      await tester.tap(find.byIcon(Icons.accessibility_new));
      await tester.pumpAndSettle();

      expect(_rotulosAnunciados(tester), isNot(contains('tela do app')));
      expect(_rotulosAnunciados(tester), contains('Fechar central'));

      semantics.dispose();
    });

    testWidgets('A11yFabVisibility esconde o FAB pela rota', (tester) async {
      await tester.pumpWidget(
        _app(
          service: await _servico(configuration: _comCentral()),
          home: const A11yFabVisibility(
            visible: false,
            child: Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.accessibility_new), findsNothing);
    });

    testWidgets('showFab desligado não desenha o FAB', (tester) async {
      await tester.pumpWidget(
        _app(
          service: await _servico(configuration: _comCentral(showFab: false)),
        ),
      );

      expect(find.byIcon(Icons.accessibility_new), findsNothing);
    });

    testWidgets('sem builders a Central padrão abre sem lançar', (
      tester,
    ) async {
      final service = await _servico();

      await tester.pumpWidget(_app(service: service));
      A11yScopeData.of(tester.element(find.text('conteúdo'))).openCenter();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(A11yCenterSheet), findsOneWidget);
      expect(find.text('conteúdo'), findsOneWidget);
    });
  });
}

void _nada() {}

// find.bySemanticsLabel lê a configuração de cada RenderObject e não enxerga um
// ExcludeSemantics ancestral: só a travessia responde o que o leitor anuncia.
List<String> _rotulosAnunciados(WidgetTester tester) => tester.semantics
    .simulatedAccessibilityTraversal()
    .map((node) => node.label)
    .where((label) => label.isNotEmpty)
    .toList();
