import 'package:dartx/dartx.dart';
import 'package:dio/dio.dart';

import 'reducible.dart';
import 'types/route_definition.dart';
import 'types/route_generator.dart';

class RouteCallConfig extends Options {
  final Map<String, dynamic>? data;

  RouteCallConfig({
    this.data,
    super.method,
    super.sendTimeout,
    super.receiveTimeout,
    super.extra,
    super.headers,
    super.preserveHeaderCase,
    super.responseType,
    super.contentType,
    super.validateStatus,
    super.receiveDataWhenStatusError,
    super.followRedirects,
    super.maxRedirects,
    super.persistentConnection,
    super.requestEncoder,
    super.responseDecoder,
    super.listFormat,
  });
}

class RouteFacade with Reducible {
  final Map<String, dynamic> routes;
  final String appUrl;

  RouteFacade(this.routes, [this.appUrl = '']);

  // forwards to the `replaceRouteParams` reducer
  dynamic _replaceRouteParams(dynamic value) {
    (this as dynamic).replaceRouteParams(value);
  }

  bool _isRouteDefinition(dynamic route) {
    // Check if route is an array with two or more elements
    if (route is! List || route.length < 2) {
      return false;
    }

    final path = route.first;
    final methods = route.skip(1);

    // Check if path is a string
    if (path is! String) {
      return false;
    }

    // Check if method is a valid HTTP method
    const validMethods = ['get', 'post', 'put', 'patch', 'delete'];
    if (!methods.every((method) => validMethods.contains(method))) {
      return false;
    }

    return true;
  }

  RouteDefinition get(String name) {
    if (!exists(name)) {
      throw Exception('Route $name does not exist.');
    }

    final route = routes.getOrElse(name, () => null);

    return RouteDefinition.fromList(route);
  }

  String url(RouteGenerator generator) {
    // Remove leading and trailing slashes
    final url = get(generator.name).name.replaceAll(RegExp(r'^\/|\/$'), '');

    final regex = RegExp(r'{([^}]+)}');

    if (generator.replacer == null) {
      return appUrl + _replaceRouteParams('/$url');
    }

    final matches = regex.allMatches(url);
    final params = matches.isNotEmpty
        ? matches.map((match) => match.group(1)!).toList()
        : <String>[];
    final replaceKeys =
        generator.replacer!.mapEntries((entry) => entry.key).toList();
    final missingParams =
        params.where((param) => !replaceKeys.contains(param)).toList();
    final extraParams =
        replaceKeys.filter((key) => !params.contains(key)).toList();

    if (missingParams.isNotEmpty) {
      throw Exception(
          'Missing values for parameter(s): ${missingParams.join(', ')}');
    }

    if (extraParams.isNotEmpty) {
      throw Exception('Unexpected parameters: ${extraParams.join(', ')}');
    }

    final newPath = params.fold(
        url,
        (acc, param) =>
            acc.replaceAll('{$param}', '${generator.replacer![param]}'));

    return '$appUrl/$newPath';
  }

  List<String> methods(RouteGenerator generator) {
    return get(generator.name).methods;
  }

  bool exists(String name) {
    return routes.any((key, _) => key == name) &&
        _isRouteDefinition(routes.getOrElse(name, () => null));
  }

  // Improve this method later
  Future<Response> call({
    required RouteGenerator generator,
    required RouteCallConfig config,
  }) async {
    final url = this.url(generator);

    final dioOptions = (this as dynamic).dioOptions(config, generator.name);

    try {
      final dio = Dio();

      final response =
          await dio.request(url, options: dioOptions, data: config.data);

      return response;
    } on DioException catch (error) {
      print(error);
      rethrow;
    }
  }
}
