# Acessibilidade — tema

O `A11yThemeAdapter` transforma o `ThemeData` do app no `ThemeData` adaptado às configurações do usuário. É uma função pura: `adapt(ThemeData base, A11ySettings settings) → ThemeData`.

```dart
final adaptado = const A11yThemeAdapter().adapt(temaDoApp, settings);
```

O `A11yScope` chama isso sozinho. Você só precisa conhecer o adapter para sobrescrevê-lo ou para entender por que uma cor não mudou.

## Ordem das transformações

1. **Resolver o `ColorScheme`** — via `A11yColorSchemeResolver`
2. **Reconstruir o tema do app** a partir do esquema adaptado, se houver `themeRebuilder`, e **re-derivar** os campos legados
3. **Tipografia** — família, escala, espaçamento, altura de linha
4. **Movimento** — transições de rota zeradas e `NoSplash`
5. **Extensão** — `A11yThemeExtension` concatenada às extensões existentes
6. **Densidade** — `visualDensity: standard` e `materialTapTargetSize: padded` quando qualquer ajuste está ativo

> **Nota:** quando nenhuma configuração muda o tema, `adapt` devolve a base **idêntica**. Use `attachExtension` se precisar garantir que a `A11yThemeExtension` exista mesmo assim — é o que o `A11yScope` faz.

### Por que re-derivar os campos legados

`ThemeData.copyWith(colorScheme:)` **não** re-deriva `primaryColor`, `canvasColor`, `scaffoldBackgroundColor`, `cardColor`, `dividerColor` e `indicatorColor` — eles só são derivados no construtor de `ThemeData`. Trocar o `ColorScheme` sem tocar neles deixa o app com metade do alto contraste aplicado. O adapter faz isso à mão quando `contrastMode != standard`.

Os **temas de componente** do app têm o mesmo problema um nível acima, e o `copyWith` não os alcança de jeito nenhum — ver [Como escrever o `app_theme.dart`](#como-escrever-o-app_themedart).

### Por que concatenar as extensões

```dart
extensions: [...base.extensions.values, A11yThemeExtension(...)]
```

`copyWith(extensions:)` **substitui o mapa inteiro**. Concatenar é obrigatório: sem isso, a `ThemeExtension` própria do app desaparece silenciosamente assim que a acessibilidade é ligada.

## Contraste

Existem dois resolvers, ambos sem dependência nova.

### `A11yBoostedColorSchemeResolver` (padrão)

Percorre uma tabela fixa de pares primeiro-plano/fundo e empurra o primeiro plano na direção do polo preto ou branco, por busca binária sobre `Color.lerp`, até atingir a razão mínima.

| Modo | Razão mínima |
|------|:------------:|
| `standard` | — (não altera nada) |
| `enhancedContrast` | 4,5:1 |
| `highContrast` | 7,0:1 |

Pares verificados: `onPrimary`/`primary`, `onPrimaryContainer`/`primaryContainer`, `onSecondary`, `onSecondaryContainer`, `onTertiary`, `onTertiaryContainer`, `onError`, `onErrorContainer`, `onSurface`, `onSurfaceVariant`, `onInverseSurface`, `outline`, `outlineVariant`.

**Vantagem:** preserva a marca. Cada cor de fundo continua a do app; só o texto sobre ela se move.

> **Nota — limitação real em 7:1.** O resolver só ajusta o **primeiro plano**. Se a marca do app usa um `primary` de luminância média (um azul ou verde intermediário), nem preto nem branco alcançam 7:1 sobre ele — o resolver entrega o melhor possível, que pode ficar abaixo do alvo. Preenchimentos de marca com luminância média são incompatíveis com `highContrast` por construção. As saídas: escolher um `primary` mais escuro ou mais claro, ou usar o resolver semeado.

### `A11ySeededColorSchemeResolver`

```dart
A11yScope.builder(
  adapter: A11yThemeAdapter(
    colorSchemeResolver: A11ySeededColorSchemeResolver(seedColor: Color(0xFF0B5FFF)),
  ),
)
```

Usa `ColorScheme.fromSeed(contrastLevel: 0.0 / 0.5 / 1.0)` — a alavanca oficial do Material 3, que reconstrói o esquema inteiro com contraste garantido.

**Custo:** **descarta todo `copyWith` de papel que o app fez**. Um app que sobrescreveu dezoito papéis do `ColorScheme` perde os dezoito.

| | `A11yBoostedColorSchemeResolver` | `A11ySeededColorSchemeResolver` |
|---|---|---|
| Preserva a marca | Sim | Só a semente |
| Preserva overrides de papel | Sim | **Não** |
| Garante a razão alvo | Onde o fundo permite | Sim |
| Padrão | ✔ | Opt-in |

### `ColorScheme.highContrastLight/Dark` não são usados

São paletas Material 2 fixas, documentadas como não-M3, e ignoram completamente a marca do app.

### Tons de cinza

`A11yContrastMode.grayscale` **não** é uma transformação de esquema de cores — isso deixaria imagens, ilustrações e SVGs coloridos. É um `ColorFiltered` de tela inteira, o `A11yGrayscaleFilter`, montado pelo `A11yScope`.

> **Nota:** o filtro fica **sempre montado**, com matriz identidade quando desligado. Montar e desmontar um `ColorFiltered` ao vivo remonta a subárvore inteira do app durante um build e dispara `'!_debugDoingUpdate': is not true`. O custo é um `saveLayer` de tela cheia por frame — meça no aparelho-alvo mais fraco.

## Tipografia

`applyA11yTypography` reconstrói os quinze papéis do `TextTheme` por `copyWith`, um a um.

### A armadilha do `TextTheme` const

Um `TextTheme` recém-construído tem os quinze papéis **nulos**. `TextTheme.apply(fontFamily:)` sobre um estilo nulo devolve nulo, e o `ThemeData` mescla de volta na tipografia padrão — o resultado é que família, espaçamento e altura de linha **nunca chegam a nenhum `Text`**. O adapter parte sempre do `TextTheme` **já materializado** do tema base.

`TextTheme.apply` também não serve para os outros dois: `letterSpacingFactor`/`Delta` e `heightFactor`/`Delta` são relativos, viram no-op sobre nulo e *assertam* quando a base é nula.

### Fontes de pacote

```dart
base.copyWith(fontFamily: 'AtkinsonHyperlegible', package: 'luminix_flutter')
```

`TextStyle` guarda o pacote e **re-prefixa**: passar `'packages/luminix_flutter/Lexend'` a um estilo que já nasceu com `package:` produz `packages/<app>/packages/luminix_flutter/Lexend` e cai silenciosamente na fonte da plataforma. Sempre o nome puro da família mais `package:`.

O `fontFamilyFallback` mantém a fonte da marca como reserva de glifo — a cobertura do OpenDyslexic é magra.

### Espaçamento entre letras em `em`

```
letterSpacing = (base.letterSpacing ?? 0) + em * (base.fontSize ?? 14)
```

`letterSpacing` é medido em pixels lógicos e **não é escalado pelo `TextScaler`**. Um valor fixo de 1,2 px é invisível no `displayLarge` (57 px) e destrói o `labelSmall` (11 px). A WCAG 1.4.12 especifica `0.12em`, que é o valor de `wider`; `wide` é `0.06em`. Somar em vez de substituir preserva o *tracking* por papel do Material 3.

| `A11yLetterSpacing` | Valor |
|---------------------|-------|
| `normal` | 0 |
| `wide` | 0,06 em |
| `wider` | 0,12 em |

### Escala de texto

`A11yTextScaler` **compõe** com o escalonador do sistema operacional e só então limita:

```
efetivo = clamp(escala_do_sistema × escala_do_usuário, max: maxTextScale)
```

Sistema em 1,3× e usuário em "GG" (1,5×) resulta em 1,95×, limitado pelo `maxTextScale` de 2,0. Descartar a escala do sistema — o erro fácil aqui — reduziria a fonte de quem já a tinha aumentado no aparelho.

> **Nota:** com a acessibilidade **desligada**, o escopo é transparente: nenhum `MediaQuery` é inserido e o `maxTextScale` não se aplica. Limitar a escala de quem nunca pediu acessibilidade seria uma regressão.

## Movimento

`MediaQueryData.disableAnimations` é quase inerte: `AnimationController` lê `SemanticsBinding.instance.disableAnimations`, não o `MediaQuery`. Por isso `reduceMotion` é estrutural:

- `pageTransitionsTheme` com `A11yNoTransitionsBuilder`
- `splashFactory: NoSplash.splashFactory`
- `A11yThemeExtension.reduceMotion` para o app consultar

> **Nota:** um `PageTransitionsBuilder` que apenas retorna o `child` **continua bloqueando 300 ms** — a duração é da rota, não do builder. `A11yNoTransitionsBuilder` sobrescreve `transitionDuration` **e** `reverseTransitionDuration` para `Duration.zero`.

## `A11yThemeExtension`

Cada campo existe porque tem um consumidor nomeado.

| Campo | Tipo | Para que serve |
|-------|------|----------------|
| `contrastMode` | `A11yContrastMode` | Modo corrente |
| `isHighContrast` | `bool` | O app suprime gradiente, sombra e imagem de fundo |
| `reduceMotion` | `bool` | O app desliga animação própria |
| `decorativeBackgrounds` | `bool` | O app remove ornamento |
| `borderWidth` | `double` | Bordas mais grossas em alto contraste |
| `focusRingColor` / `focusHaloColor` | `Color` | Anel de foco |
| `focusRingWidth` / `focusHaloWidth` | `double` | `(2,0)` padrão, `(2,3)` reforçado, `(3,4)` máximo |
| `minTapTarget` | `double` | Alvo mínimo, 48 dp |

```dart
final a11y = A11yThemeExtension.of(context);
if (a11y.isHighContrast) {
  // fundo chapado no lugar do gradiente
}
```

`of(context)` é tolerante: sem escopo, devolve o `fallback` const. Nunca lança, e nunca exige guarda de DI.

## Como escrever o `app_theme.dart`

O adapter alcança o `ColorScheme` e o `TextTheme` do `ThemeData`. Ele **não** alcança um `Color` que já esteja materializado em outro lugar. São dois casos com soluções diferentes.

### 1. Cor dentro de um widget — resolva o papel na hora do build

O widget lê o tema a cada build, e sob o escopo o tema já é o adaptado. Basta não escrever o literal:

```dart
// Não faça:
Container(color: Colors.white, child: Text('Olá', style: TextStyle(color: Color(0xFF101828))))

// Faça:
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text('Olá', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
)
```

### 2. Cor dentro de um tema de componente — use `themeRebuilder`

Aqui trocar o literal pelo papel **não basta**, e é a armadilha mais cara da integração:

```dart
// Isto NÃO é melhor que Color(0xFFD0D5DD) para o adapter:
inputDecorationTheme: InputDecorationTheme(
  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: scheme.outline)),
)
```

`scheme.outline` é lido **quando o `ThemeData` é construído**, no `main()`, muito antes de o escopo existir. O que fica guardado no `inputDecorationTheme` é o valor, não o papel — um `Color` tão congelado quanto o literal. O `copyWith(colorScheme:)` do adapter troca o esquema e não tem como reescrever os temas de componente que o app derivou dele.

O sintoma é exato: `Theme.of(context).colorScheme.outline` sobe de 4.27:1 para 7.00:1, e a borda do campo continua na cor antiga.

A saída é o app entregar a **função** de tema em vez do valor, para o escopo poder reconstruí-lo a partir do esquema adaptado:

```dart
// lib/core/app_theme.dart — o esquema passa a entrar de fora
class AppTheme {
  const AppTheme({this.seedColor = const Color(0xFF3667B4)});

  final Color seedColor;

  ThemeData toThemeData([ColorScheme? scheme]) {
    final colorScheme = scheme ?? ColorScheme.fromSeed(seedColor: seedColor);

    return ThemeData(
      colorScheme: colorScheme,
      inputDecorationTheme: InputDecorationTheme(
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline),
        ),
      ),
    );
  }
}

const defaultTheme = AppTheme();
```

```dart
// lib/main.dart
a11y: A11yConfiguration(themeRebuilder: defaultTheme.toThemeData),
```

```dart
// e o MaterialApp segue igual
MaterialApp(
  theme: defaultTheme.toThemeData(),
  builder: A11yScope.builder(),
)
```

Com isso o adapter resolve o `ColorScheme`, chama `themeRebuilder(esquemaAdaptado)` para o app refazer o próprio `ThemeData`, e só então força o esquema e re-deriva os campos legados. O esquema **não** é resolvido de novo sobre o tema reconstruído: `a11yEnsureContrast` devolveria a cor intacta, mas um papel novo que o app tenha derivado do esquema recebido acabaria adaptado duas vezes.

> **Nota:** `themeRebuilder` também aceita ser passado direto no adapter (`A11yThemeAdapter(themeRebuilder: ...)`), que vence sobre o da configuração. O da configuração é o caminho normal — mantém `A11yScope.builder()` sem parâmetros.

Sem `themeRebuilder`, o alto contraste alcança o `ColorScheme`, o `TextTheme`, os campos legados (`cardColor`, `dividerColor`, …) e todo widget que resolve o papel no build — só não alcança os temas de componente. É um meio-termo utilizável, não o padrão.

### Tabela de conversão

| Literal comum | Papel correspondente |
|---------------|----------------------|
| `Colors.white` (fundo de tela) | `colorScheme.surface` |
| `Colors.white` (texto sobre a marca) | `colorScheme.onPrimary` |
| Cinza de borda | `colorScheme.outline` / `outlineVariant` |
| Cinza de texto secundário | `colorScheme.onSurfaceVariant` |
| Vermelho de erro | `colorScheme.error` / `onError` |
| Cor da marca em botão | `colorScheme.primary` |

## Próximos passos

- [Acessibilidade — widgets](acessibilidade-widgets.md) — os primitivos que consomem a extensão
- [Acessibilidade — testes](acessibilidade-testes.md) — como provar as razões de contraste
