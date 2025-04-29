# Autenticação no Luminix Flutter

O Luminix Flutter fornece um sistema de autenticação completo e flexível, projetado para integrar-se perfeitamente com APIs Laravel/Luminix. Este documento explica como configurar e utilizar os recursos de autenticação em seu aplicativo.

## Visão Geral

O sistema de autenticação do Luminix Flutter consiste em:

1. **AuthService** - Serviço principal que gerencia o estado de autenticação
2. **AuthDriver** - Interface que define o comportamento de autenticação
3. **ApiAuthDriver** - Implementação padrão que trabalha com tokens de API
4. **Armazenamento Persistente** - Mecanismo para armazenar tokens e credenciais entre sessões

## Configuração

### Configuração Básica

Para utilizar a autenticação, você precisa configurar o `AuthService` durante a inicialização do seu aplicativo:

```dart
void main() {
  runApp(
    LuminixApp(
      configuration: AppConfiguration(
        url: 'https://api.seudominio.com',
        auth: AuthConfiguration(
          userModel: (data) => Usuario(data),
          driver: 'api', // 'api' é o driver padrão
        ),
      ),
      child: MeuAplicativo(),
    ),
  );
}
```

O parâmetro `userModel` é uma função que recebe dados do usuário e retorna uma instância do modelo de usuário. Isso permite que você defina seu próprio modelo de usuário, que deve estender a classe `BaseModel`.

### Rotas de Autenticação

O sistema de autenticação espera que certas rotas estejam definidas no arquivo `manifest.json`. As rotas padrão são:

```json
{
  "routes": {
    "login": ["/api/auth/login", "post"],
    "logout": ["/api/auth/logout", "post"],
    "refresh": ["/api/auth/refresh", "post"],
    "me": ["/api/auth/me", "get"]
  }
}
```

Você pode personalizar essas rotas em sua configuração:

```dart
LuminixApp(
  configuration: AppConfiguration(
    auth: AuthConfiguration(
      userModel: (data) => Usuario(data),
      driver: 'api',
    ),
    manifest: {
      "auth": {
        "routes": {
          "login": "custom.login.route",
          "logout": "custom.logout.route",
          "refresh": "custom.refresh.route",
          "me": "custom.me.route"
        }
      }
    }
  ),
  // ...
)
```

## Uso Básico

### Acessar o Serviço de Autenticação

```dart
// Em qualquer widget onde o LuminixApp está disponível no contexto
final authService = LuminixApp.of(context).app.make('auth');

// Ou se estiver usando GetIt
final authService = getIt.get<AuthService>();
```

### Login

Para autenticar um usuário:

```dart
try {
  await authService.attempt({
    'email': 'usuario@exemplo.com',
    'password': 'senha123',
    // Parâmetro opcional para lembrar o usuário
    'remember': true,
  });
  
  // Login bem-sucedido
  print('Usuário autenticado');
} catch (e) {
  // Tratamento de erro de autenticação
  print('Erro ao fazer login: $e');
}
```

### Verificar Autenticação

Para verificar se um usuário está autenticado:

```dart
if (authService.check()) {
  // Usuário está autenticado
  print('Usuário autenticado');
} else {
  // Usuário não está autenticado
  print('Usuário não autenticado');
}
```

### Obter Usuário Atual

Para obter o usuário autenticado:

```dart
final user = authService.user();
if (user != null) {
  print('Usuário: ${user.getAttribute('name')}');
  print('Email: ${user.getAttribute('email')}');
}
```

### Logout

Para encerrar a sessão do usuário:

```dart
await authService.logout();
// Usuário desconectado
```

## Integração com UI

### Exemplo de Tela de Login

```dart
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage != null)
              Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              child: _isLoading
                  ? CircularProgressIndicator(strokeWidth: 2.0)
                  : Text('ENTRAR'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = LuminixApp.of(context).app.make('auth');
      
      await authService.attempt({
        'email': _emailController.text,
        'password': _passwordController.text,
      });
      
      // Login bem-sucedido, navegar para a tela principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha ao fazer login. Verifique suas credenciais.';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

### Widget de Proteção de Rota

Este widget verifica se o usuário está autenticado antes de mostrar o conteúdo protegido:

```dart
class AuthGuard extends StatelessWidget {
  final Widget child;
  final Widget? loginScreen;

  const AuthGuard({
    Key? key,
    required this.child,
    this.loginScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = LuminixApp.of(context).app.make('auth');
    
    return FutureBuilder<bool>(
      future: Future.value(authService.check()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        final isAuthenticated = snapshot.data ?? false;
        
        if (isAuthenticated) {
          return child;
        } else {
          return loginScreen ?? LoginScreen();
        }
      },
    );
  }
}

// Uso
MaterialApp(
  home: AuthGuard(
    child: HomeScreen(),
    loginScreen: LoginScreen(),
  ),
);
```

## Recursos Avançados

### Drivers de Autenticação Personalizados

Você pode criar seus próprios drivers de autenticação implementando a interface `AuthDriver`:

```dart
class CustomAuthDriver extends AuthDriver {
  final PropertyBag _config;
  
  CustomAuthDriver(this._config);
  
  @override
  Future<void> attempt(Map<String, dynamic> credentials, [bool remember = false]) async {
    // Implementação personalizada de login
  }
  
  @override
  bool check() {
    // Verificar se o usuário está autenticado
  }
  
  @override
  Future<void> logout() async {
    // Implementação de logout
  }
  
  @override
  BaseModel? user() {
    // Retornar o usuário atual
  }
  
  @override
  dynamic id() {
    // Retornar o ID do usuário
  }
}
```

Registre seu driver personalizado no LuminixApp:

```dart
class MeuAppServiceProvider extends ServiceProvider {
  MeuAppServiceProvider(super.application);
  
  @override
  void register() {
    // Registrar o driver personalizado
    app.singleton('auth:custom', () {
      return CustomAuthDriver(app.make('config'));
    });
  }
}

// Usar o driver personalizado na configuração
LuminixApp(
  configuration: AppConfiguration(
    auth: AuthConfiguration(
      driver: 'custom',
      userModel: (data) => Usuario(data),
    ),
  ),
  providers: [
    MeuAppServiceProvider.new,
  ],
  // ...
)
```

### Refresh Token

O `ApiAuthDriver` suporta automaticamente refresh tokens. Se o token de acesso expirar, ele tentará obter um novo token usando o refresh token:

```dart
// O refresh token é gerenciado automaticamente pelo ApiAuthDriver
// Não é necessário código adicional para lidar com a renovação de tokens
```

### Eventos de Autenticação

Para reagir a eventos de autenticação, você pode usar callbacks:

```dart
class AuthEventsHandler {
  void setup(AuthService authService) {
    authService.onLogin((user) {
      print('Usuário logado: ${user.getAttribute('name')}');
      // Inicializar serviços que dependem de autenticação
    });
    
    authService.onLogout(() {
      print('Usuário desconectado');
      // Limpar dados sensíveis ou caches específicos do usuário
    });
  }
}
```

## Solução de Problemas

### Erros Comuns

1. **Erro "Invalid credentials"**
   - Verifique se o email e a senha estão corretos
   - Confirme que o usuário existe no sistema

2. **Erro "Token expired"**
   - O refresh token também expirou ou não está disponível
   - Faça logout e solicite que o usuário faça login novamente

3. **Erro "Unable to load user"**
   - O modelo de usuário pode estar incorreto
   - Verifique se o userModel está configurado corretamente

### Depuração

Para ativar logs de autenticação detalhados:

```dart
LuminixApp(
  configuration: AppConfiguration(
    debug: true,
    // Outras configurações...
  ),
  // ...
)
```

## Práticas Recomendadas

1. **Segurança**
   - Nunca armazene senhas em texto simples
   - Use HTTPS para todas as comunicações de autenticação
   - Implemente timeouts para tokens de acesso

2. **Experiência do Usuário**
   - Persista a sessão quando apropriado (remember: true)
   - Forneça feedback claro sobre erros de autenticação
   - Adicione opção "Esqueci minha senha"

3. **Fluxo de Trabalho**
   - Centralize a lógica de autenticação em um serviço ou provider
   - Use widgets de proteção para rotas seguras
   - Implemente desconexão automática após inatividade

## Exemplos Adicionais

### Verificação de Permissões

```dart
bool userCanEditPost(BaseModel user, BaseModel post) {
  return user.getKey() == post.getAttribute('user_id') || 
         user.getAttribute('role') == 'admin';
}

// Uso
if (userCanEditPost(authService.user()!, post)) {
  // Mostrar botão de edição
}
```

### Integração com Middleware de Rota

```dart
class AuthMiddleware extends RouteAware {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final authService = getIt.get<AuthService>();
    if (!authService.check()) {
      Navigator.of(navigatorKey.currentContext!).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }
}
```

Ao seguir essas orientações, você poderá implementar um sistema de autenticação robusto e seguro em seu aplicativo Luminix Flutter.