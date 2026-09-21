import 'package:luminix_flutter/luminix_flutter.dart';

class HasOne extends HasOneOrMany {
  HasOne({
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

  Future<BaseModel?> get() {
    return query().first();
  }

  Future<void> save(BaseModel item) async {
    await saveQuietly(item);

    items = item;
  }
}
