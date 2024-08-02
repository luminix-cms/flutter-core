/// Backtick char code.
final backtickChrCode = '`'.codeUnitAt(0);

void setPartsMapValue(Map map, Iterable<String> parts, Object value) {
  final last = parts.length - 1;
  for (var i = 0; i < last; i++) {
    final part = parts.elementAt(i);
    if (map.containsKey(part)) {
      map = map[part] as Map;
    } else {
      final newMap = <String, dynamic>{};
      map[part] = newMap;
      map = newMap;
    }
  }
  map[parts.elementAt(last)] = value;
}

/// Get value at a given field path.
///
/// Handle index for iterables
T? getPartsMapValue<T>(Map map, Iterable<String> parts) {
  Object? value = map;
  for (final part in parts) {
    if (value is Map) {
      value = value[part];
    } else if (value is List) {
      var index = int.tryParse(part) ?? -1;
      if (index >= 0 && index < value.length) {
        value = value[index];
      }
    } else {
      return null;
    }
  }
  return value as T?;
}

bool isBacktickEnclosed(String field) {
  final length = field.length;
  if (length < 2) {
    return false;
  }
  return field.codeUnitAt(0) == backtickChrCode &&
      field.codeUnitAt(length - 1) == backtickChrCode;
}

String _unescapeKey(String field) => field.substring(1, field.length - 1);

/// For merged values and filters
List<String> getFieldParts(String field) {
  if (isBacktickEnclosed(field)) {
    return [_unescapeKey(field)];
  }
  return getRawFieldParts(field);
}

/// Get field segments.
List<String> getRawFieldParts(String field) => field.split('.');

/// Get field value.
T? getMapFieldValue<T>(Map map, String field) {
  return getPartsMapValue(map, getFieldParts(field));
}

/// Set field value.
///
void setMapFieldValue(Map map, String field, Object value) {
  setPartsMapValue(map, getFieldParts(field), value);
}
