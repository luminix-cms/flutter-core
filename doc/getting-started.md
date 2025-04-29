# Instalação e Configuração

Este guia mostra como instalar e configurar o Luminix Flutter em seu projeto.

## Instalação

### Pré-requisitos

Antes de instalar o Luminix Flutter, certifique-se de que você tem:

- Flutter SDK (versão 3.0.0 ou superior)
- Dart SDK (versão 3.0.0 ou superior)
- Um projeto Flutter existente ou criar um novo

### Adicionando as Dependências

Adicione o pacote Luminix Flutter como dependência no arquivo `pubspec.yaml` do seu projeto. Como o pacote ainda não está publicado no pub.dev, você precisa referenciá-lo diretamente do GitHub:

```yaml
dependencies:
  flutter:
    sdk: flutter
  luminix_flutter:
    git:
      url: https://github.com/seu-repositorio/luminix_flutter.git
      ref: main  # ou especifique uma tag/branch específica

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0  # Necessário para geração de código
```

Após adicionar as dependências, execute o comando para baixar os pacotes:

```bash
flutter pub get
```

### Geração de Models

Para utilizar a funcionalidade de models, relacionamentos e query builder do Luminix, você precisa:

1. **Configurar o arquivo de manifesto**
   - Certifique-se de que o arquivo `manifest.json` gerado pelo backend Luminix esteja no diretório `lib/src/models/`

2. **Executar o gerador de models**
   - O Luminix Generator criará automaticamente um arquivo `models.dart` no mesmo diretório do manifesto
   - Este arquivo conterá todas as classes de modelo definidas no manifesto

Execute o seguinte comando para gerar os models:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Este comando analisará o arquivo `manifest.json` e gerará as classes Dart correspondentes para todos os models definidos no manifesto. Você precisará executar este comando novamente sempre que o arquivo de manifesto for atualizado.

O arquivo `models.dart` gerado incluirá:
- Classes para todos os models presentes no manifesto
- Métodos para serialização/deserialização
- Configuração de relacionamentos (hasOne, hasMany, belongsTo, etc.)
- Suporte para o query builder fluente

## Configuração Básica

### Inicializando o LuminixApp

Para começar a usar o Luminix Flutter, você precisa envolver sua aplicação com o widget `LuminixApp`. Este widget inicializa todos os serviços necessários e fornece acesso a eles através do contexto.

No arquivo principal da sua aplicação (geralmente `main.dart`), inicialize o Luminix da seguinte forma:

```dart
import 'package:flutter/material.dart';
import 'package:luminix_flutter/luminix_flutter.dart';

void main() {
  runApp(
    LuminixApp(
      configuration: AppConfiguration(
        url: 'https://api.seudominio.com',  // URL base da sua API
        environment: 'development',          // Ambiente (development, production)
        debug: true,                         // Modo de depuração
      ),
      providers: [
        // Adicione provedores de serviço personalizados aqui, se necessário
      ],
      onInit: () {
        // Código a ser executado após a inicialização
        print('Luminix Flutter inicializado com sucesso!');
      },
      child: MeuAplicativo(),
    ),
  );
}

class MeuAplicativo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App com Luminix',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MinhaTelaInicial(),
    );
  }
}
```

### Configuração do Manifesto e Geração de Models

O Luminix Flutter utiliza um arquivo de manifesto que contém informações sobre os modelos, rotas e configurações da API. Este arquivo deve ser gerado pelo backend Luminix e colocado na pasta específica do seu projeto Flutter.

#### Configuração do Manifesto:

1. **Gerar o arquivo manifest.json no backend Luminix**
   - Este arquivo contém as definições de modelos, rotas e outras configurações necessárias
   - É essencial não apenas para a geração de models, mas também para o funcionamento do sistema de rotas

2. **Colocar o arquivo na localização correta**
   - O arquivo deve ser colocado em: `lib/src/models/manifest.json`
   - Esta localização é esperada pelo Luminix Flutter para carregamento automático
   - Certifique-se de que a pasta `lib/src/models/` existe em seu projeto

#### Importância para o Sistema de Rotas:

O arquivo manifest.json define todas as rotas disponíveis na API, permitindo que o Luminix Flutter:

- Gere URLs corretas para cada endpoint da API
- Determine os métodos HTTP disponíveis para cada rota
- Valide parâmetros de rota antes de enviar requisições
- Forneça uma interface tipada para interação com a API

**Exemplo de definição de rotas no manifest.json:**
```json
{
  "routes": {
    "luminix.users.index": ["/api/users", "get"],
    "luminix.users.show": ["/api/users/{id}", "get"],
    "luminix.users.store": ["/api/users", "post"],
    "luminix.users.update": ["/api/users/{id}", "put", "patch"],
    "luminix.users.destroy": ["/api/users/{id}", "delete"]
  }
}
```

**Exemplo de uso do sistema de rotas:**
```dart
// Acessando o serviço de rotas
final routeService = LuminixApp.of(context).app.make('route');

// Gerando URL para listar usuários
final indexUrl = routeService.url(
  RouteGenerator(name: 'luminix.users.index')
);
// Resultado: https://api.seudominio.com/api/users

// Gerando URL para um usuário específico
final showUrl = routeService.url(
  RouteGenerator(name: 'luminix.users.show', replacer: {'id': '123'})
);
// Resultado: https://api.seudominio.com/api/users/123

// Fazendo uma requisição
final response = await routeService.call(
  generator: RouteGenerator(
    name: 'luminix.users.update', 
    replacer: {'id': '123'}
  ),
  tap: (client) => client.withData({'name': 'Novo Nome'})
);
```

#### Geração de Models a partir do Manifesto:

Depois de configurar o arquivo de manifesto, você precisa gerar as classes de modelo correspondentes:

1. **Execute o comando de geração de código:**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

2. **Verificar a geração:**
   - O comando criará um arquivo `models.dart` no mesmo diretório do `manifest.json`
   - Este arquivo conterá todas as classes de modelo baseadas nas definições do manifesto
   - Inclui métodos para serialização/deserialização, relacionamentos e query builder

3. **Regerar quando necessário:**
   - Execute o comando novamente sempre que o arquivo de manifesto for atualizado
   - Isso manterá suas classes de modelo sincronizadas com a API

#### Carregamento do Manifesto:

O Luminix Flutter carregará automaticamente o arquivo de manifesto durante a inicialização:

```dart
// Em Application.dart
Future<void> loadConfiguration() async {
  try {
    final manifestString = 
        await rootBundle.loadString('lib/src/models/manifest.json');
    final manifestJson = jsonDecode(manifestString);
    withConfiguration(AppConfiguration(manifest: manifestJson));
  } catch (e) {
    print('Um erro ocorreu durante o carregamento do manifesto: $e');
  }
}
```

> **Importante**: O arquivo manifest.json é fundamental tanto para a geração de models quanto para o funcionamento do sistema de rotas. Sem ele, você não poderá aproveitar as funcionalidades de ORM nem fazer requisições à API de forma segura e tipada.

## Acessando Serviços

Após a inicialização, você pode acessar os serviços do Luminix Flutter através do contexto:

```dart
class MinhaTelaInicial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Acesso ao serviço de rotas
    final routeService = LuminixApp.of(context).app.make('route');
    
    // Acesso ao serviço de autenticação
    final authService = LuminixApp.of(context).app.make('auth');
    
    return Scaffold(
      appBar: AppBar(title: Text('Tela Inicial')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Exemplo de uso do serviço de autenticação
            try {
              await authService.attempt({
                'email': 'usuario@exemplo.com',
                'password': 'senha123',
              });
              print('Login realizado com sucesso!');
            } catch (e) {
              print('Erro ao fazer login: $e');
            }
          },
          child: Text('Fazer Login'),
        ),
      ),
    );
  }
}
```

## Configuração Avançada

### Provedores de Serviço Personalizados

Você pode criar e registrar seus próprios provedores de serviço para estender a funcionalidade do Luminix Flutter:

```dart
class MeuServiceProvider extends ServiceProvider {
  MeuServiceProvider(Application app) : super(app);
  
  @override
  void register() {
    app.singleton('meuServico', () {
      return MeuServico();
    });
  }
  
  @override
  void boot() {
    // Código a ser executado após o registro de todos os serviços
  }
}

// No arquivo main.dart
LuminixApp(
  providers: [
    MeuServiceProvider.new,
  ],
  // ...
)
```

### Configuração de Autenticação Personalizada

Para usar um modelo de usuário personalizado:

```dart
LuminixApp(
  configuration: AppConfiguration(
    // Outras configurações...
    auth: AuthConfiguration(
      driver: 'api',
      userModel: (data) => Usuario(data),
    ),
  ),
  // ...
)
```

## Solução de Problemas

### Erros Comuns

1. **Erro de conexão com a API**
   - Verifique se a URL base está correta
   - Confirme se a API está acessível e funcionando corretamente

2. **Erro ao carregar o manifesto**
   - Verifique o formato do JSON do manifesto
   - Confirme que o manifesto contém todas as informações necessárias

3. **Erro de autenticação**
   - Verifique se as credenciais estão corretas
   - Confirme que a rota de login está configurada corretamente

### Logs e Depuração

Para habilitar logs detalhados durante o desenvolvimento:

```dart
LuminixApp(
  configuration: AppConfiguration(
    debug: true,
    // Outras configurações...
  ),
  // ...
)
```

## Próximos Passos

Agora que você configurou o Luminix Flutter em seu projeto, você pode:

1. [Gerar modelos](./geracao-modelos.md) a partir do manifesto da API
2. [Implementar autenticação](./autenticacao.md) em sua aplicação
3. [Trabalhar com modelos e relacionamentos](./modelos-relacionamentos.md)
4. [Realizar consultas avançadas](./consultas-avancadas.md) usando os builders