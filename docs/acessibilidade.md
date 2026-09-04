# Acessibilidade

Esta é a página do padrão. Todo app Luminix novo nasce com esta camada ligada, e todo app existente deve migrar para ela.

## Por que existe

| Norma | O que exige |
|-------|-------------|
| **WCAG 2.2 nível AA** | Contraste mínimo, alvos de toque, foco visível, texto redimensionável até 200%, movimento controlável |
| **LBI 13.146/2015** (Lei Brasileira de Inclusão) | Acessibilidade em sistemas de informação e comunicação de uso público ou de interesse coletivo |
| **eMAG** | Modelo de acessibilidade em governo eletrônico, referência em contratos públicos |

Acessibilidade não é uma feature do fim do backlog: quando é retrofitada, cada tela precisa ser reescrita. Quando nasce na base, o custo por tela é próximo de zero.

## Os dois pontos de integração

### 1. Ligar a capacidade

```dart
LuminixApp(
  configuration: AppConfiguration(
    a11y: const A11yConfiguration(),
  ),
  child: const MyApp(),
)
```

`a11y` nulo (o padrão) desliga tudo: nenhum I/O acontece, nenhum serviço é registrado, nenhum widget é montado.

### 2. Costurar no `MaterialApp`

```dart
MaterialApp(
  theme: appTheme,
  builder: A11yScope.builder(),
  home: const HomeScreen(),
)
```

Se o app já usa `builder:`, componha:

```dart
builder: A11yScope.builder(next: meuBuilderAtual),
```

Nenhum widget de tela precisa mudar para herdar tema adaptado, escala de texto, contraste e a Central de Acessibilidade.

### O terceiro ponto, se o app tem temas de componente

Se o `app_theme.dart` define `inputDecorationTheme`, `cardTheme`, `filledButtonTheme` e afins, entregue também a função que os constrói:

```dart
a11y: A11yConfiguration(themeRebuilder: defaultTheme.toThemeData),
```

Sem isso, o alto contraste alcança o `ColorScheme` e não alcança os temas de componente — eles guardam o valor que o app leu do esquema na hora do `main()`, não o papel. Trocar `Color(0xFFD0D5DD)` por `scheme.outline` **não resolve sozinho**; ver [Como escrever o `app_theme.dart`](acessibilidade-tema.md#como-escrever-o-app_themedart).

## Por que `MaterialApp.builder`

O `builder` é o único ponto da árvore que satisfaz as quatro condições ao mesmo tempo:

- **Abaixo do `Theme` do app** — `Theme.of(context)` devolve exatamente o `ThemeData` não adaptado que o adapter precisa como entrada, sem cooperação nenhuma do app.
- **Acima do `Navigator`** — toda rota herda os ajustes, incluindo rotas empilhadas depois.
- **Abaixo do `MediaQuery`** — o escopo lê a escala de texto do sistema para compor com a do usuário em vez de descartá-la.
- **Abaixo do `Localizations`** — e portanto abaixo do `Directionality`, que vem dele.

### Limitações conhecidas

| Limitação | Consequência |
|-----------|--------------|
| `ScaffoldMessenger` e `DefaultSelectionStyle` nascem **acima** do escopo | A cor das alças de seleção de texto não segue o alto contraste |
| O host da Central é **irmão** do `Navigator`, não descendente | O FAB não pode usar `Tooltip` nem `showModalBottomSheet`; a Central é apresentada pelo próprio host |
| Observers do `WidgetsBinding` são notificados na ordem de registro, e o `WidgetsApp` registra primeiro | Com uma rota empilhada, o botão voltar do sistema desempilha a rota antes de fechar a Central. Na rota raiz — o caso comum do FAB — a Central fecha primeiro |
| `MediaQueryData.disableAnimations` é quase inerte no framework | `reduceMotion` é implementado estruturalmente: transições de rota zeradas, `NoSplash`, e uma flag na `A11yThemeExtension` |

## O que o core resolve

- Perfis combináveis, com persistência por dispositivo ou por usuário
- Adaptação do `ThemeData`: contraste, tipografia, escala, movimento
- Fontes de alta legibilidade embarcadas
- Primitivos com semântica correta (`A11yLabeledButton`, `A11yFocusRing`, `A11yTapTarget`, …)
- Central de Acessibilidade e tela de onboarding prontas, sobrescrevíveis peça a peça

## O que continua sendo do app

- **Cor literal em widget.** Nenhum adapter alcança um `Color(0xFF...)` escrito à mão. Escreva com papéis de `ColorScheme` — veja [acessibilidade — tema](acessibilidade-tema.md).
- **Semântica de tela.** O core dá os primitivos; usar `A11ySemanticsHeader`, rotular imagens e agrupar campos é trabalho de cada tela.
- **Flags que o core modela mas não implementa.** `oneItemPerScreen` e `colorBlindCues` ficam disponíveis em `A11ySettings` e inertes no core: implementá-las exige paginar o estado de uma tela concreta.
- **Legendas e sinais visuais de som.** `captions` e `visualCuesForSound` são lidas pelo app no seu player.

## Critérios de aceite

Toda tela nova de um app Luminix deve satisfazer:

1. Todo interativo tem rótulo de semântica e papel (`button`, `header`, `selected`, `toggled`).
2. Todo alvo de toque mede no mínimo **48 dp**, com 8 dp de separação entre alvos vizinhos.
3. A tela é testada em `TextScaler.linear(2.0)` numa viewport de 320×568 e não estoura.
4. **Cor nunca é sinal único**: seleção, erro e estado são sinalizados também por ícone, texto ou forma.
5. Toda tela de ajuste mostra pré-visualização ao vivo do efeito.
6. No máximo **cinco** grupos de controle por tela.
7. Nada de CAIXA ALTA em rótulo longo — prejudica a leitura para dislexia.

## Configuração

Veja a tabela completa de `A11yConfiguration` em [acessibilidade — widgets](acessibilidade-widgets.md#a11yconfiguration).

## Próximos passos

- [Acessibilidade — perfis](acessibilidade-perfis.md) — o que cada perfil ativa e como eles se combinam
- [Acessibilidade — tema](acessibilidade-tema.md) — como escrever o `app_theme.dart` para que o contraste funcione
- [Acessibilidade — testes](acessibilidade-testes.md) — como provar que a tela passa
