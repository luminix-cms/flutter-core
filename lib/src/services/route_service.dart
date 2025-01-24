import 'package:dartx/dartx.dart';
import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/http/response.dart';

import '../http/client.dart';
import '../http/utils/is_validation_error.dart';
import '../utils.dart';
import '../reducible.dart';
import '../types/route_definition.dart';

typedef ClientContructor = Client Function();

class RouteService with Reducible {
  final Map<String, dynamic> routes;
  final _client = Client();
  final String appUrl;

  final ApiAuthDriver Function() _authProvider;

  RouteService(
      {required this.routes,
      this.appUrl = '',
      required ApiAuthDriver Function() authProvider})
      : _authProvider = authProvider;

  ApiAuthDriver get auth => _authProvider();

  // forwards to the `replaceRouteParams` reducer
  String _replaceRouteParams(String value) {
    return (this as dynamic).replaceRouteParams(value);
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

    final route = getMapFieldValue(routes, name);

    return RouteDefinition.fromList(route.cast<String>());
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
    // TODO: create extension method 'has' for Map
    return getMapFieldValue(routes, name) != null &&
        _isRouteDefinition(getMapFieldValue(routes, name));
  }

  // Improve this method later
  Future<Response> call({
    required RouteGenerator generator,
    Client Function(Client)? tap,
  }) async {
    final methods = get(generator.name).methods;
    final url = this.url(generator);

    var client = tap?.call(_client) ?? _client;

    // TODO: implement call to reducer `clientOptions`

    final method = methods.first;

    if (auth.isAuthenticated) {
      client = client.withHeaders({
        'Authorization': 'Bearer ${auth.accessToken}',
      });
    }

    final response = await client.call(method, url);

    if (isValidationError(response)) {
      final errors = response.json()['errors'] as Map<String, List<String>>;
      throw Exception(errors.values.join(', '));
    } else if (response.failed()) {
      throw Exception(response.json()['message']);
    }

    return response;
  }
}
