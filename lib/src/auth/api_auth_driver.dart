import 'dart:async';

import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/utils/prefs_file.dart';

import 'auth_driver.dart';

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

  Map<String, dynamic>? _user;
  String? _accessToken;
  String? _refreshToken;
  int? _expiresIn;

  @override
  bool get isAuthenticated => _accessToken != null;

  String get accessToken => _accessToken!;

  @override
  Map<String, dynamic>? get user => _user;

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
  Future<void> attemptLogin(String email, String password) async {
    final route =
        RouteGenerator(name: _config.get('auth.routes.login') ?? 'login');

    final response = await _route.call(
      generator: route,
      tap: (client) => client.copyWith(data: {
        'email': email,
        'password': password,
      }),
    );

    if (response.failed()) {
      throw Exception(response.json()['message']);
    }

    _accessToken = response.json()['plainTextToken'];
    _save();
  }

  @override
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresIn = null;
    await _save();
  }

  Future<void> _save() async {
    await _saveFile.save({
      'access_token': _accessToken,
      'refresh_token': _refreshToken,
      'expires_in': _expiresIn,
      'user': _user,
    });
  }

  Future<void> _load() async {
    final map = await _saveFile.load();
    _accessToken = map['access_token'];
    _refreshToken = map['refresh_token'];
    _expiresIn = map['expires_in'];
    _user = map['user'];
  }
}
