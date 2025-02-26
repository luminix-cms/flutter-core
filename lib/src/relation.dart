import 'package:luminix_flutter/luminix_flutter.dart';

class Relation<T extends BaseModel> {
  final Map<String, dynamic> meta;
  final T Function([Map<String, dynamic>?]) modelBuilder;
  final BaseModel parent;
  final RouteService route;
  dynamic items;

  Relation({
    required this.meta,
    required this.modelBuilder,
    required this.parent,
    required this.route,
    this.items,
  });

  void make([dynamic data]) {
    if (data == null) {
      this.set(null);
      return;
    }

    if (this.isSingle()) {
      if (data is! Map<String, dynamic>) {
        throw Exception('Relation.make() expects an object');
      }
      this.set(modelBuilder(data));
    }

    if (this.isMultiple()) {
      if (data is! List) {
        throw Exception('Relation.make() expects an array');
      }
      this.set(
        data.map((item) => modelBuilder(item as Map<String, dynamic>)).toList(),
      );
    }
  }

  String guessInverseRelation() {
    final relations = modelBuilder().schema['relations'];

    final currentRelationType = this.getType();

    final inverses = {
      'HasOne': ['BelongsTo'],
      'HasMany': ['BelongsTo'],
      'BelongsTo': ['HasOne', 'HasMany'],
      'BelongsToMany': ['BelongsToMany'],
      'MorphTo': ['MorphMany', 'MorphOne'],
      'MorphOne': ['MorphTo'],
      'MorphMany': ['MorphTo'],
      'MorphToMany': ['MorphToMany'],
    };

    if (inverses[currentRelationType] == null) {
      throw Exception('Invalid relation type: $currentRelationType');
    }

    for (final relationName in relations.keys) {
      final relation = relations[relationName];

      if ((relation['model'] == this.parent.type ||
              ['MorphOne', 'MorphMany'].contains(currentRelationType)) &&
          inverses[currentRelationType]!.contains(relation['type'])) {
        return relationName;
      }
    }

    throw Exception(
        'Could not find inverse relation for ${this.parent.type}.$currentRelationType');
  }

  void set(dynamic items) {
    if (items != null && items! is BaseModel && items! is List<BaseModel>) {
      throw Exception('Items must be either a BaseModel or a List<BaseModel>');
    }

    this.items = items;
  }

  String getForeignKey() => this.meta['foreignKey'];

  String getName() => this.meta['name'];

  String getType() => this.meta['type'];

  String getModel() => this.meta['model'];

  bool isLoaded() => this.items != null;

  dynamic getLoadedItems() => this.items;

  bool isSingle() => items is BaseModel;

  bool isMultiple() => items is List;

  BaseModel getParent() => parent;

  // TODO: Implement event listeners to update items on success
  Builder query() {
    return modelBuilder().query();
  }

  Builder where(
      {required String key, required dynamic value, Filter? filterOperator}) {
    return query()
        .where(key: key, value: value, filterOperator: filterOperator);
  }

  Builder whereNull(String key) {
    return query().whereNull(key);
  }

  Builder whereNotNull(String key) {
    return query().whereNotNull(key);
  }

  Builder whereBetween<R>(String key, (R, R) value) {
    return query().whereBetween(key, value);
  }

  Builder whereNotBetween<R>(String key, (R, R) value) {
    return query().whereNotBetween(key, value);
  }

  Builder orderBy(String column, [SortDirection? direction]) {
    return query().orderBy(column, direction ?? SortDirection.asc);
  }

  Builder searchBy(String term) {
    return query().searchBy(term);
  }

  Builder minified() {
    return this.query().minified();
  }

  Builder limit(int value) {
    return query().limit(value);
  }
}
