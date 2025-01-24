import 'package:luminix_flutter/luminix_flutter.dart';

class HasOneOrMany extends Relation {
  HasOneOrMany({
    required super.meta,
    required super.modelBuilder,
    required super.parent,
    required super.route,
    super.items,
  });

  @override
  Builder query() {
    final query = super.query();

    final relation = guessInverseRelation();

    query.where(key: relation, value: parent.getKey());
    query.lock('where.$relation');

    return query;
  }

  Future<void> saveQuietly(BaseModel item) async {
    if (item.type != modelBuilder().schemaName) {
      throw Exception(
          'HasOneOrMany.saveQuietly() expects a ${modelBuilder().schemaName} instance');
    }

    item.setAttribute(getForeignKey(), parent.getKey());

    await item.save();
  }
}
