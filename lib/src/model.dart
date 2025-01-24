import 'package:luminix_flutter/luminix_flutter.dart';
import 'package:luminix_flutter/src/reducible.dart';

class ModelFacade with Reducible {
  final Map<String, dynamic> _schema;
  final Map<String, BaseModel> _models = {};

  ModelFacade(Map<String, dynamic> schema) : _schema = schema;

  boot(Application app) {
    // for (var modelName in _schema.keys) {
    //   _models[modelName] = ModelFactory(app.make(), modelName, SpecificModel);
    // }
  }

  Map<String, dynamic> schema() => _schema;

  Map<String, dynamic> schemaAttributes(String schemaKey) {
    if (_schema[schemaKey] == null) {
      throw Exception('Model $schemaKey not found');
    }

    return _schema[schemaKey];
  }

  Map<String, BaseModel> make() => _models;

  BaseModel makeModel(String schemaKey) {
    if (_models[schemaKey] == null) {
      throw Exception('Model $schemaKey not found');
    }

    return _models[schemaKey]!;
  }
}
