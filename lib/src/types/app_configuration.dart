import 'package:luminix_flutter/src/a11y/config/a11y_configuration.dart';
import 'package:luminix_flutter/src/base_model.dart';
import 'package:luminix_flutter/src/types/json_encodable.dart';

class AppConfiguration implements JsonEncodable {
  const AppConfiguration({
    this.environment,
    this.debug,
    this.url,
    this.manifest,
    this.auth,
    this.a11y,
  });

  final String? environment;
  final bool? debug;
  final String? url;
  final Map<String, dynamic>? manifest;
  final AuthConfiguration? auth;
  final A11yConfiguration? a11y;

  @override
  Map<String, dynamic> toMap() {
    return {
      'manifest': manifest,
      'auth': auth?.toMap(),
      'a11y': a11y,
      'app': {'env': environment, 'debug': debug, 'url': url}
        ..removeWhere((key, value) => value == null),
    }..removeWhere((key, value) => value == null);
  }
}

class AuthConfiguration {
  const AuthConfiguration({
    required this.userModel,
    this.driver,
    this.loginRoute,
    this.refreshRoute,
  });

  final String? driver;
  final BaseModelFactory userModel;
  final String? loginRoute;
  final String? refreshRoute;

  toMap() {
    return {
      'driver': driver,
      'model': userModel,
      if (loginRoute != null || refreshRoute != null)
        'routes': {
          if (loginRoute != null) 'login': loginRoute,
          if (refreshRoute != null) 'refresh': refreshRoute,
        },
    };
  }
}
