# Luminix Flutter — Documentação

Bem-vindo à documentação do **`luminix_flutter`**, o pacote base do ecossistema Luminix para aplicações Flutter. Ele fornece o container de injeção de dependências, o cliente HTTP, a camada de modelos e — a partir da versão atual — a **camada de acessibilidade** que é o padrão da base para todo app Luminix novo.

## Visão geral

Um app Luminix é montado sobre três peças:

1. **`LuminixApp`** — o widget raiz que constrói o `Application` (container de DI), roda os *service providers* e só então libera a árvore do app.
2. **`AppConfiguration`** — a configuração declarativa que liga cada capacidade: `manifest`, `auth`, `a11y`.
3. **`MaterialApp`** — o app Flutter propriamente dito, com um único ponto de costura para a acessibilidade: `builder: A11yScope.builder()`.

A acessibilidade não é uma biblioteca à parte: ela é **parte do padrão da base**. Um app novo nasce com perfis de acessibilidade, tema adaptável, fontes de alta legibilidade e a Central de Acessibilidade, escrevendo duas linhas.

## Páginas da documentação

| Página | Descrição |
|--------|-----------|
| [Instalação](instalacao.md) | Como adicionar o `luminix_flutter` a um projeto Flutter |
| [Inicialização](inicializacao.md) | `LuminixApp`, `AppConfiguration`, providers e a ordem de boot |
| [Acessibilidade](acessibilidade.md) | **O padrão da base**: por que existe, como ligar, o que é do core e o que é do app |
| [Acessibilidade — perfis](acessibilidade-perfis.md) | Os seis perfis, a matriz de flags e as regras de combinação |
| [Acessibilidade — tema](acessibilidade-tema.md) | `A11yThemeAdapter`, contraste, tipografia e `A11yThemeExtension` |
| [Acessibilidade — widgets](acessibilidade-widgets.md) | Primitivos, telas prontas e sobrescrita por builder |
| [Acessibilidade — testes](acessibilidade-testes.md) | Semântica, diretrizes, escala 2.0 e o runbook de atualização |

## Pré-requisitos

- Flutter `3.41.7` ou superior
- Dart SDK `^3.10.0`
- `uses-material-design: true` no `pubspec.yaml` do app (os ícones da Central vêm da fonte Material)

## Próximos passos

- [Instalação](instalacao.md) — comece por aqui
- [Acessibilidade](acessibilidade.md) — o padrão que todo app Luminix novo deve seguir
