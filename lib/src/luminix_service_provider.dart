import 'package:get_it/get_it.dart';
import 'package:luminix_flutter/luminix_flutter.dart';

final getIt = GetIt.instance;

class LuminixServiceProvider extends ServiceProvider {
  LuminixServiceProvider(super.application);

  @override
  void register() {
    registerServices();
  }

  @override
  void boot() {
    // TODO: register macros
  }

  void registerServices() {
    app.singleton('config', () {
      // TODO: check for manifest in the configuration
      final config = PropertyBag.fromMap(map: Map.from(app.configuration));

      if (!config.has('auth.user')) {
        config.set('auth.user', null);
      }

      config.lock('auth.user');

      return config;
    });

    app.singleton('route', () {
      return RouteService(
        routes: app.configuration['manifest']?['routes'] ?? {},
        appUrl: app.configuration['app']?['url'] ?? '',
        authProvider: () => app.make('auth'),
      );
    });

    app.singleton('schemas', () {
      return PropertyBag.fromMap(
        map: app.configuration['manifest']['models'] ?? {},
      );
    });

    app.singleton('auth:api', () {
      return ApiAuthDriver(app.make('config'), () => app.make('route'));
    });

    app.singleton('auth', () {
      return AuthService(app);
    });

    _replaceSingleton<RouteService>(app.make('route'));
    _replaceSingleton<PropertyBag>(app.make('config'));
  }

  @override
  void flush() {
    _unregisterSingleton<RouteService>();
    _unregisterSingleton<PropertyBag>();
  }

  void _replaceSingleton<T extends Object>(T instance) {
    _unregisterSingleton<T>();
    getIt.registerSingleton<T>(instance);
  }

  void _unregisterSingleton<T extends Object>() {
    if (getIt.isRegistered<T>()) {
      getIt.unregister<T>();
    }
  }

  @override
  String toString() => 'LuminixServiceProvider';
}
