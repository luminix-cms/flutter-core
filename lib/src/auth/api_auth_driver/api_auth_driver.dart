import 'dart:async';

import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/auth/api_auth_driver/auth_response.dart';
import 'package:luminix_flutter/src/utils/prefs_file.dart';

import '../auth_driver.dart';

class ApiAuthDriver extends AuthDriver {
  final PropertyBag _config;
  final RouteService Function() _routeProvider;

  ApiAuthDriver(this._config, this._routeProvider) {
    _initialize();
  }

  RouteService get _route => _routeProvider();

  final _saveFile = SavedMap('auth_prefs');

  final Completer<bool> _comp = Completer<bool>();

  Future<bool> get isReady => _comp.future;

  AuthResponse? authResponse;

  String? get accessToken => authResponse?.accessToken;

  BaseModel? _user;

  Map<String, dynamic> _methodsMap() => {
    'isReady': isReady,
    'accessToken': accessToken,
  };

  Future<void> _initialize() async {
    try {
      await _load();

      _comp.complete(true);
    } catch (err) {
      print(err);
      logout();
      _comp.completeError(err);
    }
  }

  @override
  BaseModel? user() {
    if (_user == null && authResponse != null) {
      final userFactory = _config.get('auth.model') as BaseModelFactory?;
      _user = userFactory?.call(authResponse!.user);
    }

    return _user;
  }

  @override
  dynamic id() => user()?.getKey();

  @override
  bool check() => authResponse != null;

  AuthResponse getAuthResponse(Map<String, dynamic> response) {
    return AuthResponse(
      accessToken: response['plainTextToken'],
      refreshToken: response['refreshToken'],
      expiresIn: response['expiresIn'],
      user: response['user'],
    );
  }

  @override
  Future<void> attempt(
    Map<String, dynamic> credentials, [
    bool remember = false,
  ]) async {
    final route = RouteGenerator(
      name: _config.get('auth.routes.login') ?? 'login',
    );

    final response = await _route.call(
      generator: route,
      tap: (client) =>
          client.copyWith(data: {...credentials, 'remember': remember}),
    );

    if (response.failed()) {
      throw Exception(response.json()['message']);
    }

    authResponse = getAuthResponse(response.json());
    _saveFile.save(authResponse!.toJson());
  }

  @override
  Future<String> refreshToken() async {
    if (_config.get('auth.routes.refresh') case String routeName) {
      final response = await _route.call(
        generator: RouteGenerator(name: routeName),
        tap: (client) => client.copyWith(
          headers: {'Authorization': 'Bearer ${accessToken ?? ''}'},
        ),
      );

      if (response.failed()) {
        throw Exception(response.json()['message']);
      }

      authResponse = getAuthResponse(response.json());
      _saveFile.save(authResponse!.toJson());
    }

    throw Exception('No route name provided');
  }

  @override
  Future<void> logout() {
    _user = null;
    authResponse = null;
    return _saveFile.clear();
  }

  Future<void> _load() async {
    final map = await _saveFile.load();
    if (map != null) {
      authResponse = AuthResponse.fromJson(map);
    }
  }

  @override
  noSuchMethod(Invocation invocation) {
    final method = invocation.memberName
        .toString()
        .replaceAll('Symbol("', '')
        .replaceAll('")', '');
    if (_methodsMap().containsKey(method)) {
      return _methodsMap()[method];
    }

    return super.noSuchMethod(invocation);
  }
}
