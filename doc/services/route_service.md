# RouteService

O `RouteService` é um componente central do Luminix Flutter que facilita a comunicação com a API backend. Ele fornece uma interface simplificada para gerar URLs dinamicamente, validar parâmetros e executar requisições HTTP de forma organizada e consistente.

## Conceitos Básicos

### O que é o RouteService?

O `RouteService` é responsável por:

1. Mapear nomes de rotas para endpoints de API
2. Gerar URLs com substituição automática de parâmetros
3. Executar requisições HTTP com configurações predefinidas
4. Integrar-se com o sistema de autenticação
5. Tratar respostas e erros de forma padronizada

### Como Funciona?

O `RouteService` usa as definições de rotas presentes no arquivo `manifest.json` para criar um mapeamento entre nomes amigáveis de rotas (ex: `luminix.users.show`) e os endpoints reais da API (ex: `/api/users/{id}`). Isso permite:

- Centralizar a definição de rotas
- Alterar endpoints sem modificar o código do aplicativo
- Validar parâmetros antes de fazer requisições
- Escolher automaticamente o método HTTP correto

## Acessando o RouteService

```dart
// Em qualquer widget onde o LuminixApp está disponível no contexto
final routeService = LuminixApp.of(context).app.make('route');

// Ou se estiver usando GetIt
final routeService = getIt.get<RouteService>();
```

## Recursos Principais

### Verificação de Existência de Rotas

```dart
// Verifica se uma rota existe no manifesto
if (routeService.exists('luminix.users.show')) {
  // A rota existe
}
```

### Geração de URLs

O método `url()` gera uma URL completa para uma rota específica:

```dart
// URL sem parâmetros
final indexUrl = routeService.url(
  RouteGenerator(name: 'luminix.products.index')
);
// Resultado: https://api.seudominio.com/api/products

// URL com parâmetros
final showUrl = routeService.url(
  RouteGenerator(
    name: 'luminix.products.show',
    replacer: {'id': '123'}
  )
);
// Resultado: https://api.seudominio.com/api/products/123
```

### Obtenção de Métodos HTTP

```dart
// Obtém os métodos HTTP disponíveis para uma rota
final methods = routeService.methods(
  RouteGenerator(name: 'luminix.products.update')
);
// Resultado: ['put', 'patch']
```

### Execução de Requisições

O método `call()` executa uma requisição HTTP para a rota especificada:

```dart
// Requisição GET simples
final response = await routeService.call(
  generator: RouteGenerator(name: 'luminix.products.index')
);

// Requisição POST com dados
final createResponse = await routeService.call(
  generator: RouteGenerator(name: 'luminix.products.store'),
  tap: (client) => client.copyWith(data: {
    'name': 'Novo Produto',
    'price': 99.99,
    'description': 'Descrição do produto'
  })
);

// Requisição PUT com dados
final updateResponse = await routeService.call(
  generator: RouteGenerator(
    name: 'luminix.products.update',
    replacer: {'id': '123'}
  ),
  tap: (client) => client.copyWith(data: {
    'name': 'Nome Atualizado'
  })
);

// Requisição DELETE
final deleteResponse = await routeService.call(
  generator: RouteGenerator(
    name: 'luminix.products.destroy',
    replacer: {'id': '123'}
  )
);
```

### Modificando o Cliente HTTP

O parâmetro `tap` permite modificar o cliente HTTP antes de executar a requisição:

```dart
// Adicionando parâmetros de consulta
await routeService.call(
  generator: RouteGenerator(name: 'luminix.products.index'),
  tap: (client) => client.withParams({
    'page': '2',
    'per_page': '15',
    'sort': 'name'
  })
);

// Adicionando cabeçalhos personalizados
await routeService.call(
  generator: RouteGenerator(name: 'luminix.products.index'),
  tap: (client) => client.withHeaders({
    'X-Custom-Header': 'Valor personalizado'
  })
);

// Configurando timeout específico para uma requisição
await routeService.call(
  generator: RouteGenerator(name: 'luminix.downloads.large-file'),
  tap: (client) => client.copyWith(timeout: Duration(seconds: 60))
);
```

## Tratamento de Respostas

O `RouteService` retorna um objeto `Response` que contém métodos úteis para processar a resposta:

```dart
final response = await routeService.call(
  generator: RouteGenerator(name: 'luminix.products.show', replacer: {'id': '123'})
);

// Verificar status
if (response.successful()) {
  // Status 2xx
} else if (response.clientError()) {
  // Status 4xx
} else if (response.serverError()) {
  // Status 5xx
}

// Acessar corpo da resposta
final body = response.body();

// Acessar resposta como JSON
final json = response.json();

// Verificar códigos de status específicos
if (response.ok()) {
  // Status 200
} else if (response.created()) {
  // Status 201
} else if (response.noContent()) {
  // Status 204
} else if (response.notFound()) {
  // Status 404
}

// Lançar exceção se a requisição falhar
response.throwIfFailed();

// Lançar exceção baseada em condição
response.throwIf((r) => r.status() > 400);
```

## Integração com Autenticação

O `RouteService` integra-se automaticamente com o sistema de autenticação do Luminix:

```dart
// Se o usuário estiver autenticado, o token será incluído automaticamente
final response = await routeService.call(
  generator: RouteGenerator(name: 'luminix.users.me')
);

// O token é adicionado como um cabeçalho Authorization: Bearer {token}
```

## Tratamento de Erros

O `RouteService` possui tratamento padronizado para erros comuns:

```dart
try {
  final response = await routeService.call(
    generator: RouteGenerator(name: 'luminix.products.store'),
    tap: (client) => client.copyWith(data: productData)
  );
} catch (e) {
  if (e is ValidationException) {
    // Erros de validação (422)
    final errors = e.errors;
    // Exibir mensagens de erro para cada campo
  } else if (e is UnauthorizedException) {
    // Erro de autenticação (401)
    // Redirecionar para tela de login
  } else if (e is NotFoundException) {
    // Recurso não encontrado (404)
    // Exibir mensagem ao usuário
  } else {
    // Outros erros
    // Exibir mensagem genérica
  }
}
```

## Reducers

O `RouteService` suporta reducers, que permitem modificar o comportamento de requisições e respostas em vários pontos:

```dart
// Adicionar um reducer para substituir parâmetros de rota
routeService.reducer<String>(
  name: 'replaceRouteParams',
  callback: (value) {
    // Personalizar substituição de parâmetros
    return value.replaceAll('{tenant}', 'meu-tenant');
  }
);

// Adicionar um reducer para modificar o cliente
routeService.reducer<Client>(
  name: 'clientOptions',
  callback: (client) {
    // Adicionar cabeçalhos globais
    return client.withHeaders({
      'X-App-Version': '1.0.0',
      'X-Platform': 'iOS'
    });
  }
);
```

## Exemplo Completo

Aqui está um exemplo completo de como usar o `RouteService` em uma classe de repositório:

```dart
class ProductRepository {
  final RouteService routeService;
  
  ProductRepository(this.routeService);
  
  Future<List<Product>> getProducts({int page = 1, int perPage = 20}) async {
    final response = await routeService.call(
      generator: RouteGenerator(name: 'luminix.products.index'),
      tap: (client) => client.withParams({
        'page': page.toString(),
        'per_page': perPage.toString()
      })
    );
    
    final data = response.json()['data'] as List;
    return data.map((item) => Product(item)).toList();
  }
  
  Future<Product?> getProduct(String id) async {
    try {
      final response = await routeService.call(
        generator: RouteGenerator(
          name: 'luminix.products.show',
          replacer: {'id': id}
        )
      );
      
      return Product(response.json());
    } catch (e) {
      if (e is NotFoundException) {
        return null;
      }
      rethrow;
    }
  }
  
  Future<Product> createProduct(Map<String, dynamic> data) async {
    final response = await routeService.call(
      generator: RouteGenerator(name: 'luminix.products.store'),
      tap: (client) => client.copyWith(data: data)
    );
    
    return Product(response.json());
  }
  
  Future<Product> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await routeService.call(
      generator: RouteGenerator(
        name: 'luminix.products.update',
        replacer: {'id': id}
      ),
      tap: (client) => client.copyWith(data: data)
    );
    
    return Product(response.json());
  }
  
  Future<bool> deleteProduct(String id) async {
    try {
      final response = await routeService.call(
        generator: RouteGenerator(
          name: 'luminix.products.destroy',
          replacer: {'id': id}
        )
      );
      
      return response.noContent();
    } catch (e) {
      return false;
    }
  }
}
```

## Considerações Adicionais

### Configuração de Base URL

A URL base para todas as requisições é configurada durante a inicialização do Luminix:

```dart
LuminixApp(
  configuration: AppConfiguration(
    url: 'https://api.seudominio.com',
    // Outras configurações...
  ),
  // ...
)
```

### Timeout Global

Você pode configurar um timeout global para todas as requisições:

```dart
// No seu service provider
app.singleton('http.client', () {
  return Client(timeout: Duration(seconds: 30));
});
```

### Interceptação de Requisições

Para interceptar todas as requisições (por exemplo, para logging ou monitoramento):

```dart
routeService.reducer<Client>(
  name: 'clientOptions',
  callback: (client) {
    print('Iniciando requisição para: ${client.url}');
    return client;
  },
  priority: 5,
);
```

### Solução de Problemas

- Se você receber o erro "Route X does not exist", verifique se o nome da rota está definido corretamente no arquivo `manifest.json`.
- Se encontrar erros de parâmetros ausentes, verifique se todos os parâmetros necessários estão sendo fornecidos no objeto `replacer`.
- Para depurar requisições, você pode ativar o modo de depuração no `AppConfiguration` e observar os logs.