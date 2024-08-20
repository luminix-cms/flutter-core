import 'package:luminix_flutter_core/src/utils.dart';
import 'types/json_encodable.dart';

class PropertyBag<T extends JsonEncodable> {
  Map<String, dynamic> _properties;

  final List<String> lockedKeys = [];

  PropertyBag._internal({
    required Map<String, dynamic> properties,
  }) : _properties = properties;

  factory PropertyBag({required T bag}) =>
      PropertyBag._internal(properties: bag.toJson());

  factory PropertyBag.fromMap({required Map<String, dynamic> map}) =>
      PropertyBag._internal(properties: map);

  ///
  /// get the value of the specified [field]
  ///
  Object? operator [](String field) => getMapFieldValue(_properties, field);

  V? get<V>(String field, [V? defaultValue]) {
    final value = getMapFieldValue(_properties, field);
    return value == null ? defaultValue : value as V;
  }

  void set(String field, dynamic value) {
    if (lockedKeys.any((item) => field.startsWith(item))) {
      throw Exception('Cannot set a locked path "$field"');
    }

    if (field == '.') {
      if (lockedKeys.isNotEmpty) {
        throw Exception('Cannot set the root path when there are locked paths');
      }

      if (value! is Map<String, dynamic> || value == null) {
        throw Exception('Value must be an object');
      }

      _properties = value;
      return;
    }

    setMapFieldValue(_properties, field, value);
  }

  merge(String path, Map<String, dynamic> value) {
    if (path == '.') {
      if (lockedKeys.any((item) => getMapFieldValue(value, item) != null)) {
        throw Exception(
            'Cannot merge a path "$path" that would override a locked path');
      }
      _properties = {
        ..._properties,
        ...value,
      };
      return;
    }
    final currentValue = get(path);

    if (currentValue is Map) {
      return this.set(path, {
        ...currentValue,
        ...value,
      });
    }

    if (currentValue == null) {
      return this.set(path, value);
    }

    throw Exception('Cannot merge a non-object path "$path"');
  }

  bool has(String field) => getMapFieldValue(_properties, field) != null;

  void delete(String field) {
    if (lockedKeys.any((item) => field.startsWith(item))) {
      throw Exception('Cannot delete a locked path "$field"');
    }

    final parts = getFieldParts(field);
    final last = parts.removeLast();
    final map = getPartsMapValue(_properties, parts);
    if (map != null) {
      map.remove(last);
    }
  }

  void lock(String field) {
    if (lockedKeys.contains(field)) {
      throw Exception('Path "$field" is already locked');
    }

    lockedKeys.add(field);
  }

  Map<String, dynamic> all() => _properties;

  bool isEmpty() => _properties.isEmpty;
}
