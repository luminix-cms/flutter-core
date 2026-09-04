# Acessibilidade — perfis

O usuário não escolhe *flags*: escolhe **perfis**, em linguagem concreta ("enxergo com dificuldade"), e o pacote deriva as configurações. Perfis são **combináveis** — marcar dislexia e baixa visão ao mesmo tempo é o caso comum, não a exceção.

## Os seis perfis

| Perfil | Título (padrão PT-BR) | Subtítulo |
|--------|-----------------------|-----------|
| `lowVision` | Enxergo com dificuldade | Baixa visão |
| `colorBlindness` | Dificuldade com cores | Daltonismo |
| `epilepsy` | Sensível a luzes | Epilepsia |
| `adhd` | Me distraio fácil | TDAH |
| `dyslexia` | Dificuldade pra ler | Dislexia |
| `hearingImpairment` | Dificuldade pra ouvir | Deficiência auditiva |

Dois níveis de linguagem, de propósito: o **título** é concreto e descreve a experiência; o **subtítulo** nomeia a condição. Quem se reconhece no título não precisa do diagnóstico; quem procura pelo diagnóstico o encontra.

Todos os textos vêm de `A11yStrings` e são sobrescrevíveis campo a campo.

> **Nota:** **não existe perfil "cego" e isso é intencional.** TalkBack e VoiceOver já leem a árvore de semântica; um perfil não acrescentaria nada que o leitor de tela não faça melhor. O que o app precisa é detectar `MediaQuery.of(context).accessibleNavigation` e ajustar afordâncias que dependem de gesto.

## Matriz perfil × configuração

| Configuração | `lowVision` | `colorBlindness` | `epilepsy` | `adhd` | `dyslexia` | `hearingImpairment` |
|--------------|:-----------:|:----------------:|:----------:|:------:|:----------:|:-------------------:|
| `fontFamily` | hyperlegible | — | — | — | openDyslexic | — |
| `textScale` | 1.5 | — | — | 1.15 | 1.15 | — |
| `boldText` | ✔ | — | — | — | — | — |
| `letterSpacing` | wide | — | — | — | wider | — |
| `lineHeight` | 1.5 | — | — | — | 1.8 | — |
| `contrastMode` | highContrast | — | — | — | — | — |
| `colorBlindCues` | ✔ | ✔ | — | — | — | — |
| `decorativeBackgrounds` | ✘ | — | ✘ | ✘ | ✘ | — |
| `reduceMotion` | — | — | ✔ | ✔ | — | — |
| `noFlashing` | — | — | ✔ | — | — | — |
| `disableAutoplay` | — | — | ✔ | ✔ | — | — |
| `focusMode` | — | — | — | ✔ | ✔ | — |
| `hideTimers` | — | — | — | ✔ | ✔ | — |
| `oneItemPerScreen` | — | — | — | ✔ | — | — |
| `ttsEnabled` | ✔ | — | — | — | ✔ | — |
| `readingHighlight` | — | — | — | — | ✔ | — |
| `reducedEmphasis` | — | — | — | — | ✔ | — |
| `captions` | — | — | — | — | — | ✔ |
| `visualCuesForSound` | — | — | — | — | — | ✔ |
| `haptics` | ✔ | — | — | — | — | ✔ |

`—` significa "o perfil não opina"; `✘` significa que o perfil desliga explicitamente.

## Regras de combinação

Quando mais de um perfil está ativo, `A11ySettings.merge` resolve os conflitos assim:

| Tipo de campo | Regra | Racional |
|---------------|-------|----------|
| Booleano | **OU lógico** — verdadeiro se qualquer perfil ativo pedir | Um pedido de acessibilidade nunca é cancelado por outro |
| Numérico (`textScale`, `lineHeight`) | **Máximo** | O ajuste mais generoso vence |
| `letterSpacing`, `contrastMode` | **Máximo na escala do enum** | Idem |
| `fontFamily` | **Prioridade fixa**: dislexia > baixa visão > padrão | As duas famílias resolvem problemas diferentes; a de dislexia é a mais específica |
| `decorativeBackgrounds` | **E lógico** (`every`), padrão `true` | É a única flag invertida: basta um perfil pedir menos ruído para a decoração sair |

Exemplo: baixa visão (`textScale` 1.5) + TDAH (`textScale` 1.15) resulta em **1.5**.

## Ajustes manuais

O usuário pode discordar do preset. Um ajuste manual vira um **override esparso** — o pacote grava *que* aquele campo foi ajustado, não o valor mesclado inteiro.

```dart
controller.setOverride(A11yOverrideKey.textScale, 1.3);
controller.clearOverride(A11yOverrideKey.textScale);
```

A semântica é: **o perfil decide, exceto onde a pessoa disse explicitamente outra coisa.**

> **Nota:** essa é a diferença que mais importa em relação a um *dump* de configurações. Se o registro guardasse o resultado mesclado, uma melhoria futura num preset nunca alcançaria quem já usa o app — o valor antigo estaria congelado no disco. Com overrides esparsos, o preset evolui e só o campo que a pessoa ajustou permanece fixo.

### Chaves de override

`fontFamily`, `textScale`, `boldText`, `letterSpacing`, `lineHeight`, `contrastMode`, `colorBlindCues`, `decorativeBackgrounds`, `reduceMotion`, `noFlashing`, `disableAutoplay`, `focusMode`, `hideTimers`, `oneItemPerScreen`, `ttsEnabled`, `readingHighlight`, `captions`, `visualCuesForSound`, `haptics`, `reducedEmphasis`, `creamReadingBackground`.

## Escopo e persistência

| Escopo | Chave | Comportamento |
|--------|-------|---------------|
| `A11yScopeMode.device` (padrão) | `luminix_a11y_device` | Uma configuração por aparelho, independente de login |
| `A11yScopeMode.user` | `luminix_a11y_user_$id` | Uma configuração por usuário autenticado |

No escopo por usuário, se ainda não existe registro para aquele `id`, ele **herda o registro do dispositivo** e passa a gravar sob a chave do usuário. Quem configurou a acessibilidade na tela de login mantém a configuração depois de entrar — e essa é exatamente a população que precisou dela para conseguir entrar.

A leitura degrada, nunca lança: versão de schema ausente ou futura devolve os padrões; perfil desconhecido é ignorado; chave de override desconhecida é ignorada.

## Flags não implementadas pelo core

| Flag | Situação |
|------|----------|
| `oneItemPerScreen` | Modelada e persistida; **inerte** no core. Paginar o conteúdo de uma tela é decisão de cada tela |
| `colorBlindCues` | Modelada e persistida; **inerte** no core. O app usa a flag para acrescentar ícone/rótulo onde hoje só há cor |
| `ttsEnabled`, `readingHighlight` | Modeladas; a leitura em voz alta é do app ou do leitor de tela do sistema |
| `captions`, `visualCuesForSound` | Modeladas; consumidas pelo player do app |
| `hideTimers`, `disableAutoplay`, `noFlashing` | Modeladas; consumidas por quem tem carrossel, contador ou vídeo |

Ler uma flag no app:

```dart
final settings = A11yScopeData.of(context).settings;
if (settings.oneItemPerScreen) {
  // renderiza um passo por vez
}
```

## Próximos passos

- [Acessibilidade — tema](acessibilidade-tema.md) — como as configurações viram `ThemeData`
- [Acessibilidade — widgets](acessibilidade-widgets.md) — a Central que edita esses perfis
