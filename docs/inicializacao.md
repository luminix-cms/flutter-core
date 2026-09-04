# Inicialização

Todo app Luminix começa por um `LuminixApp` na raiz. Ele constrói o `Application` (o container de injeção de dependências), executa os *service providers* em duas passagens e só então marca o app como inicializado.

## Exemplo mínimo

```dart
void main() {
  runApp(
    LuminixApp(
      configuration: AppConfiguration(
        manifest: jsonDecode(manifestJson),
        url: const String.fromEnvironment('API_URL'),
        auth: AuthConfiguration(
          userModel: User.new,
          loginRoute: 'app.login',
        ),
        a11y: const A11yConfiguration(),
      ),
      splash: const SplashScreen(),
      child: const MyApp(),
    ),
  );
}
```

## `LuminixApp`

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `child` | `Widget` | Sim | A árvore do app, tipicamente um `MaterialApp` |
| `configuration` | `AppConfiguration` | Não | Configuração declarativa; padrão `const AppConfiguration()` |
| `providers` | `List<ServiceProviderConstructor>` | Não | Providers adicionais do app |
| `splash` | `Widget?` | Não | Renderizado no lugar do `child` enquanto o boot não terminou |
| `onInit` | `void Function(Application)?` | Não | Chamado uma vez, com o container pronto |
| `onRequestError` | `void Function(Response)?` | Não | Callback global de erro de requisição |

> **Nota:** sem `splash`, o `child` é renderizado desde o primeiro frame — o comportamento histórico. Com `splash`, o app só aparece quando o boot terminou, o que elimina o *flash* de conteúdo sem tema adaptado em apps com acessibilidade ligada.

## `AppConfiguration`

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `manifest` | `Map<String, dynamic>?` | Não | Manifesto Luminix vindo do backend |
| `url` | `String?` | Não | URL base da API |
| `environment` | `String?` | Não | Ambiente corrente |
| `debug` | `bool?` | Não | Modo de depuração |
| `auth` | `AuthConfiguration?` | Não | Modelo de usuário, driver e rotas de autenticação |
| `a11y` | `A11yConfiguration?` | Não | **Chave única de opt-in da acessibilidade**; nulo desliga tudo |

> **Nota:** o mapa produzido por `toMap()` é um **bag de injeção de dependências, nunca alvo de serialização**. Ele carrega objetos Dart vivos — funções construtoras de modelo, `Color`, builders de widget. Nada em um app Luminix deve chamar `jsonEncode` sobre `app.configuration`. O estado que precisa ser persistido tem caminho próprio e estritamente JSON.

## Ordem de boot

1. `LuminixApp` instancia o `Application` e registra, nesta ordem: `LuminixServiceProvider`, `LuminixAccessibilityServiceProvider`, e então os `providers` do app.
2. **Primeira passagem** — `register()` de cada provider, que apenas amarra *bindings* no container. Nada de I/O.
3. **Segunda passagem** — `boot()` de cada provider, **aguardado** (`FutureOr<void>`). É aqui que o `SharedPreferences` é lido.
4. `initialized` vira `true`, `onInit` é chamado, o `child` substitui o `splash`.

Como o `boot()` é aguardado, **`initialized == true` implica configuração de acessibilidade já carregada** — não existe janela em que o app renderize com os padrões e pisque para os ajustes do usuário.

> **Nota:** se um provider lançar durante o boot, o erro é reportado via `FlutterError.reportError` e o app **é inicializado mesmo assim**. Acessibilidade — ou qualquer outra capacidade opcional — nunca pode impedir o app de subir.

## Escrevendo um provider

```dart
class MyServiceProvider extends ServiceProvider {
  @override
  void register() {
    app.singleton('my.service', () => MyService());
  }

  @override
  Future<void> boot() async {
    await app.make('my.service').load();
  }

  @override
  void flush() {
    // Desfaz registros externos (GetIt, listeners) no dispose do container.
  }
}
```

`boot()` retorna `FutureOr<void>`: uma implementação `void` continua válida sem alteração.

## Próximos passos

- [Acessibilidade](acessibilidade.md) — o padrão da base
- [Acessibilidade — perfis](acessibilidade-perfis.md) — o que cada perfil ativa
