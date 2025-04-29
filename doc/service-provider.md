# Service Providers

Os Service Providers são um componente fundamental do Luminix Flutter, inspirados pelo conceito de provedores de serviço do Laravel. Eles servem como o principal meio de registrar e inicializar os diversos serviços, funcionalidades e componentes da sua aplicação.

## Conceito de Service Providers

Um Service Provider é uma classe responsável por:

1. **Registrar** serviços no contêiner de injeção de dependência
2. **Inicializar** componentes e configurações
3. **Conectar** diferentes partes da aplicação
4. **Estender** a funcionalidade principal do Luminix Flutter

Este padrão permite um carregamento modular e flexível dos componentes, mantendo o código organizado e desacoplado.

## Anatomia de um Service Provider

Todo Service Provider no Luminix Flutter estende a classe abstrata `ServiceProvider` e implementa pelo menos um dos métodos do ciclo de vida:

```dart
import 'package:luminix_flutter/luminix_flutter.dart';

class MeuServiceProvider extends ServiceProvider {
  // Construtor recebe a instância da aplicação
  MeuServiceProvider(Application app) : super(app);
  
  // Método para registrar serviços
  @override
  void register() {
    // Registrar serviços, factories, singletons...
  }
  
  // Método chamado após todos os serviços serem registrados
  @override
  void boot() {
    // Inicializar serviços, configurações...
  }
  
  // Método chamado durante o encerramento da aplicação
  @override
  void flush() {
    // Liberar recursos, salvar estados...
  }
}
```

## Ciclo de Vida dos Service Providers

O Luminix Flutter executa os Service Providers em uma sequência específica:

1. **Construção** - Todos os provedores são instanciados
2. **Registro** - O método `register()` de cada provedor é chamado
3. **Inicialização** - O método `boot()` de cada provedor é chamado
4. **Aplicação em execução**
5. **Liberação** - O método `flush()` é chamado durante o encerramento

Esta sequência garante que todos os serviços estejam registrados antes da inicialização, permitindo dependências entre serviços.

## Registrando Service Providers

Os Service Providers são registrados durante a inicialização do `LuminixApp`:

```dart
void main() {
  runApp(
    LuminixApp(
      providers: [
        // Lista de provedores de serviço
        MeuServiceProvider.new,
        OutroServiceProvider.new,
        // Você pode adicionar quantos provedores precisar
      ],
      configuration: AppConfiguration(
        // Configurações...
      ),
      child: MeuAplicativo(),
    ),
  );
}
```

## Registrando Serviços

Dentro do método `register()`, você pode registrar serviços de várias maneiras:

### Registrando uma Factory

Uma factory cria uma nova instância do serviço a cada vez que é solicitada:

```dart
@override
void register() {
  // Registrar uma factory
  app.bind('servico.transiente', () {
    return MinhaClasse();
  });
}

// Uso
final servico = app.make('servico.transiente'); // Nova instância cada vez
```

### Registrando um Singleton

Um singleton cria uma instância única que é reutilizada em toda a aplicação:

```dart
@override
void register() {
  // Registrar um singleton
  app.singleton('servico.singleton', () {
    return MinhaClasseSingleton();
  });
}

// Uso
final servicoA = app.make('servico.singleton'); // Mesma instância
final servicoB = app.make('servico.singleton'); // Mesma instância
```

### Acessando Serviços Registrados

Dentro do Service Provider, você pode acessar outros serviços já registrados:

```dart
@override
void register() {
  app.singleton('servico.dependente', () {
    // Acessar outro serviço
    final config = app.make('config');
    return NovoServico(config);
  });
}
```

## Inicializando Serviços

O método `boot()` é chamado após todos os serviços terem sido registrados:

```dart
@override
void boot() {
  // Obtendo um serviço registrado
  final database = app.make('database');
  final authService = app.make('auth');
  
  // Inicializando (exemplo: configurando listeners)
  authService.onLogin((user) {
    database.connect(user.getAttribute('tenant_id'));
  });
  
  // Carregando dados iniciais
  preCarregarDados();
}

void preCarregarDados() {
  // Carregar dados iniciais necessários para a aplicação
}
```

## Service Provider Padrão: LuminixServiceProvider

O Luminix Flutter inclui um Service Provider padrão chamado `LuminixServiceProvider` que registra os serviços básicos da framework:

```dart
class LuminixServiceProvider extends ServiceProvider {
  LuminixServiceProvider(super.application);

  @override
  void register() {
    registerServices();
  }

  void registerServices() {
    // Registra o serviço de configuração
    app.singleton('config', () {
      final config = PropertyBag.fromMap(map: Map.from(app.configuration));
      return config;
    });

    // Registra o serviço de rotas
    app.singleton('route', () {
      return RouteService(
        routes: app.configuration['manifest']?['routes'] ?? {},
        appUrl: app.configuration['app']?['url'] ?? '',
        authProvider: () => app.make('auth'),
      );
    });

    // Registra esquemas de modelos
    app.singleton('schemas', () {
      return PropertyBag.fromMap(
        map: app.configuration['manifest']['models'] ?? {},
      );
    });

    // Registra o driver de autenticação padrão
    app.singleton('auth:api', () {
      return ApiAuthDriver(
        app.make('config'),
        () => app.make('route'),
      );
    });

    // Registra o serviço de autenticação
    app.singleton('auth', () {
      return AuthService(app);
    });

    // Registra singletons no GetIt para fácil acesso global
    getIt.registerSingleton<RouteService>(app.make('route'));
    getIt.registerSingleton<PropertyBag>(app.make('config'));
  }
}
```

Este provedor é sempre incluído automaticamente e inicializa os serviços essenciais do Luminix Flutter.

## Criando Service Providers Personalizados

### Exemplo: Database Service Provider

```dart
class DatabaseServiceProvider extends ServiceProvider {
  DatabaseServiceProvider(super.application);

  @override
  void register() {
    // Registrar o serviço de database
    app.singleton('database', () {
      final config = app.make('config');
      final dbConfig = config.get('database');
      
      return DatabaseService(
        host: dbConfig['host'],
        port: dbConfig['port'],
        username: dbConfig['username'],
        password: dbConfig['password'],
        database: dbConfig['database'],
      );
    });
    
    // Registrar repositórios que dependem do database
    app.singleton('repositories.usuario', () {
      final db = app.make('database');
      return UsuarioRepository(db);
    });
  }
  
  @override
  void boot() {
    final db = app.make('database');
    
    // Inicializar conexão
    db.connect();
    
    // Configurar listeners
    db.onDisconnect(() {
      print('Database desconectado. Tentando reconectar...');
      db.reconnect();
    });
  }
  
  @override
  void flush() {
    final db = app.make('database');
    
    // Fechar conexão quando o aplicativo for encerrado
    db.disconnect();
  }
}
```

### Exemplo: Analítico Service Provider

```dart
class AnalyticsServiceProvider extends ServiceProvider {
  AnalyticsServiceProvider(super.application);
  
  @override
  void register() {
    app.singleton('analytics', () {
      final config = app.make('config');
      return AnalyticsService(
        apiKey: config.get('analytics.api_key'),
        endpoint: config.get('analytics.endpoint'),
      );
    });
  }
  
  @override
  void boot() {
    final analytics = app.make('analytics');
    final authService = app.make('auth');
    
    // Iniciar o serviço
    analytics.initialize();
    
    // Configurar eventos de autenticação
    authService.onLogin((user) {
      analytics.setUser(user.getKey(), {
        'email': user.getAttribute('email'),
        'plano': user.getAttribute('plano'),
      });
    });
    
    authService.onLogout(() {
      analytics.clearUser();
    });
  }
}
```

## Ordem de Execução dos Service Providers

A ordem em que os Service Providers são executados é determinada pela ordem em que são adicionados à lista `providers` durante a inicialização do `LuminixApp`. Se você tiver dependências entre provedores, certifique-se de registrá-los na ordem correta:

```dart
LuminixApp(
  providers: [
    // O LuminixServiceProvider é sempre adicionado primeiro automaticamente
    ConfigServiceProvider.new,    // 1º a ser executado
    DatabaseServiceProvider.new,  // 2º a ser executado
    AuthServiceProvider.new,      // 3º a ser executado
    ApiServiceProvider.new,       // 4º a ser executado
  ],
  // ...
)
```

## Acessando Serviços na Aplicação

Depois que os serviços estão registrados pelos Service Providers, você pode acessá-los em qualquer parte da sua aplicação:

```dart
// Em um widget onde o contexto está disponível
Widget build(BuildContext context) {
  final app = LuminixApp.of(context).app;
  final authService = app.make('auth');
  final apiService = app.make('api');
  
  // Usando os serviços...
}

// Ou usando GetIt para acesso global
final authService = getIt.get<AuthService>();
final routeService = getIt.get<RouteService>();
```

## Práticas Recomendadas

1. **Separação de Responsabilidades**
   - Cada Service Provider deve ter uma responsabilidade clara e específica
   - Evite provedores que fazem muitas coisas diferentes

2. **Nomenclatura**
   - Use nomes descritivos para seus provedores (ex: `DatabaseServiceProvider`)
   - Use nomes consistentes para registrar serviços (ex: `database`, `auth`, `api`)

3. **Gerenciamento de Dependências**
   - Registre serviços que são dependências antes dos serviços que dependem deles
   - Use funções de fábrica para acessar dependências no momento da criação do serviço

4. **Configuração**
   - Use o serviço de configuração para parâmetros que podem mudar
   - Evite valores codificados nos Service Providers

5. **Ciclo de Vida**
   - Use `register()` apenas para registrar serviços
   - Use `boot()` para inicialização e configuração de serviços
   - Use `flush()` para liberar recursos adequadamente

## Solução de Problemas

### Erro: "Service X is not bound in the container"

Este erro acontece quando você tenta acessar um serviço que não foi registrado:

1. Verifique se o Service Provider que registra o serviço está incluído na lista de provedores
2. Verifique se o nome do serviço está correto (maiúsculas/minúsculas são importantes)
3. Verifique se o serviço é registrado antes de ser acessado

### Erro: "Circular dependency detected"

Este erro ocorre quando serviços dependem circularmente um do outro:

1. Reestruture seus serviços para evitar dependências circulares
2. Use injeção de dependência via método em vez de via construtor
3. Use funções de fábrica lazy que resolvem dependências somente quando necessário

### Serviço Sendo Criado Múltiplas Vezes

Se um serviço que deveria ser singleton está sendo criado múltiplas vezes:

1. Verifique se você está usando `app.singleton()` em vez de `app.bind()`
2. Verifique se não está registrando o mesmo serviço em múltiplos lugares
3. Certifique-se de usar o mesmo nome para acessar o serviço

## Conclusão

Os Service Providers são uma parte essencial da arquitetura do Luminix Flutter, fornecendo um meio organizado e flexível de registrar, configurar e inicializar os diversos componentes da sua aplicação. Ao compreender bem este conceito, você poderá estruturar sua aplicação de forma modular, testável e manutenível.