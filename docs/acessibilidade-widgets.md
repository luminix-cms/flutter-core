# Acessibilidade — widgets

O pacote entrega duas camadas: **primitivos**, que o app compõe nas suas telas, e **telas prontas**, que o app liga e opcionalmente sobrescreve peça a peça.

## Primitivos

Todos funcionam com ou sem o `A11yScope` montado — sem escopo, caem no `fallback` const da `A11yThemeExtension`.

| Widget | Papel |
|--------|-------|
| `A11yLabeledButton` | O tocável base. Semântica, anel de foco e alvo de 48 dp num só widget |
| `A11yFocusRing` | Anel de foco sobre `FocusableActionDetector` |
| `A11yTapTarget` | Garante 48 dp de área tocável com 4 dp de margem |
| `A11yGrayscaleFilter` | Filtro de tons de cinza, sempre montado |
| `A11ySemanticsHeader` | Marca um texto como cabeçalho de seção |
| `A11yActionButton` | Botão de ação com ênfase preenchida, contornada ou plana |
| `A11yChoiceRow<T>` | Escolha única entre opções curtas |
| `A11ySwitchTile` | Alternador com rótulo e descrição |
| `A11yContrastSwatchRow` | Os quatro modos de contraste, nomeados |
| `A11yProfileCard` | Cartão de perfil |
| `A11yPreviewCard` | Pré-visualização ao vivo dos ajustes pendentes |

### `A11yLabeledButton` — o mais importante

```dart
A11yLabeledButton(
  label: 'Salvar cadastro',
  hint: 'Envia os dados preenchidos',
  onPressed: _salvar,
  child: const Icon(Icons.check),
)
```

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `label` | `String` | Sim | O que o leitor de tela anuncia |
| `child` | `Widget` | Sim | O conteúdo visual |
| `onPressed` | `VoidCallback?` | Não | Nulo desabilita o botão |
| `enabled` | `bool` | Não | Padrão `true`; falso desabilita mesmo com `onPressed` |
| `hint` | `String?` | Não | Complemento anunciado depois do rótulo |
| `selected` | `bool?` | Não | Estado de seleção (cartões, chips) |
| `toggled` | `bool?` | Não | Estado de alternância (switches) |
| `excludeSemantics` | `bool` | Não | Descarta a semântica do conteúdo; padrão `true` |
| `minTapTarget` | `double?` | Não | Sobrescreve o mínimo da extensão de tema |
| `margin` | `EdgeInsetsGeometry` | Não | Separação entre alvos; padrão 4 dp |
| `borderRadius` | `BorderRadiusGeometry?` | Não | Geometria do anel de foco |
| `focusNode`, `autofocus` | | Não | Controle de foco |

> **Nota — o achado que este widget existe para não deixar esquecer.** Sem `onTap` no **próprio** `Semantics`, o TalkBack lê o rótulo mas o duplo-toque não ativa nada. Com `excludeSemantics: true`, o nó do `GestureDetector` é descartado — e junto com ele a ação de toque. O `A11yLabeledButton` declara `onTap` no `Semantics` externo justamente por isso. Todo tocável do pacote nasce daqui.

> **Nota — foco.** Pelo mesmo motivo, o widget reporta `focused` no `Semantics` externo: sem isso, *switch access* e navegação por teclado perdem o botão. E é `focused`, não `focusable` — no Flutter 3.41 `isFocusable` é **derivado** de `isFocused`, então declarar `focused: false` num botão desabilitado o tornaria focável.

### `A11yFocusRing`

Cobre teclado físico, D-pad e *switch access*, com `ActivateIntent` (Enter, Espaço, NumPad Enter) já mapeado. `onShowFocusHighlight` distingue foco de teclado de foco por toque, então o anel não aparece em toque.

> **Nota:** o anel **não** sincroniza com o cursor de exploração do leitor de tela — TalkBack e VoiceOver desenham o próprio retângulo de foco.

### `A11yTapTarget`

`MaterialTapTargetSize.padded` só cobre botões Material. Qualquer coisa desenhada à mão — um ícone de 16 dp num `GestureDetector` — reprova no `androidTapTargetGuideline`. `A11yTapTarget` resolve com `ConstrainedBox(minWidth: 48, minHeight: 48)` mais 4 dp de margem, o que garante os 8 dp de separação entre alvos vizinhos.

> **Nota:** um `GestureDetector` dimensiona-se pelo filho. Se ele ficar **dentro** do `A11yTapTarget`, a área tocável volta a ser a do ícone. No `A11yLabeledButton` o gesto fica **por fora**.

## Telas prontas

### Central de Acessibilidade

Com `showFab: true` (o padrão), o `A11yScope` já desenha o FAB e apresenta a Central. Nada a fazer.

Para abrir de um item de menu, de dentro de uma rota:

```dart
onTap: () => showA11yCenter(context),
```

São **dois apresentadores para um único widget de conteúdo**:

| Apresentador | Onde vive | Como apresenta |
|--------------|-----------|----------------|
| `A11yCenterHost` (automático) | Acima do `Navigator` | `ModalBarrier` + `SlideTransition` + `FocusScope` + `Semantics(scopesRoute:)` |
| `showA11yCenter(context)` | Abaixo do `Navigator` | `showModalBottomSheet` |

> **Nota:** um widget montado no `MaterialApp.builder` é **irmão** do `Navigator`, não descendente — não tem `Navigator` nem `Overlay` ancestral. `showModalBottomSheet` lança dali, e `Tooltip` lança no long-press. É por isso que o host apresenta a Central por conta própria e o FAB não usa `Tooltip`.

Para esconder o FAB numa rota específica (uma câmera, um vídeo em tela cheia):

```dart
A11yFabVisibility(visible: false, child: minhaTela)
```

### Modelo *pendente-então-aplicar*

A Central não aplica ajuste a cada toque. O `A11yCenterController` mantém um registro **pendente**; o serviço só é tocado em "Aplicar ajustes".

```dart
final controller = A11yCenterController(service: service);
controller.toggleProfile(A11yProfile.dyslexia); // nada foi persistido
controller.isDirty;                              // true
await controller.apply();                        // agora sim
```

A pré-visualização ao vivo é o `A11yPreviewCard`, que reconstrói o **próprio** `MediaQuery`, `Theme` e filtro a partir do pendente. Ele parte do tema **base** do app, nunca do já adaptado — adaptar duas vezes empilharia contraste sobre contraste. E limita a escala em `previewMaxTextScale` (1,6 por padrão, abaixo do teto global de 2,0) para o cartão não estourar a própria caixa.

Um ajuste feito por outra superfície do app alcança a Central: se a seleção pendente ainda está limpa, ela acompanha; se a pessoa já mexeu em algo, a seleção dela é preservada.

### Tela de onboarding

```dart
if (!service.onboardingCompleted) {
  return A11yOnboardingScreen(
    service: service,
    onFinished: () => Navigator.of(context).pushReplacementNamed('/'),
  );
}
```

"Continuar" aplica a seleção e marca o onboarding como concluído. "Pular por agora" descarta a seleção pendente e marca o onboarding — quem não confirmou não escolheu.

## Sobrescrita por builder

A sobrescrita é por **callback**, não por subclasse (widgets são `@immutable`). Estilo flui por `ThemeData` e `A11yThemeExtension`; **estrutura** flui pelos builders.

```dart
a11y: A11yConfiguration(
  fabBuilder: (context, abrirCentral) => MeuFab(onTap: abrirCentral),
  profileCardBuilder: (context, perfil, selecionado, alternar) =>
      MeuCartao(perfil: perfil, selecionado: selecionado, onTap: alternar),
)
```

### `A11yConfiguration`

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `enabled` | `bool` | Não | Padrão `true`. Falso deixa o escopo transparente |
| `showFab` | `bool` | Não | Padrão `true` |
| `fabAlignment` | `AlignmentGeometry` | Não | Padrão `Alignment.bottomRight` |
| `fabPadding` | `EdgeInsetsGeometry` | Não | Padrão 16 dp |
| `profiles` | `List<A11yProfile>` | Não | Quais perfis a Central oferece |
| `scope` | `A11yScopeMode` | Não | `device` (padrão) ou `user` |
| `persistManualOverrides` | `bool` | Não | Padrão `true` |
| `awaitUserScopeOnBoot` | `bool` | Não | Aguarda a identidade antes de liberar o boot |
| `maxTextScale` | `double` | Não | Teto global; padrão 2,0 |
| `previewMaxTextScale` | `double` | Não | Teto da pré-visualização; padrão 1,6 |
| `textScaleSteps` | `List<double>` | Não | Padrão `[1.0, 1.15, 1.3, 1.5]` (P, M, G, GG) |
| `strings` | `A11yStrings` | Não | Todos os textos, PT-BR |
| `icons` | `A11yIcons` | Não | Todos os ícones |
| `seedColor` | `Color?` | Não | Semente para o resolver semeado |
| `fontFamilyOverrides` | `Map<A11yFontFamily, A11yFontOverride>` | Não | Aponta uma família para asset próprio |
| `themeRebuilder` | `A11yThemeRebuilder?` | Não | Refaz o `ThemeData` do app a partir do esquema adaptado — sem ele o alto contraste não alcança os temas de componente ([tema](acessibilidade-tema.md#como-escrever-o-app_themedart)) |
| `fabBuilder` | `A11yFabBuilder?` | Não | Substitui o FAB |
| `centerBuilder` | `A11yCenterBuilder?` | Não | Substitui a Central inteira |
| `profileCardBuilder` | `A11yProfileCardBuilder?` | Não | Substitui o cartão de perfil |
| `profileIconBuilder` | `A11yProfileIconBuilder?` | Não | Substitui só os ícones de perfil |
| `previewBuilder` | `A11yPreviewBuilder?` | Não | Substitui a pré-visualização |

## Ícones e textos

Os ícones são `Icons.*` do Material por padrão — `visibility_outlined`, `palette_outlined`, `bolt_outlined`, `psychology_outlined`, `menu_book_outlined`, `hearing_outlined`. **Sem `flutter_svg`**: seriam cinco a sete pacotes transitivos para sete glifos de 1 a 3 KB.

Os textos são `A11yStrings` const em PT-BR. **Sem `flutter_localizations`**: ele fixa `intl: 0.20.2` exato, e forçar um upgrade em lockstep por um pacote de um único idioma não se paga. Migrar para ARB depois não muda nenhuma assinatura de widget.

## Lendo o estado numa tela

```dart
final scope = A11yScopeData.of(context);
scope.settings;      // A11ySettings resolvido
scope.configuration; // A11yConfiguration
scope.centerIsOpen;  // bool
scope.openCenter();  // abre a Central
```

`A11yScopeData.maybeOf(context)` devolve nulo fora do escopo, sem lançar.

## Próximos passos

- [Acessibilidade — testes](acessibilidade-testes.md) — como provar que a tela está correta
- [Acessibilidade — tema](acessibilidade-tema.md) — de onde vêm as cores desses widgets
