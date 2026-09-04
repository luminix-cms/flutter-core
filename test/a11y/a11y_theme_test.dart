import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luminix_flutter/accessibility.dart';

class _MarcaDoApp extends ThemeExtension<_MarcaDoApp> {
  const _MarcaDoApp(this.destaque);

  final Color destaque;

  @override
  _MarcaDoApp copyWith({Color? destaque}) =>
      _MarcaDoApp(destaque ?? this.destaque);

  @override
  _MarcaDoApp lerp(covariant ThemeExtension<_MarcaDoApp>? other, double t) =>
      this;
}

const A11ySettings _baixaVisao = A11ySettings(
  fontFamily: A11yFontFamily.hyperlegible,
  textScale: 1.5,
  boldText: true,
  letterSpacing: A11yLetterSpacing.wide,
  lineHeight: 1.5,
  contrastMode: A11yContrastMode.highContrast,
);

const List<String> _papeis = [
  'displayLarge',
  'displayMedium',
  'displaySmall',
  'headlineLarge',
  'headlineMedium',
  'headlineSmall',
  'titleLarge',
  'titleMedium',
  'titleSmall',
  'bodyLarge',
  'bodyMedium',
  'bodySmall',
  'labelLarge',
  'labelMedium',
  'labelSmall',
];

// ThemeData.localize monta o textTheme como geometria.merge(textTheme): sem
// isso os 15 papéis existem, mas sem fontSize, letterSpacing nem height.
// packages/flutter/lib/src/material/theme_data.dart
TextTheme _temaDeTextoLocalizado() {
  final tema = ThemeData();
  return tema.typography.englishLike.merge(tema.textTheme);
}

List<TextStyle?> _todosOsPapeis(TextTheme theme) => [
  theme.displayLarge,
  theme.displayMedium,
  theme.displaySmall,
  theme.headlineLarge,
  theme.headlineMedium,
  theme.headlineSmall,
  theme.titleLarge,
  theme.titleMedium,
  theme.titleSmall,
  theme.bodyLarge,
  theme.bodyMedium,
  theme.bodySmall,
  theme.labelLarge,
  theme.labelMedium,
  theme.labelSmall,
];

void main() {
  group('a11yContrastRatio', () {
    test('preto sobre branco é 21:1', () {
      expect(
        a11yContrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21.0, 0.01),
      );
    });

    test('a mesma cor é 1:1 e a ordem não importa', () {
      const cor = Color(0xFF3366AA);
      expect(a11yContrastRatio(cor, cor), closeTo(1.0, 0.0001));
      expect(
        a11yContrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        a11yContrastRatio(const Color(0xFFFFFFFF), const Color(0xFF000000)),
      );
    });
  });

  group('a11yEnsureContrast', () {
    test('devolve a cor intacta quando já atende', () {
      const fundo = Color(0xFFFFFFFF);
      const frente = Color(0xFF000000);

      expect(identical(a11yEnsureContrast(frente, fundo, 7.0), frente), isTrue);
    });

    test('atinge exatamente a razão pedida, sem exagerar', () {
      const fundo = Color(0xFFFFFFFF);
      const frente = Color(0xFF9E9E9E);

      final ajustada = a11yEnsureContrast(frente, fundo, 4.5);
      final razao = a11yContrastRatio(ajustada, fundo);

      expect(razao, greaterThanOrEqualTo(4.5));
      expect(razao, lessThan(5.5));
    });

    test('escolhe o polo pelo fundo', () {
      const claro = Color(0xFFFFFFFF);
      const escuro = Color(0xFF101010);

      expect(
        a11yEnsureContrast(
          const Color(0xFF808080),
          claro,
          7.0,
        ).computeLuminance(),
        lessThan(const Color(0xFF808080).computeLuminance()),
      );
      expect(
        a11yEnsureContrast(
          const Color(0xFF808080),
          escuro,
          7.0,
        ).computeLuminance(),
        greaterThan(const Color(0xFF808080).computeLuminance()),
      );
    });

    test('entrega o melhor polo quando a razão é inalcançável', () {
      const fundo = Color(0xFF777777);

      final ajustada = a11yEnsureContrast(const Color(0xFF888888), fundo, 21.0);

      expect(ajustada, a11yContrastPoleFor(fundo));
      expect(a11yContrastRatio(ajustada, fundo), lessThan(21.0));
    });

    test('um cinza médio não alcança 7:1 contra polo nenhum', () {
      const fundo = Color(0xFF777777);

      expect(
        a11yContrastRatio(a11yContrastPoleFor(fundo), fundo),
        lessThan(7.0),
      );
    });

    test('preserva o alfa da cor de frente', () {
      final ajustada = a11yEnsureContrast(
        const Color(0x80808080),
        const Color(0xFFFFFFFF),
        7.0,
      );

      expect(ajustada.a, closeTo(0x80 / 0xFF, 0.01));
    });
  });

  group('A11yBoostedColorSchemeResolver', () {
    final resolver = const A11yBoostedColorSchemeResolver();
    final base = ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3));

    test('contraste padrão devolve o esquema idêntico', () {
      expect(
        identical(resolver.resolve(base, A11ySettings.defaults), base),
        isTrue,
      );
    });

    test('escala de cinza não é transformação de esquema', () {
      const cinza = A11ySettings(contrastMode: A11yContrastMode.grayscale);

      expect(identical(resolver.resolve(base, cinza), base), isTrue);
    });

    test('preserva os papéis de marca', () {
      const alto = A11ySettings(contrastMode: A11yContrastMode.highContrast);

      final ajustado = resolver.resolve(base, alto);

      expect(ajustado.primary, base.primary);
      expect(ajustado.surface, base.surface);
      expect(ajustado.error, base.error);
    });

    test('todo par chega ao alvo ou ao polo do fundo', () {
      for (final modo in [
        A11yContrastMode.enhancedContrast,
        A11yContrastMode.highContrast,
      ]) {
        final alvo = modo.minimumContrastRatio;
        for (final brilho in Brightness.values) {
          final origem = ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: brilho,
          );
          final ajustado = resolver.resolve(
            origem,
            A11ySettings(contrastMode: modo),
          );

          for (final par in A11yBoostedColorSchemeResolver.pairs) {
            final fundo = par.background(ajustado);
            final atingido = par.ratioIn(ajustado) >= alvo;
            final noPolo =
                par.foreground(ajustado) == a11yContrastPoleFor(fundo);

            expect(
              atingido || noPolo,
              isTrue,
              reason: '${par.name} em $brilho no modo ${modo.name}',
            );
          }
        }
      }
    });

    test('os pares sobre surface chegam a 7:1 em alto contraste', () {
      const alto = A11ySettings(contrastMode: A11yContrastMode.highContrast);

      final ajustado = resolver.resolve(base, alto);

      for (final nome in ['onSurface', 'onSurfaceVariant', 'outline']) {
        final par = A11yBoostedColorSchemeResolver.pairs.firstWhere(
          (p) => p.name == nome,
        );
        expect(par.ratioIn(ajustado), greaterThanOrEqualTo(7.0), reason: nome);
      }
    });
  });

  group('A11ySeededColorSchemeResolver', () {
    test('contraste padrão devolve o esquema idêntico', () {
      final base = ColorScheme.fromSeed(seedColor: const Color(0xFF2196F3));

      expect(
        identical(
          const A11ySeededColorSchemeResolver().resolve(
            base,
            A11ySettings.defaults,
          ),
          base,
        ),
        isTrue,
      );
    });

    test(
      'descarta os overrides de papel do app — é o preço do contrastLevel',
      () {
        final base = ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
        ).copyWith(primary: const Color(0xFFAA0000));
        const alto = A11ySettings(contrastMode: A11yContrastMode.highContrast);

        final ajustado = const A11ySeededColorSchemeResolver().resolve(
          base,
          alto,
        );

        expect(ajustado.primary, isNot(const Color(0xFFAA0000)));
        expect(ajustado.brightness, base.brightness);
      },
    );
  });

  group('applyA11yTypography', () {
    final base = _temaDeTextoLocalizado();

    test('a base localizada tem os 15 papéis com métrica', () {
      expect(_todosOsPapeis(base), everyElement(isNotNull));
      expect(
        _todosOsPapeis(base).map((s) => s!.fontSize),
        everyElement(isNotNull),
      );
    });

    test('o ThemeData cru não tem métrica nenhuma — ela vem do localize', () {
      expect(ThemeData().textTheme.bodyMedium!.fontSize, isNull);
    });

    test('sem métrica na base o espaçamento vira o mesmo em todo papel', () {
      final cru = applyA11yTypography(
        ThemeData().textTheme,
        const A11ySettings(letterSpacing: A11yLetterSpacing.wide),
      );

      expect(
        _todosOsPapeis(cru).map((s) => s!.letterSpacing).toSet(),
        hasLength(1),
      );
    });

    test('os 15 papéis recebem a família do package', () {
      final ajustado = applyA11yTypography(base, _baixaVisao);
      final papeis = _todosOsPapeis(ajustado);

      for (var i = 0; i < papeis.length; i++) {
        expect(
          papeis[i]!.fontFamily,
          'packages/luminix_flutter/AtkinsonHyperlegible',
          reason: _papeis[i],
        );
      }
    });

    test('papel nulo continua nulo', () {
      const magro = TextTheme(bodyMedium: TextStyle(fontSize: 14));

      final ajustado = applyA11yTypography(magro, _baixaVisao);

      expect(ajustado.bodyMedium, isNotNull);
      expect(ajustado.displayLarge, isNull);
      expect(ajustado.labelSmall, isNull);
    });

    test('família padrão não toca em fontFamily', () {
      const semFonte = A11ySettings(letterSpacing: A11yLetterSpacing.wide);

      final ajustado = applyA11yTypography(base, semFonte);

      expect(ajustado.bodyMedium!.fontFamily, base.bodyMedium!.fontFamily);
    });

    test('sem mudança de tipografia devolve o tema idêntico', () {
      const soContraste = A11ySettings(
        contrastMode: A11yContrastMode.highContrast,
      );

      expect(identical(applyA11yTypography(base, soContraste), base), isTrue);
    });

    test('letterSpacing é aditivo e proporcional ao corpo do papel', () {
      const em = 0.06;

      final ajustado = applyA11yTypography(
        base,
        const A11ySettings(letterSpacing: A11yLetterSpacing.wide),
      );

      for (final papel in [base.displayLarge!, base.labelSmall!]) {
        final destino = papel == base.displayLarge
            ? ajustado.displayLarge!
            : ajustado.labelSmall!;

        expect(
          destino.letterSpacing,
          closeTo((papel.letterSpacing ?? 0) + em * papel.fontSize!, 0.0001),
        );
      }

      expect(
        ajustado.displayLarge!.letterSpacing! >
            ajustado.labelSmall!.letterSpacing!,
        isTrue,
      );
    });

    test('lineHeight vira height em todo papel', () {
      final ajustado = applyA11yTypography(
        base,
        const A11ySettings(lineHeight: 1.8),
      );

      expect(_todosOsPapeis(ajustado).map((s) => s!.height), everyElement(1.8));
    });

    test('reducedEmphasis tira o itálico e limita o peso', () {
      const papel = TextStyle(
        fontSize: 16,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w900,
      );

      final ajustado = a11yAdaptTextStyle(
        papel,
        const A11ySettings(reducedEmphasis: true),
      );

      expect(ajustado.fontStyle, FontStyle.normal);
      expect(ajustado.fontWeight, FontWeight.w600);
    });

    test('reducedEmphasis não engorda um peso já leve', () {
      final ajustado = a11yAdaptTextStyle(
        const TextStyle(fontWeight: FontWeight.w300),
        const A11ySettings(reducedEmphasis: true),
      );

      expect(ajustado.fontWeight, FontWeight.w300);
    });
  });

  group('a11yStyleWithFont — R3', () {
    const daMarca = TextStyle(fontFamily: 'BrandFont', package: 'brand_pkg');

    test('a base do app já vem prefixada pelo package dela', () {
      expect(daMarca.fontFamily, 'packages/brand_pkg/BrandFont');
    });

    test('prefixo montado à mão empilha sobre o package da base', () {
      final ingenuo = daMarca.copyWith(
        fontFamily: 'packages/luminix_flutter/OpenDyslexic',
      );

      expect(
        ingenuo.fontFamily,
        'packages/brand_pkg/packages/luminix_flutter/OpenDyslexic',
      );
    });

    test('passar package troca o pacote da base em vez de empilhar', () {
      final ajustado = a11yStyleWithFont(
        daMarca,
        a11yResolveFont(
          const A11ySettings(fontFamily: A11yFontFamily.openDyslexic),
        )!,
      );

      expect(ajustado.fontFamily, 'packages/luminix_flutter/OpenDyslexic');
    });

    test('a cadeia de fallback fica dentro do package', () {
      final ajustado = a11yStyleWithFont(
        const TextStyle(fontFamilyFallback: ['FonteDaMarca']),
        a11yResolveFont(
          const A11ySettings(fontFamily: A11yFontFamily.openDyslexic),
        )!,
      );

      expect(ajustado.fontFamilyFallback, [
        'packages/luminix_flutter/AtkinsonHyperlegible',
      ]);
    });

    test('a fonte de fallback não cai em si mesma', () {
      final atkinson = a11yResolveFont(
        const A11ySettings(fontFamily: A11yFontFamily.hyperlegible),
      )!;

      expect(atkinson.fallback, isEmpty);
    });

    test('fontFamilyOverrides aponta para o asset do app', () {
      final resolvida = a11yResolveFont(
        const A11ySettings(fontFamily: A11yFontFamily.lexend),
        fontFamilyOverrides: const {
          A11yFontFamily.lexend: A11yFontOverride(fontFamily: 'LexendDoApp'),
        },
      )!;

      expect(resolvida.family, 'LexendDoApp');
      expect(resolvida.package, isNull);
    });

    test('a família padrão nunca resolve fonte, nem com override', () {
      expect(
        a11yResolveFont(
          A11ySettings.defaults,
          fontFamilyOverrides: const {
            A11yFontFamily.standard: A11yFontOverride(fontFamily: 'Qualquer'),
          },
        ),
        isNull,
      );
    });
  });

  group('A11yTextScaler — R8', () {
    test('compõe com o ajuste do sistema em vez de descartá-lo', () {
      final escalador = A11yTextScaler.resolve(
        platform: const TextScaler.linear(1.3),
        factor: 1.5,
      );

      expect(escalador.scale(10), closeTo(19.5, 0.0001));
    });

    test('compõe primeiro e limita depois', () {
      final escalador = A11yTextScaler.resolve(
        platform: const TextScaler.linear(1.5),
        factor: 1.5,
        maxScaleFactor: 2.0,
      );

      expect(escalador.scale(10), closeTo(20.0, 0.0001));
    });

    test('fator 1.0 devolve o escalador da plataforma', () {
      const plataforma = TextScaler.linear(1.3);

      expect(
        A11yTextScaler.resolve(platform: plataforma, factor: 1.0),
        plataforma,
      );
    });

    test('instâncias iguais são iguais, inclusive depois do clamp', () {
      TextScaler montar() => A11yTextScaler.resolve(
        platform: const TextScaler.linear(1.3),
        factor: 1.5,
        maxScaleFactor: 2.0,
      );

      expect(montar(), montar());
      expect(montar().hashCode, montar().hashCode);
    });
  });

  group('A11yNoTransitionsBuilder — R7', () {
    test('zera a ida e a volta', () {
      const construtor = A11yNoTransitionsBuilder();

      expect(construtor.transitionDuration, Duration.zero);
      expect(construtor.reverseTransitionDuration, Duration.zero);
    });

    test('cobre todas as plataformas', () {
      expect(
        a11yNoPageTransitionsTheme.builders.keys,
        containsAll(TargetPlatform.values),
      );
    });
  });

  group('A11yThemeExtension — R10', () {
    testWidgets('num ThemeData pelado devolve o fallback', (tester) async {
      late A11yThemeExtension lida;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Builder(
            builder: (context) {
              lida = A11yThemeExtension.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(identical(lida, A11yThemeExtension.fallback), isTrue);
      expect(lida.isHighContrast, isFalse);
      expect(lida.minTapTarget, 48.0);
    });

    test('lerp snapa booleano e enum na metade', () {
      const inicio = A11yThemeExtension();
      const fim = A11yThemeExtension(
        contrastMode: A11yContrastMode.highContrast,
        reduceMotion: true,
        borderWidth: 3.0,
      );

      expect(inicio.lerp(fim, 0.49).reduceMotion, isFalse);
      expect(inicio.lerp(fim, 0.51).reduceMotion, isTrue);
      expect(inicio.lerp(fim, 0.49).contrastMode, A11yContrastMode.standard);
      expect(inicio.lerp(fim, 0.5).borderWidth, closeTo(2.0, 0.0001));
    });
  });

  group('A11yThemeAdapter', () {
    const adaptador = A11yThemeAdapter();

    test('sem ajuste devolve o tema idêntico', () {
      final base = ThemeData();

      expect(
        identical(adaptador.adapt(base, A11ySettings.defaults), base),
        isTrue,
      );
    });

    test('a extensão do app sobrevive ao adapt', () {
      final base = ThemeData(
        extensions: const [_MarcaDoApp(Color(0xFFAA0000))],
      );

      final adaptado = adaptador.adapt(base, _baixaVisao);

      expect(
        adaptado.extension<_MarcaDoApp>()!.destaque,
        const Color(0xFFAA0000),
      );
      expect(adaptado.extension<A11yThemeExtension>(), isNotNull);
    });

    test('a extensão do package descreve os ajustes', () {
      final adaptado = adaptador.adapt(ThemeData(), _baixaVisao);
      final extensao = adaptado.extension<A11yThemeExtension>()!;

      expect(extensao.contrastMode, A11yContrastMode.highContrast);
      expect(extensao.isHighContrast, isTrue);
      expect(extensao.focusRingWidth, 3.0);
      expect(extensao.focusHaloWidth, 4.0);
      expect(extensao.borderWidth, 2.0);
    });

    test('o anel de foco alcança 3:1 contra a superfície', () {
      for (final modo in A11yContrastMode.values) {
        final adaptado = adaptador.adapt(
          ThemeData(),
          A11ySettings(contrastMode: modo, reduceMotion: true),
        );
        final extensao = adaptado.extension<A11yThemeExtension>()!;

        expect(
          a11yContrastRatio(
            extensao.focusRingColor,
            adaptado.colorScheme.surface,
          ),
          greaterThanOrEqualTo(3.0),
          reason: modo.name,
        );
      }
    });

    test('a tipografia chega no textTheme do tema', () {
      final adaptado = adaptador.adapt(ThemeData(), _baixaVisao);

      expect(
        adaptado.textTheme.bodyMedium!.fontFamily,
        'packages/luminix_flutter/AtkinsonHyperlegible',
      );
      expect(
        adaptado.primaryTextTheme.bodyMedium!.fontFamily,
        'packages/luminix_flutter/AtkinsonHyperlegible',
      );
    });

    test('reduceMotion zera as transições e o splash — R6/R7', () {
      final adaptado = adaptador.adapt(
        ThemeData(),
        const A11ySettings(reduceMotion: true),
      );

      for (final construtor in adaptado.pageTransitionsTheme.builders.values) {
        expect(construtor.transitionDuration, Duration.zero);
        expect(construtor.reverseTransitionDuration, Duration.zero);
      }
      expect(adaptado.splashFactory, NoSplash.splashFactory);
    });

    test('alto contraste re-deriva o dividerColor legado — R5', () {
      final base = ThemeData();
      const alto = A11ySettings(contrastMode: A11yContrastMode.highContrast);

      final adaptado = adaptador.adapt(base, alto);

      expect(adaptado.dividerColor, adaptado.colorScheme.outline);
      expect(adaptado.dividerColor, isNot(base.dividerColor));
    });

    test(
      'copyWith(colorScheme:) sozinho deixaria os legados para trás — R5',
      () {
        final base = ThemeData();
        final esquema = base.colorScheme.copyWith(
          surface: const Color(0xFF123456),
        );

        final ingenuo = base.copyWith(colorScheme: esquema);

        expect(ingenuo.scaffoldBackgroundColor, isNot(esquema.surface));
      },
    );

    test(
      'creamReadingBackground troca a superfície e leva os legados junto',
      () {
        const creme = A11ySettings(creamReadingBackground: true);

        final adaptado = adaptador.adapt(ThemeData(), creme);

        expect(adaptado.colorScheme.surface, a11yCreamSurface);
        expect(adaptado.scaffoldBackgroundColor, a11yCreamSurface);
        expect(adaptado.canvasColor, a11yCreamSurface);
        expect(adaptado.cardColor, a11yCreamSurface);
      },
    );

    test('creme não se aplica ao tema escuro', () {
      final base = ThemeData(brightness: Brightness.dark);

      final adaptado = adaptador.adapt(
        base,
        const A11ySettings(creamReadingBackground: true),
      );

      expect(adaptado.colorScheme.surface, base.colorScheme.surface);
    });

    test('qualquer ajuste força densidade e alvo de toque generosos', () {
      final adaptado = adaptador.adapt(
        ThemeData(visualDensity: VisualDensity.compact),
        const A11ySettings(reduceMotion: true),
      );

      expect(adaptado.visualDensity, VisualDensity.standard);
      expect(adaptado.materialTapTargetSize, MaterialTapTargetSize.padded);
    });
  });

  group('themeRebuilder', () {
    const alto = A11ySettings(contrastMode: A11yContrastMode.highContrast);

    ThemeData temaDoApp(ColorScheme esquema) => ThemeData(
      colorScheme: esquema,
      // É assim que todo app escreve o próprio tema, e é o que o adapter não
      // alcança sozinho: o papel vira um Color literal aqui dentro.
      inputDecorationTheme: InputDecorationTheme(
        fillColor: esquema.surface,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: esquema.outline),
        ),
      ),
    );

    final base = temaDoApp(ColorScheme.fromSeed(seedColor: Color(0xFF3667B4)));

    Color borda(ThemeData tema) =>
        (tema.inputDecorationTheme.enabledBorder! as OutlineInputBorder)
            .borderSide
            .color;

    test('sem ele o component theme fica com a cor congelada', () {
      final adaptado = const A11yThemeAdapter().adapt(base, alto);

      expect(adaptado.colorScheme.outline, isNot(base.colorScheme.outline));
      expect(borda(adaptado), base.colorScheme.outline);
    });

    test('com ele o component theme acompanha o esquema adaptado', () {
      final adaptado = A11yThemeAdapter(
        themeRebuilder: temaDoApp,
      ).adapt(base, alto);

      expect(borda(adaptado), adaptado.colorScheme.outline);
      expect(
        a11yContrastRatio(
          borda(adaptado),
          adaptado.inputDecorationTheme.fillColor!,
        ),
        greaterThanOrEqualTo(7.0),
      );
    });

    test('o esquema do tema reconstruído não é adaptado de novo', () {
      final adaptado = A11yThemeAdapter(
        themeRebuilder: temaDoApp,
      ).adapt(base, alto);

      final duplo = A11yThemeAdapter(
        themeRebuilder: temaDoApp,
      ).adapt(adaptado, alto);

      expect(duplo.colorScheme.outline, adaptado.colorScheme.outline);
    });

    test('sem mudança de esquema o tema do app não é refeito', () {
      var chamadas = 0;

      final adaptado = A11yThemeAdapter(
        themeRebuilder: (esquema) {
          chamadas++;
          return temaDoApp(esquema);
        },
      ).adapt(base, const A11ySettings(reduceMotion: true));

      expect(chamadas, 0);
      expect(borda(adaptado), base.colorScheme.outline);
    });
  });
}
