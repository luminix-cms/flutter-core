import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/relation/morph_one_or_many.dart';

class MorphMany extends MorphOneOrMany {
  MorphMany({
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
    final related = modelBuilder();
    if (!models.every((model) => model.type == related.schemaName)) {
      throw Exception(
          'MorphMany.saveManyQuietly() expects a ${related.schemaName} instance');
    }

    await Future.wait(models.map((model) {
      model.setAttribute('${getName()}_id', parent.getKey());
      model.setAttribute('${getName()}_type', parent.type);
      return model.save();
    }));
  }

  Future<void> save(BaseModel item) async {
    await saveQuietly(item);

    if (items) {
      items.push(item);
    } else {
      items = await all();
    }
  }

  Future<void> saveMany(List<BaseModel> models) async {
    await saveManyQuietly(models);

    final newItems = await all();

    if (items is List) {
      (items as List).replaceRange(0, items.lenth, [...newItems.data]);
    } else {
      items = newItems;
    }
  }
}
