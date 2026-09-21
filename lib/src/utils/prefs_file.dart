import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Serializes a [Map] using json encoding. Requires a fileName.
class SavedMap {
  SavedMap(this.name);
  final String name;
  Future<Map<String, dynamic>?> load() async {
    final p = (await SharedPreferences.getInstance()).getString(name);
    return p != null ? Map<String, dynamic>.from(jsonDecode(p)) : null;
  }

  Future<void> save(Map<String, dynamic> data) async {
    (await SharedPreferences.getInstance()).setString(name, jsonEncode(data));
  }

  Future<void> clear() async {
    (await SharedPreferences.getInstance()).remove(name);
  }
}
