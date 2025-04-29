# Trabalhando com Modelos

Este guia explica como trabalhar com os modelos gerados pelo Luminix Flutter a partir do arquivo `manifest.json`. Depois de configurar corretamente o manifesto e executar o gerador de código, você terá acesso a classes Dart tipadas que representam suas entidades de negócio.

## Visão Geral

Os modelos gerados pelo Luminix Flutter fornecem uma camada de abstração sobre os dados da API, permitindo:

- Manipulação de dados com tipagem segura
- Serialização/deserialização automática
- Gerenciamento de relacionamentos entre modelos
- Operações CRUD simplificadas
- Consultas fluentes similares ao Eloquent do Laravel

## Estrutura dos Modelos Gerados

Quando você executa o comando de geração, o Luminix Flutter cria um arquivo `models.dart` contendo classes para cada modelo definido no manifesto. Cada classe gerada:

- Estende a classe `BaseModel`
- Implementa getters e setters tipados para os atributos
- Configura relacionamentos (hasOne, hasMany, belongsTo, etc.)
- Fornece métodos para operações CRUD (save, update, delete)
- Implementa um builder de consultas

## Uso Básico dos Modelos

### Criando uma Instância

```dart
// Criando um modelo vazio
final usuario = Usuario();

// Criando com atributos iniciais
final produto = Produto({
  'nome': 'Smartphone XYZ',
  'preco': 1999.99,
  'disponivel': true,
  'categoria_id': 5
});
```

### Acessando e Modificando Atributos

Os modelos gerados fornecem métodos para acessar e modificar atributos de forma tipada:

```dart
// Acessando atributos
final nomeUsuario = usuario.getAttribute('nome');
final email = usuario.getAttribute('email');

// Também é possível usar getters gerados (se disponíveis)
final nomeUsuario = usuario.nome;
final email = usuario.email;

// Modificando atributos
usuario.setAttribute('nome', 'João Silva');
usuario.setAttribute('email', 'joao@exemplo.com');

// Também é possível usar setters gerados (se disponíveis)
usuario.nome = 'João Silva';
usuario.email = 'joao@exemplo.com';
```

### Operações CRUD Básicas

#### Salvar um Modelo

```dart
// Criar ou atualizar um modelo
// Se o modelo já existe (tem ID), será atualizado
// Se o modelo é novo, será criado
await usuario.save();

// Com opções adicionais
await produto.save(
  ModelSaveOptions(
    // Enviar apenas campos modificados (padrão: true)
    sendsOnlyModifiedFields: true, 
    
    // Dados adicionais a serem enviados com a requisição
    additionalPayload: {
      'publish': true,
    }
  )
);
```

#### Atualizar um Modelo

```dart
// Atualizar apenas campos específicos
await usuario.update({
  'status': 'ativo',
  'ultimo_acesso': DateTime.now().toIso8601String(),
});
```

#### Excluir um Modelo

```dart
// Exclusão simples
await usuario.delete();

// Exclusão forçada (para modelos com soft delete)
await usuario.forceDelete();

// Restaurar modelo excluído com soft delete
await usuario.restore();
```

## Trabalhando com Relacionamentos

Os modelos gerados incluem métodos para acessar e gerenciar relacionamentos entre entidades.

### Tipos de Relacionamentos

- **hasOne**: Um para um
- **hasMany**: Um para muitos
- **belongsTo**: Pertence a
- **belongsToMany**: Muitos para muitos
- **morphTo/morphMany/morphOne**: Relacionamentos polimórficos

### Acessando Relacionamentos

```dart
// Acessando um relacionamento belongsTo
final categoria = await produto.relation('categoria').get();

// Acessando um relacionamento hasMany
final pedidos = await usuario.relation('pedidos').get();

// Acessando um relacionamento belongsToMany
final tags = await produto.relation('tags').get();
```

### Carregando Relacionamentos Aninhados

```dart
// Carregar produtos com suas categorias
final query = Produto.query().withRelation('categoria');
final produtos = await query.get();

// Produtos incluirão o relacionamento 'categoria' preenchido
```

### Gerenciando Relacionamentos

#### Relacionamento hasOne/hasMany

```dart
// Salvar um modelo relacionado
final endereco = Endereco({
  'rua': 'Av. Paulista',
  'numero': '1000',
  'cidade': 'São Paulo',
});

// Associar ao usuário e salvar
await usuario.relation('endereco').save(endereco);
```

#### Relacionamento belongsTo

```dart
// Associar produto a uma categoria existente
final categoria = await Categoria.query().find(5);
await produto.relation('categoria').associate(categoria);
```

#### Relacionamento belongsToMany

```dart
// Anexar uma tag a um produto
await produto.relation('tags').attach(tagId);

// Anexar com dados de tabela pivô
await produto.relation('tags').attach(tagId, {
  'created_by': adminId,
  'featured': true,
});

// Desanexar uma tag
await produto.relation('tags').detach(tagId);

// Sincronizar tags (substitui todas as tags existentes)
await produto.relation('tags').sync([tag1Id, tag2Id, tag3Id]);

// Sincronizar com dados de tabela pivô
await produto.relation('tags').syncWithPivotValues(
  [tag1Id, tag2Id], 
  {'status': 'ativo'}
);
```

## Query Builder

Os modelos gerados incluem um poderoso query builder para consultas avançadas.

### Consultas Básicas

```dart
// Consulta básica que retorna todos os usuários
final usuarios = await Usuario.query().get();

// Paginação
final usuariosPagina2 = await Usuario.query().get(2); // página 2

// Limitar resultados
final top10Produtos = await Produto.query().limit(10).get();
```

### Filtragem

```dart
// Filtro simples
final produtosAtivos = await Produto.query()
  .where(key: 'ativo', value: true)
  .get();

// Encadeando filtros
final smarthphonesCaros = await Produto.query()
  .where(key: 'categoria_id', value: 5) // smartphones
  .where(key: 'preco', value: 1000, filterOperator: Filter.greaterThan)
  .get();

// Filtros NULL
final usuariosSemEndereco = await Usuario.query()
  .whereNull('endereco_id')
  .get();

// Filtros NOT NULL
final usuariosComEndereco = await Usuario.query()
  .whereNotNull('endereco_id')
  .get();

// Filtros BETWEEN
final produtosPrecoMedio = await Produto.query()
  .whereBetween('preco', (500, 1500))
  .get();

// Filtros NOT BETWEEN
final produtosForaFaixaPreco = await Produto.query()
  .whereNotBetween('preco', (500, 1500))
  .get();
```

### Ordenação

```dart
// Ordenação padrão (ascendente)
final usuariosOrdemAlfabetica = await Usuario.query()
  .orderBy('nome')
  .get();

// Ordenação descendente
final produtosMaisCaros = await Produto.query()
  .orderBy('preco', SortDirection.desc)
  .get();
```

### Busca

```dart
// Busca em campos de texto
final resultadosBusca = await Produto.query()
  .searchBy('smartphone')
  .get();
```

### Métodos Auxiliares

```dart
// Encontrar pelo ID
final usuario = await Usuario.query().find(123);

// Obter apenas o primeiro resultado
final produtoDestaque = await Produto.query()
  .where(key: 'destaque', value: true)
  .first();

// Obter todos os resultados (sem paginação)
final todasCategorias = await Categoria.query().all();
```

## Processando Respostas Paginadas

As consultas com `get()` retornam um objeto `ModelPaginatedResponse` que contém metadados de paginação:

```dart
final response = await Produto.query().get();

// Dados
final produtos = response.data;

// Informações de paginação
print('Página atual: ${response.currentPage}');
print('Total de páginas: ${response.lastPage}');
print('Itens por página: ${response.perPage}');
print('Total de itens: ${response.total}');
print('De: ${response.from} até: ${response.to}');

// Processando os resultados
for (final produto in produtos) {
  print('Produto: ${produto.getAttribute('nome')}');
}
```

## Exemplos Práticos

### Cadastro de Usuário

```dart
Future<void> cadastrarUsuario(Map<String, dynamic> dados) async {
  try {
    final usuario = Usuario(dados);
    await usuario.save();
    
    // Adicionar endereço
    if (dados['endereco'] != null) {
      final endereco = Endereco(dados['endereco']);
      await usuario.relation('endereco').save(endereco);
    }
    
    print('Usuário cadastrado com sucesso: ID ${usuario.getKey()}');
    return usuario;
  } catch (e) {
    print('Erro ao cadastrar usuário: $e');
    rethrow;
  }
}
```

### Listagem de Produtos com Filtros

```dart
Future<List<Produto>> buscarProdutos({
  String? termoBusca, 
  int? categoriaId,
  double? precoMinimo,
  double? precoMaximo,
  int pagina = 1,
}) async {
  final query = Produto.query();
  
  // Aplicar filtros somente se fornecidos
  if (termoBusca != null && termoBusca.isNotEmpty) {
    query.searchBy(termoBusca);
  }
  
  if (categoriaId != null) {
    query.where(key: 'categoria_id', value: categoriaId);
  }
  
  if (precoMinimo != null && precoMaximo != null) {
    query.whereBetween('preco', (precoMinimo, precoMaximo));
  } else if (precoMinimo != null) {
    query.where(
      key: 'preco', 
      value: precoMinimo, 
      filterOperator: Filter.greaterThanOrEquals
    );
  } else if (precoMaximo != null) {
    query.where(
      key: 'preco', 
      value: precoMaximo, 
      filterOperator: Filter.lessThanOrEquals
    );
  }
  
  // Ordenação e paginação
  query.orderBy('nome');
  final response = await query.get(pagina);
  
  return response.data;
}
```

### Atualização de Pedido com Relacionamentos

```dart
Future<void> atualizarStatusPedido(int pedidoId, String novoStatus) async {
  final pedido = await Pedido.query().find(pedidoId);
  if (pedido == null) {
    throw Exception('Pedido não encontrado');
  }
  
  // Atualizar status
  await pedido.update({
    'status': novoStatus,
    'atualizado_em': DateTime.now().toIso8601String(),
  });
  
  // Se o pedido foi concluído, atualizar estoque dos produtos
  if (novoStatus == 'concluido') {
    final itensPedido = await pedido.relation('itens').get();
    
    for (final item in itensPedido.data) {
      final produtoId = item.getAttribute('produto_id');
      final quantidade = item.getAttribute('quantidade');
      
      final produto = await Produto.query().find(produtoId);
      if (produto != null) {
        final estoqueAtual = produto.getAttribute('estoque');
        await produto.update({
          'estoque': estoqueAtual - quantidade,
        });
      }
    }
  }
}
```

## Práticas Recomendadas

1. **Use modelos em vez de mapas crus**
   - Aproveite a tipagem e validação fornecidas pelos modelos

2. **Centralize a lógica de negócios**
   - Crie métodos específicos nos modelos ou em repositórios

3. **Carregue apenas o necessário**
   - Use `limit()`, paginação e consultas específicas para reduzir o tráfego

4. **Valide antes de salvar**
   - Adicione validação antes de enviar dados para a API

5. **Gerencie cuidadosamente os relacionamentos**
   - Carregue relacionamentos apenas quando necessário
   - Considere o impacto de performance de relacionamentos aninhados

6. **Cache quando apropriado**
   - Para dados que não mudam frequentemente, implemente cache

## Solução de Problemas

### Erros Comuns

1. **"Model not found"**
   - Verifique se o modelo existe no manifesto
   - Confirme que o arquivo models.dart foi gerado corretamente
   - Certifique-se de que está usando o nome correto do modelo

2. **"Route not found"**
   - A rota necessária para o modelo não está definida no manifesto
   - Certifique-se de que as rotas CRUD estão configuradas na API

3. **"Validation errors"**
   - Dados enviados não atendem às regras de validação da API
   - Verifique as mensagens de erro para campos específicos

4. **"Token expired" ou "Unauthorized"**
   - A sessão expirou ou o usuário não está autenticado
   - Refaça o login antes de continuar

### Depuração

Para ajudar na depuração, você pode ativar logs detalhados:

```dart
LuminixApp(
  configuration: AppConfiguration(
    debug: true,
    // Outras configurações...
  ),
  // ...
)
```

## Extensibilidade

### Personalizando Modelos

Você pode estender os modelos gerados para adicionar funcionalidades personalizadas:

```dart
class UsuarioExtendido extends Usuario {
  UsuarioExtendido([Map<String, dynamic>? attributes]) : super(attributes);
  
  // Métodos personalizados
  String nomeCompleto() {
    return '${getAttribute('nome')} ${getAttribute('sobrenome')}';
  }
  
  bool isPremium() {
    return getAttribute('plano') == 'premium';
  }
  
  // Validação personalizada
  bool validarEmail() {
    final email = getAttribute('email');
    return email != null && email.contains('@');
  }
}
```

Ao dominar o uso dos modelos gerados pelo Luminix Flutter, você poderá criar aplicações robustas e bem estruturadas, com código limpo e manutenível.