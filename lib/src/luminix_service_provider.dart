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

    app.singleton('auth', () {
      return ApiAuthDriver(
        app.make('config'),
        () => app.make('route'),
      );
    });

    getIt.registerSingleton<RouteService>(app.make('route'));
    // TODO: specify configuration as a singleton
    getIt.registerSingleton<PropertyBag>(app.make('config'));
  }

  @override
  String toString() => 'LuminixServiceProvider';
}
