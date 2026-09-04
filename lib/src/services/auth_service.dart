import 'dart:async';

import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/http/request.dart' show Request;

class AuthService {
  final Application app;

  Completer<String>? _refreshCompleter;

  final List<void Function(dynamic id)> _identityListeners = [];

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

  Future<void> get ready => _getDriver().ready;

  void addIdentityListener(void Function(dynamic id) listener) {
    _identityListeners.add(listener);
  }

  void removeIdentityListener(void Function(dynamic id) listener) {
    _identityListeners.remove(listener);
  }

  void _notifyIdentity(dynamic id) {
    for (final listener in List.of(_identityListeners)) {
      listener(id);
    }
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
  ]) async {
    await _getDriver().attempt(credentials, remember);
    _notifyIdentity(id());
  }

  Future<String> refreshToken() {
    return _getDriver().refreshToken();
  }

  Future<void> logout() async {
    Request.clearTokenRefreshCallback();
    await _getDriver().logout();
    _notifyIdentity(null);
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
