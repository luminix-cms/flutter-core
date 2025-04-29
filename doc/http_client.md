# HTTP Client

O Luminix Flutter fornece um cliente HTTP flexível e poderoso para facilitar a comunicação com APIs. O cliente HTTP é a base do sistema de requisições e é usado internamente pelo `RouteService`, mas também pode ser utilizado diretamente para necessidades específicas.

## Visão Geral

O cliente HTTP do Luminix Flutter é composto por duas classes principais:

1. **Client** - Responsável por configurar e iniciar requisições HTTP
2. **Request** - Representa uma requisição HTTP em andamento
3. **Response** - Encapsula a resposta da API com métodos úteis para processamento

## Acessando o Cliente HTTP

```dart
// Criando uma nova instância do cliente
final client = Client();

// Ou acessando através do RouteService
final routeService = LuminixApp.of(context).app.make('route');
final response = await routeService.call(
  generator: RouteGenerator(name: 'luminix.users.index'),
  tap: (client) {
    // Manipule o cliente aqui antes da requisição
    return client;
  },
);
```

## Configuração Básica

### Criando um Cliente

```dart
// Cliente com configurações padrão
final client = Client();

// Cliente com URL base
final client = Client(baseUrl: 'https://api.seudominio.com');

// Cliente com cabeçalhos personalizados
final client = Client(
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'X-API-Key': 'sua-chave-api',
  }
);

// Cliente com parâmetros de consulta padrão
final client = Client(
  params: {
    'version': '1.0',
    'lang': 'pt-BR',
  }
);

// Cliente com dados padrão para requisições
final client = Client(
  data: {
    'source': 'app-mobile',
  }
);
```

### Métodos de Configuração em Cadeia

O cliente HTTP permite encadear métodos para facilitar a configuração:

```dart
final response = await Client()
  .withHeaders({'X-Custom-Header': 'valor'})
  .withParams({'page': '1', 'limit': '20'})
  .acceptJson()
  .get('https://api.exemplo.com/users');
```

## Métodos HTTP

### GET

```dart
// Requisição GET simples
final response = await client.get('https://api.exemplo.com/users');

// Com parâmetros de consulta
final response = await client
  .withParams({'active': 'true', 'sort': 'name'})
  .get('https://api.exemplo.com/users');
```

### POST

```dart
// Requisição POST com dados JSON
final response = await client
  .post('https://api.exemplo.com/users')
  .withData({
    'name': 'João Silva',
    'email': 'joao@exemplo.com',
    'role': 'user',
  });

// Requisição POST com formulário
final response = await client
  .asForm()
  .post('https://api.exemplo.com/login')
  .withData({
    'username': 'joao',
    'password': 'senha123',
  });
```

### PUT

```dart
final response = await client
  .put('https://api.exemplo.com/users/123')
  .withData({
    'name': 'João da Silva',
    'email': 'joao.silva@exemplo.com',
  });
```

### PATCH

```dart
final response = await client
  .patch('https://api.exemplo.com/users/123')
  .withData({
    'status': 'active',
  });
```

### DELETE

```dart
final response = await client
  .delete('https://api.exemplo.com/users/123');
```

### Método Genérico

```dart
// Método genérico para qualquer tipo de requisição
final response = await client
  .call('PUT', 'https://api.exemplo.com/resources/456')
  .withData({
    'title': 'Novo título',
  });
```

## Configurações Avançadas

### Modificando Cabeçalhos

```dart
// Adicionando cabeçalhos
final response = await client
  .withHeaders({
    'X-Requested-With': 'XMLHttpRequest',
    'Authorization': 'Bearer token123',
  })
  .get('https://api.exemplo.com/protected-resource');

// Definindo tipo de conteúdo como formulário
final response = await client
  .asForm()
  .post('https://api.exemplo.com/submit-form');

// Definindo tipo de conteúdo aceito
final response = await client
  .accept('application/pdf')
  .get('https://api.exemplo.com/report');

// Atalho para aceitar JSON
final response = await client
  .acceptJson()
  .get('https://api.exemplo.com/data');
```

### Autenticação

```dart
// Autenticação Basic
final response = await client
  .withBasicAuth('username', 'password')
  .get('https://api.exemplo.com/protected');

// Autenticação Bearer Token
final response = await client
  .withBearerToken('seu-token-jwt')
  .get('https://api.exemplo.com/me');
```

### Construção de URL

O cliente HTTP possui um método para construir URLs com parâmetros:

```dart
final uri = client
  .withParams({
    'q': 'flutter',
    'sort': 'stars',
    'per_page': '50',
  })
  .buildUrl('/search');

// Resultado: /search?q=flutter&sort=stars&per_page=50
```

## Processando Respostas

O objeto `Response` retornado pelas requisições fornece vários métodos úteis:

```dart
final response = await client.get('https://api.exemplo.com/users/123');

// Obtendo o corpo da resposta
final body = response.body();

// Obtendo a resposta como JSON
final data = response.json();
final name = data['name'];

// Verificando o status da resposta
if (response.ok()) {
  // Status 200 OK
} else if (response.created()) {
  // Status 201 Created
} else if (response.noContent()) {
  // Status 204 No Content
}

// Categorias de status
if (response.successful()) {
  // Status 2xx (sucesso)
} else if (response.redirect()) {
  // Status 3xx (redirecionamento)
} else if (response.clientError()) {
  // Status 4xx (erro do cliente)
} else if (response.serverError()) {
  // Status 5xx (erro do servidor)
}

// Verificações específicas
if (response.unauthorized()) {
  // Status 401 Unauthorized
} else if (response.forbidden()) {
  // Status 403 Forbidden
} else if (response.notFound()) {
  // Status 404 Not Found
} else if (response.unprocessableEntity()) {
  // Status 422 Unprocessable Entity
}

// Obtendo cabeçalhos
final contentType = response.header('Content-Type');
final allHeaders = response.headers();

// Lançando exceções em caso de erro
try {
  response.throwIfFailed(); // Lança exceção para status 4xx ou 5xx
  response.throwIf((r) => r.status() == 403); // Lança exceção para condição específica
  response.throwIfStatus(401); // Lança exceção para status específico
} catch (e) {
  print('Erro na requisição: $e');
}
```

## Tratamento de Erros

```dart
try {
  final response = await client.get('https://api.exemplo.com/users/999');
  response.throwIfFailed();
  
  // Processar resposta bem-sucedida
  final user = response.json();
  print('Usuário: ${user['name']}');
} catch (e) {
  if (e is HttpException) {
    if (e.response.notFound()) {
      print('Usuário não encontrado');
    } else if (e.response.unauthorized()) {
      print('Autenticação necessária');
    } else {
      print('Erro HTTP: ${e.response.status()}');
      print('Mensagem: ${e.response.json()['message']}');
    }
  } else {
    print('Erro de conexão: $e');
  }
}
```

## Validação de Erros

O Luminix Flutter possui um utilitário para verificar erros de validação:

```dart
try {
  final response = await client
    .post('https://api.exemplo.com/users')
    .withData(userData);
    
  if (isValidationError(response)) {
    final errors = response.json()['errors'] as Map<String, List<String>>;
    // Exibir erros de validação
    errors.forEach((field, messages) {
      print('Erro em $field: ${messages.join(', ')}');
    });
    return;
  }
  
  // Processar resposta bem-sucedida
} catch (e) {
  print('Erro: $e');
}
```

## Clonando Clientes

Você pode criar uma cópia de um cliente com modificações usando o método `copyWith`:

```dart
// Cliente original
final client = Client(baseUrl: 'https://api.exemplo.com');

// Cliente clonado com modificações
final authClient = client.copyWith(
  headers: {
    ...client.headers,
    'Authorization': 'Bearer $token',
  },
  params: {
    'version': '2.0',
  },
);
```

## Exemplo Completo

Aqui está um exemplo completo mostrando como usar o cliente HTTP em uma classe de serviço:

```dart
class ApiService {
  final Client _client;
  
  ApiService({String? baseUrl, String? token})
      : _client = Client(
          baseUrl: baseUrl ?? 'https://api.exemplo.com',
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
  
  Future<List<User>> getUsers({int page = 1, int perPage = 20}) async {
    try {
      final response = await _client
        .withParams({
          'page': page.toString(),
          'per_page': perPage.toString(),
          'sort': 'name',
        })
        .get('/users');
      
      response.throwIfFailed();
      
      final data = response.json()['data'] as List;
      return data.map((item) => User.fromJson(item)).toList();
    } catch (e) {
      print('Erro ao buscar usuários: $e');
      rethrow;
    }
  }
  
  Future<User> createUser(Map<String, dynamic> userData) async {
    try {
      final response = await _client
        .post('/users')
        .withData(userData);
      
      if (isValidationError(response)) {
        final errors = response.json()['errors'] as Map<String, List<String>>;
        throw ValidationException(errors);
      }
      
      response.throwIfFailed();
      
      return User.fromJson(response.json());
    } catch (e) {
      print('Erro ao criar usuário: $e');
      rethrow;
    }
  }
  
  Future<bool> deleteUser(String id) async {
    try {
      final response = await _client.delete('/users/$id');
      return response.noContent();
    } catch (e) {
      print('Erro ao excluir usuário: $e');
      return false;
    }
  }
}

// Uso
final apiService = ApiService(
  baseUrl: 'https://api.exemplo.com',
  token: 'seu-token-jwt',
);

final users = await apiService.getUsers(page: 2, perPage: 50);
```

## Considerações de Desempenho

- **Reuse instâncias do cliente** quando possível para aproveitar a configuração
- **Considere o timeout** para evitar que requisições fiquem pendentes indefinidamente
- **Libere recursos** após o uso, especialmente para uploads/downloads grandes

## Integração com RouteService

O cliente HTTP é usado internamente pelo `RouteService`, mas você pode personalizá-lo:

```dart
final response = await routeService.call(
  generator: RouteGenerator(name: 'luminix.users.index'),
  tap: (client) => client
    .withParams({'status': 'active'})
    .withHeaders({'X-Custom-Header': 'value'}),
);
```

Este padrão permite que você configure o cliente HTTP para cada requisição individual, enquanto ainda aproveita a infraestrutura de rotas do Luminix Flutter.