import 'package:flutter_test/flutter_test.dart';
import 'package:luminix_flutter/accessibility.dart';

void main() {
  group('A11yOverrides — aplicação', () {
    test('vazio devolve a base intocada', () {
      final base = a11ySettingsForProfiles([A11yProfile.dyslexia]);

      expect(const A11yOverrides.empty().applyTo(base), base);
    });

    test('vence o perfil no campo escolhido', () {
      final base = a11ySettingsForProfiles([A11yProfile.lowVision]);
      final overrides = const A11yOverrides.empty().set(
        A11yOverrideKey.textScale,
        1.15,
      );

      final resultado = overrides.applyTo(base);

      expect(base.textScale, 1.5);
      expect(resultado.textScale, 1.15);
    });

    test('não toca nos campos que não foram definidos', () {
      final base = a11ySettingsForProfiles([A11yProfile.lowVision]);
      final resultado = const A11yOverrides.empty()
          .set(A11yOverrideKey.textScale, 1.0)
          .applyTo(base);

      expect(resultado.contrastMode, A11yContrastMode.highContrast);
      expect(resultado.fontFamily, A11yFontFamily.hyperlegible);
      expect(resultado.boldText, isTrue);
      expect(resultado.decorativeBackgrounds, isFalse);
    });

    test('define lineHeight como nulo, que o copyWith não alcança', () {
      final base = a11ySettingsForProfiles([A11yProfile.dyslexia]);
      final resultado = const A11yOverrides.empty()
          .set(A11yOverrideKey.lineHeight, null)
          .applyTo(base);

      expect(base.lineHeight, 1.8);
      expect(resultado.lineHeight, isNull);
    });

    test('desligar um booleano que o perfil ligou', () {
      final base = a11ySettingsForProfiles([A11yProfile.adhd]);
      final resultado = const A11yOverrides.empty()
          .set(A11yOverrideKey.reduceMotion, false)
          .applyTo(base);

      expect(base.reduceMotion, isTrue);
      expect(resultado.reduceMotion, isFalse);
    });

    test('uma melhoria no preset alcança quem já tem overrides', () {
      final overrides = const A11yOverrides.empty().set(
        A11yOverrideKey.textScale,
        1.3,
      );

      final antes = overrides.applyTo(
        a11ySettingsForProfiles([A11yProfile.colorBlindness]),
      );
      final depois = overrides.applyTo(
        a11ySettingsForProfiles([
          A11yProfile.colorBlindness,
          A11yProfile.dyslexia,
        ]),
      );

      expect(antes.fontFamily, A11yFontFamily.standard);
      expect(depois.fontFamily, A11yFontFamily.openDyslexic);
      expect(depois.textScale, 1.3);
    });
  });

  group('A11yOverrides — tri-state', () {
    test('has distingue não definido de definido como nulo', () {
      const vazio = A11yOverrides.empty();
      final comNulo = vazio.set(A11yOverrideKey.lineHeight, null);

      expect(vazio.has(A11yOverrideKey.lineHeight), isFalse);
      expect(comNulo.has(A11yOverrideKey.lineHeight), isTrue);
      expect(comNulo.read(A11yOverrideKey.lineHeight), isNull);
    });

    test('clear volta a delegar ao perfil', () {
      final base = a11ySettingsForProfiles([A11yProfile.lowVision]);
      final overrides = const A11yOverrides.empty().set(
        A11yOverrideKey.textScale,
        1.0,
      );

      expect(overrides.applyTo(base).textScale, 1.0);
      expect(
        overrides.clear(A11yOverrideKey.textScale).applyTo(base).textScale,
        1.5,
      );
    });

    test('clear de chave ausente devolve a mesma instância', () {
      const overrides = A11yOverrides.empty();

      expect(
        identical(overrides.clear(A11yOverrideKey.boldText), overrides),
        isTrue,
      );
    });

    test('set não muda a instância original', () {
      const original = A11yOverrides.empty();
      final derivado = original.set(A11yOverrideKey.boldText, true);

      expect(original.isEmpty, isTrue);
      expect(derivado.length, 1);
    });
  });

  group('A11yOverrides — serialização', () {
    test('grava só o que foi definido', () {
      final overrides = const A11yOverrides.empty()
          .set(A11yOverrideKey.contrastMode, A11yContrastMode.highContrast)
          .set(A11yOverrideKey.textScale, 1.5);

      expect(overrides.toJson(), {
        'textScale': 1.5,
        'contrastMode': 'highContrast',
      });
    });

    test('sobrevive à ida e volta, inclusive o nulo explícito', () {
      final overrides = const A11yOverrides.empty()
          .set(A11yOverrideKey.lineHeight, null)
          .set(A11yOverrideKey.fontFamily, A11yFontFamily.lexend)
          .set(A11yOverrideKey.boldText, true);

      final volta = A11yOverrides.fromJson(overrides.toJson());

      expect(volta, overrides);
      expect(volta.has(A11yOverrideKey.lineHeight), isTrue);
      expect(volta.read(A11yOverrideKey.fontFamily), A11yFontFamily.lexend);
    });

    test('chave desconhecida é ignorada', () {
      final volta = A11yOverrides.fromJson({
        'textScale': 1.3,
        'modoTurbo': true,
      });

      expect(volta.length, 1);
      expect(volta.read(A11yOverrideKey.textScale), 1.3);
    });

    test('valor inválido é ignorado em vez de virar padrão', () {
      final volta = A11yOverrides.fromJson({
        'boldText': 'sim',
        'contrastMode': 'ultra',
        'lineHeight': 'alto',
        'textScale': 1.3,
      });

      expect(volta.has(A11yOverrideKey.boldText), isFalse);
      expect(volta.has(A11yOverrideKey.contrastMode), isFalse);
      expect(volta.has(A11yOverrideKey.lineHeight), isFalse);
      expect(volta.length, 1);
    });

    test('entrada que não é mapa devolve vazio', () {
      expect(A11yOverrides.fromJson(['textScale']).isEmpty, isTrue);
      expect(A11yOverrides.fromJson(null).isEmpty, isTrue);
    });

    test('inteiro vira double no textScale', () {
      final volta = A11yOverrides.fromJson({'textScale': 2});

      expect(volta.read(A11yOverrideKey.textScale), 2.0);
    });
  });

  group('A11yOverrides — igualdade', () {
    test('mesmas chaves e valores são iguais em qualquer ordem', () {
      final um = const A11yOverrides.empty()
          .set(A11yOverrideKey.boldText, true)
          .set(A11yOverrideKey.textScale, 1.3);
      final dois = const A11yOverrides.empty()
          .set(A11yOverrideKey.textScale, 1.3)
          .set(A11yOverrideKey.boldText, true);

      expect(um, dois);
      expect(um.hashCode, dois.hashCode);
    });

    test('definido como nulo difere de não definido', () {
      const vazio = A11yOverrides.empty();

      expect(vazio.set(A11yOverrideKey.lineHeight, null), isNot(vazio));
    });

    test('mergedWith deixa o segundo vencer', () {
      final base = const A11yOverrides.empty()
          .set(A11yOverrideKey.textScale, 1.0)
          .set(A11yOverrideKey.boldText, true);
      final novo = const A11yOverrides.empty().set(
        A11yOverrideKey.textScale,
        1.5,
      );

      final merged = base.mergedWith(novo);

      expect(merged.read(A11yOverrideKey.textScale), 1.5);
      expect(merged.read(A11yOverrideKey.boldText), isTrue);
    });
  });
}
