# Instalação

O `luminix_flutter` é publicado no registro privado da AranduTech e também pode ser consumido diretamente do repositório Git.

## Dependência Git

```yaml
dependencies:
  luminix_flutter:
    git:
      url: https://github.com/luminix-cms/flutter-core
      ref: new_pattern
```

> **Nota:** `new_pattern` é o *trunk* do repositório — não `master`. O `pubspec.lock` do app fixa o commit resolvido, então atualizar o pacote é sempre um passo explícito (`flutter pub upgrade luminix_flutter`).

## Requisitos no `pubspec.yaml` do app

```yaml
flutter:
  uses-material-design: true
```

Sem `uses-material-design`, os ícones da Central de Acessibilidade (e de qualquer widget Material) não são embarcados no bundle.

## Dependências transitivas

| Pacote | Origem |
|--------|--------|
| `dio` | Cliente HTTP |
| `shared_preferences` | Persistência local (auth e acessibilidade) |
| `get_it` | Localizador de serviços do `LuminixServiceProvider` |
| `collection`, `dartx`, `path`, `args`, `http`, `qs_dart` | Utilitários |

A camada de acessibilidade **não adiciona nenhuma dependência nova**: sem `flutter_svg`, sem `google_fonts`, sem `intl`, sem `provider`.

## Custo de bundle das fontes

O pacote embarca três famílias de alta legibilidade, em peso regular e negrito apenas:

| Família | Licença | Tamanho aproximado |
|---------|---------|--------------------|
| Atkinson Hyperlegible | OFL 1.1 | ~110 KB |
| Lexend (variável) | OFL 1.1 | ~172 KB |
| OpenDyslexic | OFL 1.1 | ~360 KB |
| **Total** | | **~645 KB** |

> **Nota:** fontes **não são *tree-shaken***. O custo entra em todo app consumidor, esteja a acessibilidade ligada ou não. A compressão do APK/AAB recupera aproximadamente 40–50% disso. Se o app já embarca uma família equivalente, use `A11yConfiguration.fontFamilyOverrides` para apontar o pacote para o asset próprio.

## Verificação

```bash
flutter pub get
flutter analyze
flutter test
```

## Próximos passos

- [Inicialização](inicializacao.md) — monte o `LuminixApp` e configure os providers
- [Acessibilidade](acessibilidade.md) — ligue a camada de acessibilidade
