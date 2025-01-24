import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/relation/has_one_or_many.dart';

class MorphOneOrMany extends HasOneOrMany {
  MorphOneOrMany({
    required super.meta,
    required super.modelBuilder,
    required super.parent,
    required super.route,
    super.items,
  });

  @override
  Builder query() {
    final related = modelBuilder();
    final query = related.query();

    // TODO: implement event listener
    // query.once('success', (e) => {
    //     items = e.items;
    // });

    final relation = guessInverseRelation();

    query.where(key: '${relation}_id', value: parent.getKey());
    query.where(key: '${relation}_type', value: related.schemaName);
    query.lock('where.${relation}_id');
    query.lock('where.${relation}_type');

    return query;
  }

  @override
  Future<void> saveQuietly(BaseModel item) async {
    final related = modelBuilder();

    if (item.type != related.schemaName) {
      throw Exception(
          'MorphOneOrMany.saveQuietly() expects a ${related.schemaName} instance');
    }

    final relation = guessInverseRelation();

    item.setAttribute('${relation}_id', parent.getKey());
    item.setAttribute('${relation}_type', parent.type);

    await item.save();
  }
}
