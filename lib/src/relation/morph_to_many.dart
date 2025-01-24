import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/relation/belongs_to_many.dart';

class MorphToMany extends BelongsToMany {
  MorphToMany({
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

    query.where(key: '${relation}_id', value: parent.getKey());
    query.where(key: '${relation}_type', value: parent.type);
    query.lock('where.${relation}_id');
    query.lock('where.${relation}_type');

    return query;
  }
}
