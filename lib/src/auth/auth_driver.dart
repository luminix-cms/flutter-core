import 'package:luminix_flutter/src/base_model.dart';

abstract class AuthDriver {
  Future<void> attempt(Map<String, dynamic> credentials,
      [bool remember = false]);
  bool check();
  Future<void> logout();
  BaseModel? user();
  dynamic id();
}
