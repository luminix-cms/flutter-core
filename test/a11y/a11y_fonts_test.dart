import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luminix_flutter/accessibility.dart';
import 'package:luminix_flutter/src/a11y/a11y_licenses.dart';

String _pubspec() => File('pubspec.yaml').readAsStringSync();

List<String> _assetsDeclarados() {
  return _pubspec()
      .split('\n')
      .map((linha) => linha.trim())
      .where(
        (linha) =>
            linha.startsWith('- asset: ') || linha.startsWith('- assets/'),
      )
      .map((linha) => linha.replaceFirst(RegExp(r'^- (asset: )?'), ''))
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('pubspec das fontes', () {
    test('declara as famílias que o resolvedor nomeia', () {
      final pubspec = _pubspec();

      for (final familia in A11yFontFamily.values) {
        final nome = familia.familyName;
        if (nome == null) continue;

        expect(pubspec, contains('- family: $nome'), reason: familia.name);
      }
    });

    test('todo asset declarado existe no disco', () {
      final assets = _assetsDeclarados();

      expect(assets, isNotEmpty);
      for (final asset in assets) {
        expect(File(asset).existsSync(), isTrue, reason: asset);
      }
    });

    test('só empacota Regular e Bold — itálico fica de fora', () {
      final fontes = _assetsDeclarados().where(
        (a) => a.endsWith('.ttf') || a.endsWith('.otf'),
      );

      expect(fontes, isNotEmpty);
      expect(fontes.where((a) => a.toLowerCase().contains('italic')), isEmpty);
    });

    test('o peso das fontes cabe no orçamento declarado', () {
      final bytes = _assetsDeclarados()
          .where((a) => a.endsWith('.ttf') || a.endsWith('.otf'))
          .map((a) => File(a).lengthSync())
          .fold<int>(0, (total, tamanho) => total + tamanho);

      expect(bytes, lessThan(700 * 1024));
    });
  });

  group('licenças das fontes', () {
    test('cada OFL empacotada é carregável e é mesmo a OFL 1.1', () async {
      for (final asset in a11yFontLicenseAssets) {
        final texto = await rootBundle.loadString(asset);

        expect(
          texto,
          contains('SIL Open Font License, Version 1.1'),
          reason: asset,
        );
      }
    });

    test('a OFL do OpenDyslexic é a de 2019, pós-relicenciamento', () async {
      final texto = await rootBundle.loadString(
        'packages/luminix_flutter/assets/fonts/OpenDyslexic/OFL.txt',
      );

      expect(texto, contains('2019-07-29'));
      expect(texto, contains('Abbie Gonzalez'));
    });

    test('o registro atribui as três ao package', () async {
      registerA11yFontLicenses();
      final entradas = await a11yFontLicenses().toList();

      expect(entradas, hasLength(a11yFontLicenseAssets.length));
      for (final entrada in entradas) {
        expect(entrada.packages, ['luminix_flutter']);
      }
    });

    test('registrar de novo não duplica a atribuição', () async {
      registerA11yFontLicenses();
      registerA11yFontLicenses();

      final doPackage = await LicenseRegistry.licenses
          .where((entrada) => entrada.packages.contains('luminix_flutter'))
          .toList();

      expect(doPackage, hasLength(a11yFontLicenseAssets.length));
    });
  });
}
