import 'package:collection/collection.dart';
import 'package:dartx/dartx.dart';
import 'package:dio/dio.dart';

import 'model.dart';
import 'route.dart';
import 'builder.dart';
import 'property_bag.dart';
import 'types/route_generator.dart';

typedef ModelSaveOptions = (Map<String, dynamic>, bool);
typedef JsonObject = Map<String, dynamic>;

class BaseModel {
  final String schemaKey;
  final ModelFacade model;
  final RouteFacade route;

  final PropertyBag _attributes;
  final _changedKeys = <String>[];
  var _original = <String, dynamic>{};

  bool exists = false;
  bool wasRecentlyCreated = false;

  BaseModel({
    required this.model,
    required this.route,
    required this.schemaKey,
    Map<String, dynamic> attributes = const {},
  }) : _attributes = PropertyBag.fromMap(map: {}) {
    _makeAttributes(attributes);
  }

  _cast(dynamic value, String cast) {
    if (value == null || cast.isEmpty) return value;

    switch (cast) {
      case 'boolean' || 'bool' when value is String:
        return bool.parse(value);
      case 'date' || 'datetime' || 'immutable_date' || 'immutable_datetime'
          when value is String:
        return DateTime.parse(value);
      case 'float' || 'double' when value is String:
        return double.parse(value);
      case 'integer' || 'int' when value is String:
        return int.parse(value);
      default:
        return value;
    }
  }

  _mutate(dynamic value, String mutator) {
    if (value == null || mutator.isEmpty) {
      return value;
    }

    switch (mutator) {
      case 'boolean' || 'bool':
        return value is bool ? value : value == 'true';
      case 'date' || 'datetime' || 'immutable_date' || 'immutable_datetime':
        return value is DateTime ? value.toIso8601String() : value;
      case 'float' || 'double':
        return value is double ? value : double.parse(value);
      case 'integer' || 'int':
        return value is int ? value : int.parse(value);
      default:
        return value;
    }
  }

  _makeAttributes(Map<String, dynamic> attributes) {
    final {'relations': relations as Map<String, dynamic>} =
        model.schemaAttributes(schemaKey);

    // remove relations from attributes
    final excludedKeys = relations.keys.toList();
    final newAttributes =
        attributes.filter((entry) => excludedKeys.contains(entry.key));

    // fill missing fillable attributes with null
    fillable.where((key) => !newAttributes.containsKey(key)).forEach((key) {
      newAttributes[key] = null;
    });

    if (!_validateJsonObject(newAttributes)) {
      print('Invalid attributes for model "$schemaKey" after mutation.');
    }

    _attributes.set('.', newAttributes);
    _original = newAttributes;
    _changedKeys.clear();
  }

  Map<String, dynamic> _makePrimaryKeyReplacer() => {
        getKeyName(): getKey(),
      };

  void _updateChangedKeys(String key) {
    bool determineValueEquality(dynamic a, dynamic b) {
      if (a is Map) {
        return DeepCollectionEquality().equals(a, b);
      }

      return a == b;
    }

    // Accessing values using cascade operator and null-aware operators for safety
    var originalValue = _original[key];
    var currentValue = _attributes.get(key);

    if (!_changedKeys.contains(key) &&
        !determineValueEquality(originalValue, currentValue)) {
      _changedKeys.add(key);
    } else if (_changedKeys.contains(key) &&
        determineValueEquality(originalValue, currentValue)) {
      _changedKeys.remove(key);
    }
  }

  bool _validateJsonObject(Map<String, dynamic> json) {
    return json.entries.every((entry) {
      final value = entry.value;
      return ['bool', 'int', 'double', 'String']
              .contains(value.runtimeType.toString()) ||
          value == null ||
          _validateJsonObject(value) ||
          (value is List && value.every((item) => _validateJsonObject(item)));
    });
  }

  Map<String, dynamic> get attributes => _attributes.all();

  Map<String, dynamic> get original => _original;

  List<String> get fillable {
    return model.schemaAttributes(schemaKey)['fillable'];
  }

  get primaryKey {
    return model.schemaAttributes(schemaKey)['primaryKey'];
  }

  bool get timestamps {
    return model.schemaAttributes(schemaKey)['timestamps'];
  }

  Map<String, dynamic> get casts => {
        ...model.schemaAttributes(schemaKey)['casts'],
        ...timestamps
            ? {'created_at': 'datetime', 'updated_at': 'datetime'}
            : {},
        // ...this.softDeletes ? { deleted_at: 'datetime' } : {},
      };

  bool get isDirty => _changedKeys.isNotEmpty;

  dynamic getAttribute(String key) {
    var value = _attributes.get(key, null);
    if (casts.containsKey(key)) {}
    value = _cast(value, casts[key]);
    // final reducer = 'model${schemaKey.capitalize().camelCase()}Get${key.capitalize().camelCase()}Attribute';
    // :TODO call !Reducer `model${ClassName}Get${Key}Attribute`
    return value;
  }

  void setAttribute(String key, dynamic value) {
    // final reducer = 'model${schemaKey.capitalize().camelCase()}Set${key.capitalize().camelCase()}Attribute';
    // :TODO !Reducer `model${ClassName}Set${Key}Attribute`
    final mutated = _mutate(value, casts[key]);

    if (!_validateJsonObject({key: mutated})) {
      print('Invalid attributes for model "$schemaKey" after mutation.');
      return;
    }

    _attributes.set(key, mutated);

    _updateChangedKeys(key);
  }

  dynamic getKey() {
    return getAttribute(primaryKey);
  }

  String getKeyName() => primaryKey;

  void fill(Map<String, dynamic> attributes) {
    final validAttributes =
        attributes.filterKeys((key) => fillable.contains(key));

    final mutatedAttributes = Map.fromEntries(
      validAttributes.entries.map((entry) {
        final key = entry.key;
        final value = entry.value;

        // Assuming 'mutate' and 'casts' are available in the current Dart context
        final mutatedValue = _mutate(value, casts[key]);

        return MapEntry(key, mutatedValue);
      }),
    );

    if (!_validateJsonObject(mutatedAttributes)) {
      print('Invalid attributes for model "$schemaKey" after mutation.');
      return;
    }

    _attributes.merge('.', mutatedAttributes);
  }

  Map<String, dynamic> toJson() {
    // !Reducer `model${ClassName}Json`
    return {
      ...attributes,
    };
  }

  Map<String, dynamic> diff() {
    return _changedKeys.fold<Map<String, dynamic>>({}, (acc, key) {
      acc[key] = _attributes[key];
      return acc;
    });
  }

  String getType() {
    return schemaKey;
  }

  RouteGenerator getRouteForSave() {
    return exists
        ? RouteGenerator(
            name: 'luminix.$schemaKey.update',
            replacer: _makePrimaryKeyReplacer(),
          )
        : RouteGenerator(name: 'luminix.$schemaKey.store');
  }

  RouteGenerator getRouteForUpdate() {
    return RouteGenerator(
      name: 'luminix.$schemaKey.update',
      replacer: _makePrimaryKeyReplacer(),
    );
  }

  RouteGenerator getRouteForDelete() => RouteGenerator(
        name: 'luminix.$schemaKey.destroy',
        replacer: _makePrimaryKeyReplacer(),
      );

  RouteGenerator getRouteForRestore() => RouteGenerator(
        name: 'luminix.$schemaKey.restore',
        replacer: _makePrimaryKeyReplacer(),
      );

  RouteGenerator getRouteForForceDelete() => RouteGenerator(
        name: 'luminix.$schemaKey.forceDelete',
        replacer: _makePrimaryKeyReplacer(),
      );

  RouteGenerator getRouteForRefresh() => RouteGenerator(
        name: 'luminix.$schemaKey.show',
        replacer: _makePrimaryKeyReplacer(),
      );

  String getLabel() {
    final {'labeledBy': key} = model.schemaAttributes(schemaKey);

    return getAttribute(key);
  }

  Future<void> refresh() async {
    if (!exists) {
      throw Exception('Model not persisted');
    }
    final response = await route.call(
        generator: getRouteForRefresh(), config: RouteCallConfig());

    _makeAttributes(response.data);
  }

  Future<Response?> save([ModelSaveOptions options = (const {}, true)]) async {
    try {
      final (
        additionalPayload,
        sendsOnlyModifiedFields,
      ) = options;

      final existedBeforeSaving = exists;

      final data = {
        ...(sendsOnlyModifiedFields && existedBeforeSaving
                ? diff()
                : attributes)
            .filterKeys((key) => fillable.contains(key)),
        ...additionalPayload,
      };

      if (data.isEmpty) {
        return Future.value();
      }

      final response = await route.call(
        generator: getRouteForSave(),
        config: RouteCallConfig(
          data: data,
        ),
      );

      if ([200, 201].contains(response.statusCode)) {
        _makeAttributes(response.data);
        exists = true;
        if (!existedBeforeSaving) {
          wasRecentlyCreated = true;
        }

        return response;
      }

      throw response;
    } catch (error) {
      rethrow;
    }
  }

  Future<Response> push() async {
    throw Exception('Method not implemented');
  }

  Future<Response> delete() async {
    try {
      final response = await route.call(
        generator: getRouteForDelete(),
        config: RouteCallConfig(),
      );

      if (response.statusCode == 204) {
        return response;
      }

      throw response;
    } catch (error) {
      rethrow;
    }
  }

  Future<void> update(JsonObject data) async {
    try {
      final response = await route.call(
        generator: getRouteForUpdate(),
        config: RouteCallConfig(data: data),
      );

      if (response.statusCode == 200) {
        _makeAttributes(response.data);
        return;
      }

      throw response;
    } catch (error) {
      rethrow;
    }
  }

  Future<Response> forceDelete() async {
    try {
      final response = await route.call(
        generator: getRouteForForceDelete(),
        // TODO: { params: { force: true } }
        config: RouteCallConfig(),
      );

      if (response.statusCode == 204) {
        return response;
      }

      throw response;
    } catch (error) {
      rethrow;
    }
  }

  Future<Response> restore() async {
    try {
      final response = await route.call(
        generator: getRouteForRestore(),
        // TODO: { params: { restore: true } }
        config: RouteCallConfig(),
      );

      if (response.statusCode == 200) {
        return response;
      }

      throw response;
    } catch (error) {
      rethrow;
    }
  }

  // static String getSchemaName() {
  //   return schemaKey;
  // }

  // static Map<String, dynamic> getSchema() {
  //   return model.schema(schemaKey);
  // }

  // Builder query() {
  //   return Builder(schemaKey: schemaKey, route: route);
  // }

  // Builder where(
  //     {required String key, required dynamic value, Filter? filterOperator}) {
  //   return query().where(
  //     key: key,
  //     value: value,
  //     filterOperator: filterOperator,
  //   );
  // }

  // Builder whereNull(String key) {
  //   return query().whereNull(key);
  // }

  // whereNotNull(String key) {
  //   return query().whereNotNull(key);
  // }

  // Builder whereBetween<T>(String key, (T, T) value) {
  //   return query().whereBetween(key, value);
  // }

  // Builder whereNotBetween<T>(String key, (T, T) value) {
  //   return query().whereNotBetween(key, value);
  // }

  // Builder orderBy(String key, [SortDirection direction = SortDirection.asc]) {
  //   return query().orderBy(key, direction);
  // }

  // Builder searchBy(String term) {
  //   return query().searchBy(term);
  // }

  // Builder minified() {
  //   return query().minified();
  // }

  // Builder limit(int value) {
  //   return query().limit(value);
  // }

  // Future get([int page = 1, String? replaceLinksWith]) {
  //   return query().get(page, replaceLinksWith);
  // }

  // Future find(dynamic id) {
  //   return query().find(id);
  // }

  // Future first() {
  //   return query().first();
  // }

  // static create(JsonObject attributes) async {
  //   final model = BaseModel(
  //     model: this.model,
  //     route: route,
  //     schemaKey: schemaKey,
  //   );

  //   model.fill(attributes);

  //   await model.save();

  //   return model;
  // }

  // static update(dynamic id, JsonObject attributes) async {
  //   final model = BaseModel(
  //     model: this.model,
  //     route: route,
  //     schemaKey: schemaKey,
  //     attributes: {'id': id},
  //   );

  //   model.fill(attributes);
  //   model.exists = true;

  //   await model.save();

  //   return model;
  // }

  // static delete(dynamic id) {
  //   if (id is List) {
  //     return route.call(
  //       generator: RouteGenerator(name: 'luminix.$schemaKey.destroyMany'),
  //       // TODO: { params: { ids: id } }
  //       config: RouteCallConfig(),
  //     );
  //   }

  //   final model = BaseModel(
  //     model: this.model,
  //     route: route,
  //     schemaKey: schemaKey,
  //     attributes: {'id': id},
  //   );

  //   return model.delete();
  // }

  // static restore(dynamic id) {
  //   if (id is List) {
  //     return route.call(
  //       generator: RouteGenerator(name: 'luminix.$schemaKey.restoreMany'),
  //       config: RouteCallConfig(data: {'ids': id}),
  //     );
  //   }

  //   final model = BaseModel(
  //     model: this.model,
  //     route: route,
  //     schemaKey: schemaKey,
  //     attributes: {'id': id},
  //   );

  //   return model.restore();
  // }

  // static forceDelete(dynamic id) {
  //   if (id is List) {
  //     return route.call(
  //       generator: RouteGenerator(name: 'luminix.$schemaKey.destroyMany'),
  //       // TODO: { params: { ids: id, force: true } }
  //       config: RouteCallConfig(),
  //     );
  //   }

  //   final model = BaseModel(
  //     model: model,
  //     route: route,
  //     schemaKey: schemaKey,
  //     attributes: {'id': id},
  //   );

  //   return model.forceDelete();
  // }

  // static singular() {
  //   return model.schema(schemaKey)['displayName']['singular'];
  // }

  // static plural() {
  //   return model.schema(schemaKey)['displayName']['plural'];
  // }
}
