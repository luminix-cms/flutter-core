import 'package:luminix_flutter/src/base_model.dart';

abstract class AuthDriver {
  Future<void> get ready => Future<void>.value();

  Future<void> attempt(
    Map<String, dynamic> credentials, [
    bool remember = false,
  ]);
  bool check();
  Future<void> logout();
  Future<String> refreshToken();
  BaseModel? user();
  dynamic id();
}
