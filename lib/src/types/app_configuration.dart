import 'package:luminix_flutter/src/base_model.dart';
import 'package:luminix_flutter/src/types/json_encodable.dart';

class AppConfiguration implements JsonEncodable {
  const AppConfiguration({
    this.environment,
    this.debug,
    this.url,
    this.manifest,
    this.auth,
  });

  final String? environment;
  final bool? debug;
  final String? url;
  final Map<String, dynamic>? manifest;
  final AuthConfiguration? auth;

  @override
  Map<String, dynamic> toMap() {
    return {
      'manifest': manifest,
      'auth': auth?.toMap(),
      'app': {
        'env': environment,
        'debug': debug,
        'url': url,
      }..removeWhere((key, value) => value == null),
    }..removeWhere((key, value) => value == null);
  }
}

class AuthConfiguration {
  const AuthConfiguration({
    required this.userModel,
    this.driver,
  });

  final String? driver;
  final BaseModelFactory userModel;

  toMap() {
    return {
      'driver': driver,
      'model': userModel,
    };
  }
}
