import 'dart:async';

import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/auth/auth_driver.dart';
import 'package:luminix_flutter/src/http/request.dart' show Request;

class AuthService {
  final Application app;

  Completer<String>? _refreshCompleter;

  AuthService(this.app) {
    // Register a single-flight token refresh callback so multiple concurrent 401s
    // only trigger a single refresh request.
    Request.setTokenRefreshCallback(() async => _singleFlightRefresh());
  }

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

  Future<void> attempt(
    Map<String, dynamic> credentials, [
    bool remember = false,
  ]) {
    return _getDriver().attempt(credentials, remember);
  }

  Future<String> refreshToken() {
    return _getDriver().refreshToken();
  }

  Future<void> logout() {
    // Clear the global callback to avoid accidental refresh attempts after logout
    Request.clearTokenRefreshCallback();
    return _getDriver().logout();
  }

  /// Ensures only one refresh call runs at a time. Returns the refreshed token.
  Future<String> _singleFlightRefresh() {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<String>();

    _getDriver()
        .refreshToken()
        .then((token) => _refreshCompleter!.complete(token))
        .catchError((e, st) => _refreshCompleter!.completeError(e, st))
        .whenComplete(() => _refreshCompleter = null);

    return _refreshCompleter!.future;
  }

  @override
  noSuchMethod(Invocation invocation) {
    // if the method being called is not present on the AuthService class call it on the auth driver
    return Function.apply(_getDriver().noSuchMethod, [invocation]);
  }
}
