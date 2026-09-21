import 'package:flutter_test/flutter_test.dart';
import 'package:luminix_flutter/accessibility.dart';

void main() {
  group('A11ySettings.merge', () {
    test('sem perfis devolve os padrões', () {
      expect(A11ySettings.merge([]), A11ySettings.defaults);
    });

    test('booleanos ligam se qualquer perfil pedir', () {
      final merged = a11ySettingsForProfiles([
        A11yProfile.colorBlindness,
        A11yProfile.epilepsy,
      ]);

      expect(merged.colorBlindCues, isTrue);
      expect(merged.reduceMotion, isTrue);
      expect(merged.noFlashing, isTrue);
      expect(merged.captions, isFalse);
    });

    test('textScale fica no maior pedido', () {
      final merged = a11ySettingsForProfiles([
        A11yProfile.adhd,
        A11yProfile.lowVision,
      ]);

      expect(merged.textScale, 1.5);
    });

    test('letterSpacing fica no maior espaçamento', () {
      final merged = a11ySettingsForProfiles([
        A11yProfile.lowVision,
        A11yProfile.dyslexia,
      ]);

      expect(merged.letterSpacing, A11yLetterSpacing.wider);
    });

    test('lineHeight ignora os nulos e fica no maior', () {
      final merged = a11ySettingsForProfiles([
        A11yProfile.lowVision,
        A11yProfile.dyslexia,
        A11yProfile.hearingImpairment,
      ]);

      expect(merged.lineHeight, 1.8);
    });

    test('lineHeight continua nulo quando nenhum perfil define', () {
      final merged = a11ySettingsForProfiles([
        A11yProfile.colorBlindness,
        A11yProfile.hearingImpairment,
      ]);

      expect(merged.lineHeight, isNull);
    });

    test('fontFamily segue a prioridade fixa, não a ordem da lista', () {
      final ordemUm = a11ySettingsForProfiles([
        A11yProfile.lowVision,
        A11yProfile.dyslexia,
      ]);
      final ordemDois = a11ySettingsForProfiles([
        A11yProfile.dyslexia,
        A11yProfile.lowVision,
      ]);

      expect(ordemUm.fontFamily, A11yFontFamily.openDyslexic);
      expect(ordemDois.fontFamily, A11yFontFamily.openDyslexic);
    });

    test('contrastMode segue a prioridade fixa', () {
      final merged = A11ySettings.merge([
        const A11ySettings(contrastMode: A11yContrastMode.grayscale),
        const A11ySettings(contrastMode: A11yContrastMode.highContrast),
        const A11ySettings(contrastMode: A11yContrastMode.enhancedContrast),
      ]);

      expect(merged.contrastMode, A11yContrastMode.highContrast);
    });

    test('decorativeBackgrounds desliga se um único perfil pedir', () {
      final merged = a11ySettingsForProfiles([
        A11yProfile.hearingImpairment,
        A11yProfile.epilepsy,
      ]);

      expect(merged.decorativeBackgrounds, isFalse);
    });

    test('decorativeBackgrounds continua ligado sem quem peça o contrário', () {
      final merged = a11ySettingsForProfiles([
        A11yProfile.colorBlindness,
        A11yProfile.hearingImpairment,
      ]);

      expect(merged.decorativeBackgrounds, isTrue);
    });
  });

  group('A11ySettings — família tipográfica', () {
    test('standard não impõe fonte nenhuma', () {
      expect(A11yFontFamily.standard.familyName, isNull);
    });

    test('as demais nomeiam a família empacotada', () {
      expect(A11yFontFamily.hyperlegible.familyName, 'AtkinsonHyperlegible');
      expect(A11yFontFamily.lexend.familyName, 'Lexend');
      expect(A11yFontFamily.openDyslexic.familyName, 'OpenDyslexic');
    });
  });

  group('A11ySettings — contraste', () {
    test('a razão mínima acompanha o modo', () {
      expect(A11yContrastMode.standard.minimumContrastRatio, 0.0);
      expect(A11yContrastMode.grayscale.minimumContrastRatio, 0.0);
      expect(A11yContrastMode.enhancedContrast.minimumContrastRatio, 4.5);
      expect(A11yContrastMode.highContrast.minimumContrastRatio, 7.0);
    });

    test('grayscale não é tratado como reforço de contraste', () {
      expect(A11yContrastMode.grayscale.boostsContrast, isFalse);
      expect(A11yContrastMode.enhancedContrast.boostsContrast, isTrue);
      expect(A11yContrastMode.highContrast.boostsContrast, isTrue);
    });
  });

  group('A11ySettings — serialização', () {
    test('sobrevive à ida e volta', () {
      final original = a11ySettingsForProfiles([
        A11yProfile.dyslexia,
        A11yProfile.lowVision,
      ]);

      expect(A11ySettings.fromJson(original.toJson()), original);
    });

    test('mapa vazio devolve os padrões', () {
      expect(A11ySettings.fromJson({}), A11ySettings.defaults);
    });

    test('valores inválidos degradam em vez de lançar', () {
      final settings = A11ySettings.fromJson({
        'fontFamily': 'comic-sans',
        'contrastMode': 42,
        'letterSpacing': null,
        'textScale': 2,
      });

      expect(settings.fontFamily, A11yFontFamily.standard);
      expect(settings.contrastMode, A11yContrastMode.standard);
      expect(settings.letterSpacing, A11yLetterSpacing.normal);
      expect(settings.textScale, 2.0);
    });

    test('decorativeBackgrounds ausente volta ligado', () {
      expect(A11ySettings.fromJson({}).decorativeBackgrounds, isTrue);
    });
  });

  group('A11ySettings — igualdade', () {
    test('mesmos campos são iguais e compartilham hash', () {
      final um = a11ySettingsForProfiles([A11yProfile.adhd]);
      final dois = a11ySettingsForProfiles([A11yProfile.adhd]);

      expect(um, dois);
      expect(um.hashCode, dois.hashCode);
    });

    test('um campo diferente separa', () {
      const base = A11ySettings();

      expect(base.copyWith(boldText: true), isNot(base));
    });

    test('isDefault reconhece o estado neutro', () {
      expect(const A11ySettings().isDefault, isTrue);
      expect(a11ySettingsForProfiles([A11yProfile.adhd]).isDefault, isFalse);
    });

    test('changesTheme ignora ajustes que não são de tema', () {
      expect(const A11ySettings(captions: true).changesTheme, isFalse);
      expect(const A11ySettings(reduceMotion: true).changesTheme, isTrue);
      expect(
        const A11ySettings(fontFamily: A11yFontFamily.lexend).changesTheme,
        isTrue,
      );
    });
  });

  group('A11yProfile', () {
    test('nomes desconhecidos são descartados', () {
      expect(a11yProfilesFromNames(['dyslexia', 'blind', 7]), [
        A11yProfile.dyslexia,
      ]);
    });

    test('entrada que não é lista devolve vazio', () {
      expect(a11yProfilesFromNames('dyslexia'), isEmpty);
      expect(a11yProfilesFromNames(null), isEmpty);
    });

    test('repetições colapsam', () {
      expect(a11yProfilesFromNames(['adhd', 'adhd']), [A11yProfile.adhd]);
    });
  });
}
