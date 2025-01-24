import 'package:luminix_flutter/luminix_flutter.dart';

class HasMany extends HasOneOrMany {
  HasMany({
    required super.meta,
    required super.modelBuilder,
    required super.parent,
    required super.route,
    super.items,
  });

  @override
  bool isSingle() {
    return false;
  }

  @override
  bool isMultiple() {
    return true;
  }

  Future<ModelPaginatedResponse<BaseModel>> get(
      [int page = 1, String? replaceLinksWith]) {
    return query().get(page, replaceLinksWith);
  }

  Future<ModelPaginatedResponse<BaseModel>> all() {
    return query().all();
  }

  Future<BaseModel?> first() {
    return query().first();
  }

  Future<BaseModel?> find(dynamic id) {
    return query().find(id);
  }

  Future<void> saveManyQuietly(List<BaseModel> models) async {
    if (!models.every((model) => model.type == modelBuilder().schemaName)) {
      throw Exception(
          'HasMany.saveManyQuietly() expects a ${modelBuilder().schemaName} instance');
    }

    Future.wait(models.map((model) {
      model.setAttribute(getForeignKey(), parent.getKey());
      return model.save();
    }));
  }

  Future<void> saveMany(List<BaseModel> models) async {
    await saveManyQuietly(models);

    // final newItems = await all();

    if (items is List) {
      (items as List).replaceRange(0, items.length, [...models]);
    } else {
      items = [...models];
    }
  }

  Future<void> save(BaseModel item) async {
    await saveQuietly(item);

    if (items == null) {
      items = [item];
    } else {
      items.push(item);
    }
  }
}
