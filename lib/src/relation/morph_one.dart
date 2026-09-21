import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/relation/morph_one_or_many.dart';

class MorphOne extends MorphOneOrMany {
  MorphOne({
    required super.meta,
    required super.modelBuilder,
    required super.parent,
    required super.route,
    super.items,
  });

  @override
  bool isSingle() {
    return true;
  }

  @override
  bool isMultiple() {
    return false;
  }

  get() {
    return query().first();
  }

  Future<void> save(BaseModel item) async {
    await saveQuietly(item);

    items = item;
  }
}
