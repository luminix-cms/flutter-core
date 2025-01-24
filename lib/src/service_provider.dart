import 'application.dart';

abstract class ServiceProvider {
  final Application _application;
  ServiceProvider(this._application);

  Application get app => _application;

  void register() {}

  void boot() {}

  void flush() {}
}
