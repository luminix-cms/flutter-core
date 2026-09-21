import 'package:luminix_flutter/src/application.dart';
import 'package:luminix_flutter/src/property_bag.dart';
import 'package:luminix_flutter/src/service_provider.dart';
import 'package:luminix_flutter/src/services/auth_service.dart';

import 'a11y_licenses.dart';
import 'a11y_service.dart';
import 'config/a11y_configuration.dart';

class LuminixAccessibilityServiceProvider extends ServiceProvider {
  LuminixAccessibilityServiceProvider(super.application);

  AuthService? _auth;
  A11yService? _service;

  @override
  void register() {
    registerA11yFontLicenses();

    app.singleton('a11y', () {
      return A11yService(configuration: _configuration(app) ?? _disabled);
    });
  }

  @override
  Future<void> boot() async {
    final configuration = _configuration(app);
    if (configuration == null || !configuration.enabled) return;

    final service = app.make('a11y') as A11yService;
    _service = service;

    await service.load();

    if (configuration.scope != A11yScopeMode.user) return;

    final auth = app.make('auth') as AuthService;
    _auth = auth;
    auth.addIdentityListener(_onIdentityChanged);

    final bind = auth.ready.then((_) => service.bindToIdentity(auth.id()));

    if (configuration.awaitUserScopeOnBoot) await bind;
  }

  @override
  void flush() {
    _auth?.removeIdentityListener(_onIdentityChanged);
    _auth = null;
    _service?.dispose();
    _service = null;
  }

  void _onIdentityChanged(dynamic id) {
    _service?.bindToIdentity(id);
  }

  static const A11yConfiguration _disabled = A11yConfiguration(enabled: false);

  static A11yConfiguration? _configuration(Application app) {
    final config = app.make('config') as PropertyBag;
    final value = config.get('a11y');
    return value is A11yConfiguration ? value : null;
  }

  @override
  String toString() => 'LuminixAccessibilityServiceProvider';
}
