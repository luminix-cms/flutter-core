import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/relation/belongs_to.dart';

class MorphTo extends BelongsTo {
  MorphTo({
    required super.meta,
    required super.modelBuilder,
    required super.parent,
    required super.route,
    super.items,
  });

  // TODO: Implement the following methods
  // getRelated(): typeof Model
  // {
  //     return this.services.model.make(
  //         this.parent.getAttribute(this.getName() + '_type') as string
  //     );
  // }

  @override
  Future<void> associate(BaseModel item) async {
    if (!item.exists) {
      await item.save();
    }

    return parent.update({
      '${getName()}_id': item.getKey(),
      '${getName()}_type': item.type,
    });
  }

  Future<void> dissociate() {
    return parent.update({
      '${getName()}_id': null,
      '${getName()}_type': null,
    });
  }
}
