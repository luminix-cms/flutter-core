import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/http/response.dart';

class BelongsToMany extends Relation {
  BelongsToMany({
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

  @override
  Builder query() {
    final query = super.query();

    final relation = guessInverseRelation();

    query.where(key: relation, value: parent.getKey());
    query.lock('where.$relation');

    return query;
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

  Future<Response> attachQuietly(dynamic id,
      [Map<String, dynamic> pivot = const {}]) {
    return route.call(
      generator: RouteGenerator(
        name: 'luminix.${parent.type}.${getName()}:attach',
        replacer: {
          parent.primaryKey: parent.getKey(),
          'itemId': id,
        },
      ),
    );
    // TODO: Implement withData
    // (client) => client.withData(pivot));
  }

  Future<void> attach(
    dynamic id, [
    Map<String, dynamic> pivot = const {},
  ]) async {
    await attachQuietly(id, pivot);

    if (items is List) {
      final currentIndex =
          (items as List<BaseModel>).indexWhere((item) => item.getKey() == id);
      final freshItem = await modelBuilder().query().find(id);

      if (freshItem == null) {
        return;
      }

      if (-1 != currentIndex) {
        items.put(currentIndex, freshItem);
      } else {
        items.push(freshItem);
      }
    } else {
      items = await all();
    }
  }

  Future<void> detachQuietly(dynamic id) async {
    await route.call(
      generator: RouteGenerator(
        name: 'luminix.${parent.type}.${getName()}:detach',
        replacer: {
          parent.primaryKey: parent.getKey(),
          'itemId': id,
        },
      ),
    );
  }

  Future<void> detach(dynamic id) async {
    await detachQuietly(id);

    if (items is List<BaseModel>) {
      final currentIndex =
          (items as List<BaseModel>).indexWhere((item) => item.getKey() == id);
      if (-1 != currentIndex) {
        items.pull(currentIndex);
      }
    }
  }

  Future<void> syncQuietly(dynamic ids) async {
    await route.call(
      generator: RouteGenerator(
        name: 'luminix.${parent.type}.${getName()}:sync',
        replacer: {
          parent.primaryKey: parent.getKey(),
        },
      ),
    );
    // TODO: Implement withData
    // (client) => client.withData(ids));
  }

  Future<void> syncWithPivotValuesQuietly(
      dynamic ids, Map<String, dynamic> pivot) async {
    await route.call(
        generator: RouteGenerator(
            name: 'luminix.${parent.type}.${getName()}:sync',
            replacer: {
          parent.primaryKey: parent.getKey(),
        }));
    // TODO: Implement withData
    // (client) => client.withData(ids.map((id) => ({
    //     [this.getRelated().getSchema().primaryKey]: id,
    //     ...pivot,
    // }))));
  }

  Future<void> sync(List<dynamic> ids) async {
    await syncQuietly(ids);

    final newItems = await all();

    if (items is List) {
      (items as List).replaceRange(0, items.length, newItems.data);
    } else {
      items = newItems;
    }
  }

  Future<void> syncWithPivotValues(
      List<dynamic> ids, Map<String, dynamic> pivot) async {
    await syncWithPivotValuesQuietly(ids, pivot);

    final newItems = await all();

    if (items is List) {
      (items as List).replaceRange(0, items.length, [...newItems.data]);
    } else {
      items = newItems;
    }
  }
}
