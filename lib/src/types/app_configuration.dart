import 'package:luminix_flutter/src/types/json_encodable.dart';

class AppConfiguration implements JsonEncodable {
  const AppConfiguration({
    this.environment,
    this.debug,
    this.url,
    this.manifest,
  });

  final String? environment;
  final bool? debug;
  final String? url;
  final Map<String, dynamic>? manifest;

  @override
  Map<String, dynamic> toJson() {
    return {
      'manifest': manifest,
      'app': {
        'env': environment,
        'debug': debug,
        'url': url,
      }..removeWhere((key, value) => value == null)
    }..removeWhere((key, value) => value == null);
  }
}
