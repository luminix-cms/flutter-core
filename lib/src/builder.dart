import 'package:luminix_flutter/src/services/route_service.dart';
import 'package:luminix_flutter/src/types/route_generator.dart';

import 'base_model.dart';
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

class ModelPaginatedResponse<T> {
  final List<T> data;
  final int currentPage;
  final int? from;
  final int lastPage;
  final int perPage;
  final int? to;
  final int total;

  ModelPaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.from,
    required this.lastPage,
    required this.perPage,
    required this.to,
    required this.total,
  });

  factory ModelPaginatedResponse.fromJson(
      List<T> items, Map<String, dynamic> map) {
    return ModelPaginatedResponse(
      data: items,
      currentPage: map['meta']['current_page'],
      from: map['meta']['from'],
      lastPage: map['meta']['last_page'],
      perPage: map['meta']['per_page'],
      to: map['meta']['to'],
      total: map['meta']['total'],
    );
  }
}

class Builder<T extends BaseModel> {
  final PropertyBag bag = PropertyBag.fromMap(map: {});

  final String schemaKey;
  final RouteService route;
  final Map<String, dynamic> schema;
  final PropertyBag config;
  final T Function(Map<String, dynamic>) modelBuilder;

  Builder({
    required this.schemaKey,
    required this.route,
    required this.schema,
    required this.config,
    required this.modelBuilder,
  });

  void lock(String path) {
    bag.lock(path);
  }

  Builder<T> whereBetween<R>(String key, (R, R) value) {
    if (!bag.has('where')) {
      bag.set('where', {});
    }
    final (a, b) = value;
    bag.set('where.${key.camelCase()}Between', [a, b]);
    return this;
  }

  Builder<T> whereNotBetween<R>(String key, (R, R) value) {
    if (!bag.has('where')) {
      bag.set('where', {});
    }
    final (a, b) = value;
    bag.set('where.${key.camelCase()}NotBetween', [a, b]);
    return this;
  }

  Builder<T> whereNull(String key) {
    if (!bag.has('where')) {
      bag.set('where', {});
    }
    bag.set('where.${key.camelCase()}Null', true);
    return this;
  }

  Builder<T> whereNotNull(String key) {
    if (!bag.has('where')) {
      bag.set('where', {});
    }
    bag.set('where.${key.camelCase()}NotNull', true);
    return this;
  }

  Builder<T> limit(int value) {
    bag.set('per_page', '$value');
    return this;
  }

  Builder<T> where(
      {required String key, required dynamic value, Filter? filterOperator}) {
    if (!bag.has('where')) {
      bag.set('where', {});
    }

    if (value == null) {
      throw Exception('Invalid value provided for where clause.');
    }

    if (filterOperator == null) {
      bag.set('where.$key', value);
      return this;
    }

    final String suffix = filterOperator.name;

    bag.set('where.$key$suffix', value);

    return this;
  }

  Builder<T> withRelation(String relation) {
    final relations = bag.get('with', <String>[]) as List<String>;
    if (!relations.contains(relation)) {
      relations.add(relation);
    }
    bag.set('with', relations);
    return this;
  }

  // with(relation: string | string[]): this {
  //       const relations: string[] = this.bag.get('with', []) as string[];

  //       const include = Array.isArray(relation) ? relation : [relation];

  //       include.forEach((relation) => {
  //           if (!relations.includes(relation)) {
  //               relations.push(relation);
  //           }
  //       });

  //       this.bag.set('with', relations);

  //       return this;
  //   }

  Builder<T> orderBy(String column,
      [SortDirection direction = SortDirection.asc]) {
    bag.set('order_by', '$column:${direction.name}');
    return this;
  }

  Builder<T> searchBy(String term) {
    bag.set('q', term);
    return this;
  }

  Builder<T> minified() {
    bag.set('minified', true);
    return this;
  }

  Builder<T> unset(String key) {
    bag.delete(key);
    return this;
  }

  Builder<T> include(Map<String, String> searchParams) {
    for (final key in searchParams.keys) {
      bag.set(key, searchParams[key]);
    }
    return this;
  }

  // TODO: Return paginated response
  Future<ModelPaginatedResponse<T>> _exec(
      [int page = 1, String? replaceLinksWith]) async {
    try {
      bag.set('page', page);

      final response = await route.call(
        generator: RouteGenerator(name: 'luminix.$schemaKey.index'),
        tap: (c) => c.withParams(bag.all()),
      );

      final models = (response.json()['data'] as List<dynamic>)
          .map((item) => modelBuilder(item))
          .toList();

      return ModelPaginatedResponse<T>.fromJson(models, response.json());
    } catch (error) {
      print(error);
      rethrow;
    }
  }

  Future<ModelPaginatedResponse<T>> get(
      [int page = 1, String? replaceLinksWith]) async {
    return _exec(page, replaceLinksWith);
  }

  Future<T?> first() async {
    final result = await limit(1)._exec(1);
    if (result.data.isEmpty) {
      return null;
    }
    return result.data.first;
  }

  Future<T?> find(dynamic id) async {
    final primaryKeyField = schema['primaryKey'];
    if (primaryKeyField == null) {
      throw Exception('Primary key not defined for schema $schemaKey');
    }

    final result =
        await where(key: primaryKeyField, value: id).limit(1)._exec(1);

    if (result.data.isEmpty) {
      return null;
    }

    return result.data.first;
  }

  Future<ModelPaginatedResponse<T>> all() async {
    final limit = config.get('luminix.backend.api.max_per_page', 150)!;
    final firstPage = await this.limit(limit)._exec(1);
    // TODO: Implement pagination to be returned from the `_exec` method

    throw UnimplementedError();
  }
}
