import 'package:luminix_flutter_core/src/utils.dart';

class PropertyBag {
  Map<String, dynamic> _properties;

  final List<String> lockedKeys = [];

  PropertyBag({
    Map<String, dynamic>? initialProperties,
  }) : _properties = initialProperties ?? {};

  ///
  /// get the value of the specified [field]
  ///
  Object? operator [](String field) => getMapFieldValue(_properties, field);

  T? get<T>(String field, T? defaultValue) {
    final value = getMapFieldValue(_properties, field);
    return value == null ? defaultValue : value as T;
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
