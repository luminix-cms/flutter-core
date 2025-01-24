import 'package:luminix_flutter/luminix_flutter.dart';

class BelongsTo extends Relation {
  BelongsTo({
    required super.meta,
    required super.modelBuilder,
    required super.parent,
    required super.route,
    super.items,
  });

  @override
  bool isSingle() => true;

  @override
  bool isMultiple() => false;

  @override
  Builder query() {
    final query = super.query();

    final relation = guessInverseRelation();

    query.where(key: relation, value: parent.getKey());
    query.lock('where.$relation');

    return query;
  }

  // TODO: TYPE THIS
  Future<BaseModel?> get() {
    return query().first();
  }

  void associate(BaseModel item) async {
    if (item.type != modelBuilder().schemaName) {
      throw Exception(
          'BelongsTo.associate() expects a ${modelBuilder().schemaName} instance');
    }

    if (!item.exists) {
      throw Exception('BelongsTo.associate() expects a persisted instance');
    }

    return parent.update({
      getForeignKey(): item.getKey(),
    });
  }
}
