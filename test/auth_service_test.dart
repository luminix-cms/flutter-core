import 'package:flutter_test/flutter_test.dart';
import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeDriver extends AuthDriver {
  dynamic identity;

  @override
  Future<void> attempt(
    Map<String, dynamic> credentials, [
    bool remember = false,
  ]) async {
    identity = credentials['id'];
  }

  @override
  bool check() => identity != null;

  @override
  Future<void> logout() async => identity = null;

  @override
  Future<String> refreshToken() async => 'token';

  @override
  BaseModel? user() => null;

  @override
  dynamic id() => identity;
}

AuthService _buildService(AuthDriver driver) {
  final app = Application();
  app.singleton('config', () => PropertyBag.fromMap(map: {}));
  app.singleton('auth:api', () => driver);

  final service = AuthService(app);
  app.singleton('auth', () => service);
  return service;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService — identidade', () {
    test('notifica os ouvintes com o id após o login', () async {
      final service = _buildService(_FakeDriver());
      final vistos = <dynamic>[];
      service.addIdentityListener(vistos.add);

      await service.attempt({'id': 42});

      expect(vistos, [42]);
    });

    test('notifica com nulo após o logout', () async {
      final service = _buildService(_FakeDriver());
      final vistos = <dynamic>[];

      await service.attempt({'id': 42});
      service.addIdentityListener(vistos.add);
      await service.logout();

      expect(vistos, [null]);
    });

    test('para de notificar depois de remover o ouvinte', () async {
      final service = _buildService(_FakeDriver());
      final vistos = <dynamic>[];
      void ouvinte(dynamic id) => vistos.add(id);

      service.addIdentityListener(ouvinte);
      service.removeIdentityListener(ouvinte);
      await service.attempt({'id': 42});

      expect(vistos, isEmpty);
    });

    test('ready resolve pelo driver', () async {
      final service = _buildService(_FakeDriver());

      await expectLater(service.ready, completes);
    });
  });

  group('ApiAuthDriver.ready', () {
    ApiAuthDriver buildDriver() => ApiAuthDriver(
      PropertyBag.fromMap(map: {}),
      () => throw StateError('a rota não deve ser usada'),
    );

    test('resolve quando não há sessão guardada', () async {
      SharedPreferences.setMockInitialValues({});

      await expectLater(buildDriver().ready, completes);
    });

    test('resolve mesmo com a sessão corrompida', () async {
      SharedPreferences.setMockInitialValues({'auth_prefs': 'isso não é json'});

      final driver = buildDriver();

      await expectLater(driver.ready, completes);
      expect(driver.check(), isFalse);
    });
  });
}
