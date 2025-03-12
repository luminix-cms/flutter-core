import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/auth/auth_driver.dart';

class AuthService {
  final Application app;

  AuthService(this.app);

  void registerDriver(String name, AuthDriver instance) {
    app.singleton('auth:$name', () => instance);
  }

  AuthDriver _getDriver() {
    final config = app.make('config') as PropertyBag;
    return app.make('auth:${config.get('auth.driver', 'api')}');
  }

  BaseModel? user() {
    return _getDriver().user();
  }

  dynamic id() {
    return _getDriver().id();
  }

  bool check() {
    return _getDriver().check();
  }

  Future<void> attempt(Map<String, dynamic> credentials,
      [bool remember = false]) {
    return _getDriver().attempt(credentials, remember);
  }

  Future<void> logout() {
    return _getDriver().logout();
  }

  @override
  noSuchMethod(Invocation invocation) {
    // if the method being called is not present on the AuthService class call it on the auth driver
    return Function.apply(_getDriver().noSuchMethod, [invocation]);
  }
}
