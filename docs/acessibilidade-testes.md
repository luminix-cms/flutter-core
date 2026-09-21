# Acessibilidade — testes

Acessibilidade que não é testada regride no primeiro refactor. Esta página é o que colar num teste de tela nova.

## Semântica

A semântica só é computada quando alguém a pede. Sem `ensureSemantics()`, `getSemantics` lança `StateError: Semantics are not enabled`. Sempre `dispose()` no handle ao fim do teste.

```dart
testWidgets('o botão anuncia rótulo, papel e ação', (tester) async {
  final handle = tester.ensureSemantics();

  await tester.pumpWidget(const MaterialApp(
    home: Scaffold(body: A11yLabeledButton(
      label: 'Salvar cadastro',
      onPressed: _salvar,
      child: Icon(Icons.check),
    )),
  ));

  expect(
    tester.getSemantics(find.byType(A11yLabeledButton)),
    isSemantics(
      label: 'Salvar cadastro',
      isButton: true,
      hasTapAction: true,
      isEnabled: true,
    ),
  );

  handle.dispose();
});
```

| Matcher | Para |
|---------|------|
| `isSemantics(...)` | Rótulo, dica, papel e ações de um nó |
| `isSelected` | Cartões e chips |
| `isToggled` | Alternadores |
| `isHeader` | `A11ySemanticsHeader` |
| `hasTapAction` | **O que prova que o duplo-toque do leitor de tela funciona** |

> **Nota:** `containsSemantics` está descontinuado no Flutter 3.41 — use `isSemantics`.

### O que o leitor de tela realmente anuncia

`find.bySemanticsLabel` inspeciona a configuração de cada `RenderObject` e **não enxerga um `ExcludeSemantics` ancestral**. Para verificar o que é de fato anunciado, percorra a travessia compilada:

```dart
List<String> rotulosAnunciados(WidgetTester tester) => tester.semantics
    .simulatedAccessibilityTraversal()
    .map((node) => node.label)
    .where((label) => label.isNotEmpty)
    .toList();

expect(rotulosAnunciados(tester), isNot(contains('tela do app')));
```

É assim que se prova que, com a Central aberta, o app saiu da árvore de semântica.

Para tocar por semântica em vez de por posição:

```dart
await tester.semantics.tap(find.semantics.byLabel('Abrir ajustes de acessibilidade'));
```

## Diretrizes automáticas

```dart
await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
```

`androidTapTargetGuideline` é o que reprova alvos abaixo de 48 dp — a falha mais comum.

> **Nota:** `textContrastGuideline` só serve em superfície chapada. Ele lança `StateError` quando não consegue resolver o fundo e dá falso positivo sobre gradiente ou imagem. **Não** rode sobre o `A11yPreviewCard`.

## O pior caso: escala 2.0 numa tela pequena

Toda tela nova precisa deste teste. É o que pega `Row` sem `Expanded`, `SizedBox` de altura fixa e `GridView.count(childAspectRatio:)`.

```dart
const apertado = MediaQueryData(
  size: Size(320, 568),
  textScaler: TextScaler.linear(2.0),
  boldText: true,
);

testWidgets('em 2.0 e 320 dp a tela não estoura', (tester) async {
  await tester.pumpWidget(MediaQuery(
    data: apertado,
    child: MaterialApp(home: MinhaTela()),
  ));
  await tester.pumpAndSettle();

  expect(tester.takeException(), isNull);

  await tester.tap(find.text('Continuar'));
  await tester.pump();
  expect(tester.takeException(), isNull);
});
```

Assertar `takeException()` nulo **e** que o rodapé segue clicável: um `RenderFlex overflow` não impede o toque, mas um botão empurrado para fora da viewport impede.

### Padrões que sobrevivem a 2.0

| Em vez de | Use |
|-----------|-----|
| `GridView.count(childAspectRatio:)` | `LayoutBuilder` + `Wrap` com largura calculada |
| `SizedBox(height:)` numa folha | `ConstrainedBox(maxHeight:)` |
| `Column` + `Expanded` dentro de altura não fixa | `Column(mainAxisSize: min)` + `Flexible` |
| Texto em uma linha com `overflow` | Deixar quebrar |

## Contraste

```dart
for (final pair in A11yBoostedColorSchemeResolver.pairs) {
  final scheme = const A11yBoostedColorSchemeResolver()
      .resolve(base, const A11ySettings(contrastMode: A11yContrastMode.enhancedContrast));

  expect(
    a11yContrastRatio(pair.foreground(scheme), pair.background(scheme)),
    greaterThanOrEqualTo(4.5),
    reason: pair.name,
  );
}
```

> **Nota:** o alvo de 7:1 (`highContrast`) **não é alcançável sobre todo fundo**. Um `primary` de luminância média não atinge 7:1 nem com preto nem com branco. Se o teste do app falhar em 7:1 num papel de marca, a correção é escolher um `primary` mais escuro ou mais claro — não afrouxar o teste.

## Regressões que o pacote guarda

Estes testes existem porque cada um deles já foi um defeito real. Copie o padrão ao estender a camada.

| O que provar | Por quê |
|--------------|---------|
| Os quinze papéis do `TextTheme` recebem a família de pacote | Partir de um `TextTheme` const deixa os papéis nulos e a família nunca chega |
| Uma base criada com `package:` não gera prefixo duplo | `TextStyle` re-prefixa o nome da família |
| A `ThemeExtension` do app sobrevive ao `adapt` | `copyWith(extensions:)` substitui o mapa inteiro |
| Sistema 1,3 × usuário 1,5 limita em 2,0 | A escala do SO precisa ser composta, não descartada |
| `reduceMotion` produz `transitionDuration == Duration.zero` | Um builder que só retorna o child ainda bloqueia 300 ms |
| Abrir a Central pelo FAB não lança sem `Navigator` ancestral | O host é irmão do `Navigator` |
| `A11yThemeExtension.of` num `ThemeData` pelado devolve o `fallback` | Nenhum widget pode exigir o escopo |
| Sem serviço, o app renderiza intocado | Acessibilidade nunca impede o app de renderizar |

## Boot

```dart
test('sem a11y na configuração, nada é registrado', () async {
  final app = Application()
    ..withProviders([LuminixServiceProvider.new, LuminixAccessibilityServiceProvider.new])
    ..withConfiguration(const AppConfiguration());

  await app.create();

  expect(() => app.make('a11y'), throwsA(anything));
});
```

E o inverso: com `a11y` configurado, `create()` não resolve antes de `load()` terminar; e um provider que lança **não** deixa `initialized` em falso.

## Runbook — quando o padrão mudar

1. **Um preset mudou** (uma flag entrou ou saiu de um perfil): atualize a matriz em [acessibilidade — perfis](acessibilidade-perfis.md) e o teste de merge. Nenhum app precisa mudar — overrides são esparsos, então apps existentes recebem a melhoria automaticamente, exceto onde o usuário ajustou aquele campo à mão.
2. **Uma configuração nova entrou em `A11ySettings`**: acrescente a chave em `A11yOverrideKey`, o campo em `merge`, a linha na matriz da documentação, e um teste de round-trip de persistência. Chave desconhecida no disco é ignorada, então versões antigas do app não quebram.
3. **Um par novo entrou na tabela de contraste**: acrescente ao `A11yBoostedColorSchemeResolver.pairs` — o teste de contraste itera a tabela e cobre o par novo sozinho.
4. **A API de semântica do Flutter mudou** (acontece a cada duas ou três versões): rode `flutter analyze` e migre os descontinuados. Já aconteceu com `SemanticsNode.hasFlag` → `flagsCollection`, `containsSemantics` → `isSemantics` e `tester.binding.pipelineOwner` → `tester.semantics`.
5. **Um app reportou uma tela que estoura em 2.0**: acrescente o teste do pior caso **antes** de corrigir o layout.

## Próximos passos

- [Acessibilidade](acessibilidade.md) — os critérios de aceite que estes testes verificam
- [Acessibilidade — widgets](acessibilidade-widgets.md) — os primitivos que já nascem testados
