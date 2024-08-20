import 'package:dio/dio.dart';
import 'package:luminix_flutter_core/src/route.dart';
import 'package:luminix_flutter_core/src/types/route_generator.dart';

import 'property_bag.dart';
import 'extensions/string.dart';

enum SortDirection {
  asc,
  desc,
}

enum Filter {
  notEquals,
  greaterThan,
  greaterThanOrEquals,
  lessThan,
  lessThanOrEquals,
}

class Builder {
  final PropertyBag bag = PropertyBag.fromMap(map: {});
  final String schemaKey;
  final RouteFacade route;

  Builder({
    required this.schemaKey,
    required this.route,
  });

  void lock(String path) {
    bag.lock(path);
  }

  Builder whereBetween<T>(String key, (T, T) value) {
    if (!bag.has('where')) {
      bag.set('where', {});
    }
    final (a, b) = value;
    bag.set('where.${key.camelCase()}Between', [a, b]);
    return this;
  }

  Builder whereNotBetween<T>(String key, (T, T) value) {
    if (!bag.has('where')) {
      bag.set('where', {});
    }
    final (a, b) = value;
    bag.set('where.${key.camelCase()}NotBetween', [a, b]);
    return this;
  }

  Builder whereNull(String key) {
    if (!bag.has('where')) {
      bag.set('where', {});
    }
    bag.set('where.${key.camelCase()}Null', true);
    return this;
  }

  Builder whereNotNull(String key) {
    if (!bag.has('where')) {
      bag.set('where', {});
    }
    bag.set('where.${key.camelCase()}NotNull', true);
    return this;
  }

  Builder limit(int value) {
    bag.set('per_page', value);
    return this;
  }

  Builder where(
      {required String key, required dynamic value, Filter? filterOperator}) {
    if (!bag.has('where')) {
      bag.set('where', {});
    }

    if (value == null) {
      throw Exception('Invalid value provided for where clause.');
    }

    if (filterOperator == null) {
      bag.set('where.${key.camelCase()}', value);
      return this;
    }

    final String suffix = filterOperator.name.capitalize();

    bag.set('where.${key.camelCase()}$suffix', value);

    return this;
  }

  Builder orderBy(String column,
      [SortDirection direction = SortDirection.asc]) {
    bag.set('order_by', '$column:${direction.name}');
    return this;
  }

  Builder searchBy(String term) {
    bag.set('q', term);
    return this;
  }

  Builder minified() {
    bag.set('minified', true);
    return this;
  }

  Builder unset(String key) {
    bag.delete(key);
    return this;
  }

  Builder include(dynamic searchParams) {
    throw UnimplementedError();
  }

  Future<Response> _exec([int page = 1, String? replaceLinksWith]) async {
    try {
      bag.set('page', page);

      // TODO: Return model
      return await route.call(
          generator: RouteGenerator(name: 'luminix.$schemaKey.index'),
          config: RouteCallConfig(
            extra: bag.all(),
          ));
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  get([int page = 1, String? replaceLinksWith]) async {
    throw UnimplementedError();
  }

  Future first() async {
    throw UnimplementedError();
  }

  Future find(dynamic id) async {
    throw UnimplementedError();
  }

  Future all() async {
    throw UnimplementedError();
  }
}
