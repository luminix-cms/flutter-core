import 'package:luminix_flutter/src/types/json_encodable.dart';

class AppConfiguration implements JsonEncodable {
  AppConfiguration({
    this.environment,
    this.debug,
    this.url,
    this.bootUrl,
  });

  final String? environment;
  final bool? debug;
  final String? url;
  final String? bootUrl;

  @override
  Map<String, dynamic> toJson() {
    return {
      'environment': environment,
      'debug': debug,
      'url': url,
      'bootUrl': bootUrl,
    };
  }
}
