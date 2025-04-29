# 4. Luminix ORM

## Geração de Models
Antes de gerar os modelos, certifique-se de que o arquivo `manifest.json` está devidamente configurado e localizado no diretório `lib/src/models/`. Este arquivo é essencial para definir os modelos e rotas disponíveis na aplicação.

Para gerar os modelos automaticamente, utilize o seguinte comando:

```bash
flutter pub run build_runner build
```

Isso criará um arquivo chamado `models.dart` no mesmo diretório onde está o `manifest.json`, contendo todas as classes de modelo configuradas.

Exemplo de modelo gerado:

```dart
class User extends BaseModel {
  @override
  String get type => 'user';

  @override
  String get schemaName => 'users';

  @override
  Map<String, dynamic> get schema => {
    'fillable': ['name', 'email'],
    'relations': {
      'posts': {'type': 'HasMany', 'model': 'Post'}
    }
  };
}
```

---

## Operações CRUD
Os modelos gerados permitem realizar operações CRUD de forma simples:

### Criar
```dart
final user = User({'name': 'John Doe', 'email': 'john@example.com'});
await user.save();
print('Usuário criado: ${user.getAttribute('name')}');
```

### Ler
```dart
final user = await User.find(1);
if (user != null) {
  print('Usuário encontrado: ${user.getAttribute('name')}');
}
```

### Atualizar
```dart
user.setAttribute('name', 'Jane Doe');
await user.save();
print('Usuário atualizado: ${user.getAttribute('name')}');
```

### Deletar
```dart
await user.delete();
print('Usuário deletado.');
```

---

## Query Builder
O Luminix ORM fornece um poderoso Query Builder para criar consultas complexas:

### Consultas Básicas
```dart
// Buscar usuários ativos
final users = await User.query()
  .where('active', true)
  .orderBy('created_at', SortDirection.desc)
  .get();

for (final user in users.data) {
  print('Usuário ativo: ${user.getAttribute('name')}');
}
```

### Paginação
```dart
// Buscar usuários com paginação
final paginatedUsers = await User.query()
  .paginate(15);

print('Página atual: ${paginatedUsers.currentPage}');
for (final user in paginatedUsers.data) {
  print('Usuário: ${user.getAttribute('name')}');
}
```

### Relações
```dart
// Incluir relações (exemplo: posts do usuário)
final usersWithPosts = await User.query()
  .with(['posts'])
  .get();

for (final user in usersWithPosts.data) {
  print('Usuário: ${user.getAttribute('name')}');
}
```

### Consultas Avançadas
```dart
// Consultar usuários com múltiplos filtros
final advancedUsers = await User.query()
  .where('active', true)
  .whereBetween('age', [18, 30])
  .whereHas('posts', (query) {
    query.where('published', true);
  })
  .get();

for (final user in advancedUsers.data) {
  print('Usuário avançado: ${user.getAttribute('name')}');
}
```

---

Com essas funcionalidades, o Luminix ORM oferece uma solução robusta para manipulação de dados, permitindo operações CRUD, consultas avançadas e gerenciamento de relações de forma eficiente.