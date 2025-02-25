import 'package:get_it/get_it.dart';
import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/extensions/string.dart';
import 'package:luminix_flutter/src/http/client.dart';
import 'package:luminix_flutter/src/http/response.dart';

GetIt getIt = GetIt.instance;

typedef BaseModelFactory = BaseModel Function([Map<String, dynamic>?]);

typedef RelationFactory = Relation Function({
  required Map<String, dynamic> meta,
  required BaseModel Function([Map<String, dynamic>?]) modelBuilder,
  required BaseModel parent,
  dynamic items,
});

class ModelSaveOptions {
  final Map<String, dynamic> additionalPayload;
  final bool sendsOnlyModifiedFields;

  const ModelSaveOptions({
    this.additionalPayload = const {},
    this.sendsOnlyModifiedFields = true,
  });
}

abstract class BaseModel {
  late PropertyBag _attributes;
  // Map<String, dynamic> _original = {};
  final Map<String, Relation> _relations = {};

  BaseModel([Map<String, dynamic>? attributes]) {
    _attributes = PropertyBag.fromMap(map: {});
    makeRelations();
    _makeAttributes(attributes ?? {});
  }

  final config = getIt.get<PropertyBag>();
  final route = getIt.get<RouteService>();

  String get type;
  String get schemaName;
  String get primaryKey;
  Map<String, dynamic> get schema;
  Map<String, String> get attributeTypes;
  void makeRelations();

  bool exists = false;
  bool wasRecentlyCreated = false;
  final List<String> _changedKeys = [];

  Map<String, dynamic> get attributes {
    return _attributes.all();
  }

  Map<String, Relation> get relations => _relations;

  List<String> get fillable {
    return schema['fillable'];
  }

  BelongsTo belongsTo({
    required String relation,
    required Map<String, dynamic> meta,
    required BaseModelFactory modelBuilder,
    required BaseModel parent,
    dynamic items,
  }) {
    if (relations[relation] == null) {
      relations[relation] = BelongsTo(
        meta: meta,
        modelBuilder: modelBuilder,
        parent: parent,
        route: route,
        items: items,
      );
    }
    return relations[relation] as BelongsTo;
  }

  BelongsToMany belongsToMany({
    required String relation,
    required Map<String, dynamic> meta,
    required BaseModelFactory modelBuilder,
    required BaseModel parent,
    dynamic items,
  }) {
    if (relations[relation] == null) {
      relations[relation] = BelongsToMany(
        meta: meta,
        modelBuilder: modelBuilder,
        parent: parent,
        route: route,
        items: items,
      );
    }
    return relations[relation] as BelongsToMany;
  }

  HasMany hasMany({
    required String relation,
    required Map<String, dynamic> meta,
    required BaseModelFactory modelBuilder,
    required BaseModel parent,
    dynamic items,
  }) {
    if (relations[relation] == null) {
      relations[relation] = HasMany(
        meta: meta,
        modelBuilder: modelBuilder,
        parent: parent,
        route: route,
        items: items,
      );
    }
    return relations[relation] as HasMany;
  }

  HasOneOrMany hasOneOrMany({
    required String relation,
    required Map<String, dynamic> meta,
    required BaseModelFactory modelBuilder,
    required BaseModel parent,
    dynamic items,
  }) {
    if (relations[relation] == null) {
      relations[relation] = HasOneOrMany(
        meta: meta,
        modelBuilder: modelBuilder,
        parent: parent,
        route: route,
        items: items,
      );
    }
    return relations[relation] as HasOneOrMany;
  }

  HasOne hasOne({
    required String relation,
    required Map<String, dynamic> meta,
    required BaseModelFactory modelBuilder,
    required BaseModel parent,
    dynamic items,
  }) {
    if (relations[relation] == null) {
      relations[relation] = HasOne(
        meta: meta,
        modelBuilder: modelBuilder,
        parent: parent,
        route: route,
        items: items,
      );
    }
    return relations[relation] as HasOne;
  }

  MorphMany morphMany({
    required String relation,
    required Map<String, dynamic> meta,
    required BaseModelFactory modelBuilder,
    required BaseModel parent,
    dynamic items,
  }) {
    if (relations[relation] == null) {
      relations[relation] = MorphMany(
        meta: meta,
        modelBuilder: modelBuilder,
        parent: parent,
        route: route,
        items: items,
      );
    }
    return relations[relation] as MorphMany;
  }

  MorphOneOrMany morphOneOrMany({
    required String relation,
    required Map<String, dynamic> meta,
    required BaseModelFactory modelBuilder,
    required BaseModel parent,
    dynamic items,
  }) {
    if (relations[relation] == null) {
      relations[relation] = MorphOneOrMany(
        meta: meta,
        modelBuilder: modelBuilder,
        parent: parent,
        route: route,
        items: items,
      );
    }
    return relations[relation] as MorphOneOrMany;
  }

  MorphOne morphOne({
    required String relation,
    required Map<String, dynamic> meta,
    required BaseModelFactory modelBuilder,
    required BaseModel parent,
    dynamic items,
  }) {
    if (relations[relation] == null) {
      relations[relation] = MorphOne(
        meta: meta,
        modelBuilder: modelBuilder,
        parent: parent,
        route: route,
        items: items,
      );
    }
    return relations[relation] as MorphOne;
  }

  MorphToMany morphToMany({
    required String relation,
    required Map<String, dynamic> meta,
    required BaseModelFactory modelBuilder,
    required BaseModel parent,
    dynamic items,
  }) {
    if (relations[relation] == null) {
      relations[relation] = MorphToMany(
        meta: meta,
        modelBuilder: modelBuilder,
        parent: parent,
        route: route,
        items: items,
      );
    }
    return relations[relation] as MorphToMany;
  }

  MorphTo morphTo({
    required String relation,
    required Map<String, dynamic> meta,
    required BaseModelFactory modelBuilder,
    required BaseModel parent,
    dynamic items,
  }) {
    if (relations[relation] == null) {
      relations[relation] = MorphTo(
        meta: meta,
        modelBuilder: modelBuilder,
        parent: parent,
        route: route,
        items: items,
      );
    }
    return relations[relation] as MorphTo;
  }

  Map<String, dynamic> _makePrimaryKeyReplacer() {
    return {
      primaryKey: getKey(),
    };
  }

  void _makeAttributes(Map<String, dynamic> attributes) {
    final relations = schema['relations'] as Map<String, dynamic>?;

    // remove relations from attributes
    relations?.keys ?? [];
    final excludedKeys = relations?.keys ?? [];
    final newAttributes = {...attributes}
      ..removeWhere(((key, value) => excludedKeys.contains(key)));

    // fill missing fillable attributes with null
    fillable
        .where((key) => !newAttributes.containsKey(key))
        .forEach((key) => newAttributes[key] = null);

    if (relations != null) {
      for (var key in relations.keys) {
        // TODO: check this later
        relation(key.camelCase())?.make(attributes[key]);
      }
    }

    // TODO: validate attributes

    _attributes.set('.', newAttributes);
    // _original = newAttributes;
    _changedKeys.clear();
  }

  Builder query();

  dynamic getKey() => getAttribute(primaryKey);

  Map<String, dynamic> diff() {
    return _changedKeys.fold<Map<String, dynamic>>({}, (acc, key) {
      acc[key] = _attributes.get(key);
      return acc;
    });
  }

  RouteGenerator getRouteForSave() {
    return exists
        ? RouteGenerator(
            name: 'luminix.$schemaName.update',
            replacer: _makePrimaryKeyReplacer())
        : RouteGenerator(name: 'luminix.$schemaName.store');
  }

  RouteGenerator getRouteForUpdate() {
    return RouteGenerator(
      name: 'luminix.$schemaName.update',
      replacer: _makePrimaryKeyReplacer(),
    );
  }

  RouteGenerator getRouteForDelete() {
    return RouteGenerator(
      name: 'luminix.$schemaName.destroy',
      replacer: _makePrimaryKeyReplacer(),
    );
  }

  RouteGenerator getRouteForRefresh() {
    return RouteGenerator(
      name: 'luminix.$schemaName.show',
      replacer: _makePrimaryKeyReplacer(),
    );
  }

  Relation? relation(String name) {
    if (name != name.camelCase()) {
      return null;
    }
    return relations[name.snakeCase()];
  }

  void refresh([Client Function(Client)? tap]) async {
    if (!exists) {
      throw Exception('Model not persisted');
    }
    final response = await route.call(
      generator: getRouteForRefresh(),
      tap: tap,
    );

    _makeAttributes(response.json());
  }

  Future<Response?> save([
    ModelSaveOptions options = const ModelSaveOptions(),
    Client Function(Client)? tap,
  ]) async {
    try {
      final existedBeforeSaving = exists;

      final attributes = options.sendsOnlyModifiedFields && existedBeforeSaving
          ? diff()
          : this.attributes;

      final data = Map.fromEntries(
          attributes.entries.where((entry) => fillable.contains(entry.key)));

      if (data.isEmpty) {
        return null;
      }

      final response = await route.call(
        generator: getRouteForSave(),
        tap: (client) {
          if (tap != null) {
            return tap(client.copyWith(data: data));
          }
          return client.copyWith(data: data);
        },
      );

      if (response.successful()) {
        _makeAttributes(response.json());
        exists = true;
        if (!existedBeforeSaving) {
          wasRecentlyCreated = true;
          print('dispatchCreateEvent: UPDATE MODEL $schemaName');
        } else {
          print('dispatchUpdateEvent: UPDATE MODEL $schemaName');
        }

        return response;
      }

      throw response;
    } catch (err) {
      print(err);
      rethrow;
    }
  }

  Future<Response> push() async {
    throw UnimplementedError();
  }

  Future<Response> delete() async {
    try {
      final response = await route.call(
        generator: getRouteForDelete(),
      );

      if (response.noContent()) {
        return response;
      }

      throw response;
    } catch (err) {
      print(err);
      rethrow;
    }
  }

  Future<void> update(Map<String, dynamic> data,
      [Client Function(Client)? tap]) async {
    try {
      final response = await route.call(
        generator: getRouteForUpdate(),
        tap: (client) {
          if (tap != null) {
            return tap(client.copyWith(data: data));
          }
          return client.copyWith(data: data);
        },
      );

      if (response.ok()) {
        _makeAttributes(response.json());
        return;
      }

      throw response;
    } catch (err) {
      print(err);
      rethrow;
    }
  }

  Future<Response> forceDelete() async {
    try {
      final response = await route.call(
        generator: getRouteForDelete(),
        tap: (client) => client.copyWith(params: {'force': true}),
      );

      if (response.noContent()) {
        return response;
      }

      throw response;
    } catch (err) {
      print(err);
      rethrow;
    }
  }

  Future<Response> restore() async {
    try {
      final response = await route.call(
        generator: getRouteForUpdate(),
        tap: (client) => client.copyWith(params: {'restore': true}),
      );

      if (response.ok()) {
        return response;
      }

      throw response;
    } catch (err) {
      print(err);
      rethrow;
    }
  }

  dynamic getAttribute(String key) {
    _attributes[key];

    if (attributeTypes[key] == 'bool') {
      print('bool: ${_attributes[key].runtimeType}');
      return false;
    }

    if (attributeTypes[key] != null) {
      return switch (attributeTypes[key]) {
        'DateTime' => _attributes[key] != null
            ? DateTime.parse(_attributes[key] as String)
            : null,
        'int' => _attributes[key],
        'bool' => _attributes[key] == true || _attributes[key] == 1,
        _ => _attributes[key],
      };
    }

    return _attributes[key];
  }

  void setAttribute(String key, dynamic value) {
    if (value != null) {
      if (attributeTypes[key] != null) {
        switch (attributeTypes[key]) {
          case 'DateTime':
            value = value.toString();
            break;
          default:
            value = value.toString();
        }
      }
    }

    _attributes.set(key, value);
  }
}
