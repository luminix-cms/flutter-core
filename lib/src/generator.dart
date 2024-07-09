import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

// Recebe o path do arquivo boot.json e retorna um Map com o conteúdo do arquivo
Future<Map<String, dynamic>> loadBootJson(String path) async {
  final file = File(path);
  final content = await file.readAsString();
  return jsonDecode(content) as Map<String, dynamic>;
}

// Converte uma string no formato snake_case para CamelCase
// Utiliza "_" como separador
String snakeToCamelCase(String snake) {
  return snake.split('_').map((word) {
    return word[0].toUpperCase() + word.substring(1);
  }).join('');
}

String generateClass(String className, Map<String, dynamic> model,
    Map<String, dynamic> allModels) {
  final StringBuffer buffer = StringBuffer();
  final fields = model['fillable'] as List<dynamic>? ?? [];
  final casts = model['casts'] as Map<String, dynamic>? ?? {};
  final relations = model['relations'] as Map<String, dynamic>? ?? {};

  // Gerar imports para classes relacionadas
  final imports = <String>{};
  relations.forEach((relationName, relationDetails) {
    final relatedModel = relationDetails['model'] as String?;
    final relatedClass = relatedModel != null
        ? snakeToCamelCase(
            allModels[relatedModel]['displayName']['singular'] as String)
        : null;
    if (relatedModel != null && relatedClass != null) {
      imports.add('import \'${relatedModel.replaceAll('_', '')}.dart\';');
    }
  });

  // Declaração da classe
  imports.forEach(buffer.writeln);
  buffer.writeln('');
  buffer.writeln('class $className {');

  // Campos da classe
  buffer.writeln('  int id;');
  fields.forEach((field) {
    final fieldType =
        casts.containsKey(field) ? casts[field] as String : 'String';
    buffer.writeln('  $fieldType $field;');
  });

  // Campos de relação
  relations.forEach((relationName, relationDetails) {
    final relatedModel = relationDetails['model'] as String?;
    final relatedClass = relatedModel != null
        ? snakeToCamelCase(
            allModels[relatedModel]['displayName']['singular'] as String)
        : null;
    final relationType = relationDetails['type'] as String?;

    if (relationType == 'HasMany' && relatedClass != null) {
      buffer.writeln('  List<$relatedClass> $relationName;');
    } else if (relationType == 'BelongsTo' && relatedClass != null) {
      buffer.writeln('  $relatedClass $relationName;');
    }
  });

  // Construtor
  buffer.writeln('\n  $className({');
  buffer.writeln('    required this.id,');
  fields.forEach((field) {
    buffer.writeln('    required this.$field,');
  });
  relations.forEach((relationName, relationDetails) {
    buffer.writeln('    required this.$relationName,');
  });
  buffer.writeln('  });\n');

  // Cria FromJson
  buffer.writeln('  factory $className.fromJson(Map<String, dynamic> json) {');
  buffer.writeln('    return $className(');
  buffer.writeln('      id: json[\'id\'] as int,');
  fields.forEach((field) {
    final fieldType =
        casts.containsKey(field) ? casts[field] as String : 'String';
    if (fieldType == 'int') {
      buffer.writeln('      $field: json[\'$field\'] as int,');
    } else {
      buffer.writeln('      $field: json[\'$field\'] as String,');
    }
  });
  relations.forEach((relationName, relationDetails) {
    final relatedModel = relationDetails['model'] as String?;
    final relatedClass = relatedModel != null
        ? snakeToCamelCase(
            allModels[relatedModel]['displayName']['singular'] as String)
        : null;
    final relationType = relationDetails['type'] as String?;

    if (relationType == 'HasMany' && relatedClass != null) {
      buffer.writeln(
          '      $relationName: (json[\'$relationName\'] as List).map((e) => $relatedClass.fromJson(e as Map<String, dynamic>)).toList(),');
    } else if (relationType == 'BelongsTo' && relatedClass != null) {
      buffer.writeln(
          '      $relationName: $relatedClass.fromJson(json[\'$relationName\'] as Map<String, dynamic>),');
    }
  });
  buffer.writeln('    );');
  buffer.writeln('  }\n');

  // cria ToJson
  buffer.writeln('  Map<String, dynamic> toJson() {');
  buffer.writeln('    return {');
  buffer.writeln('      \'id\': id,');
  fields.forEach((field) {
    buffer.writeln('      \'$field\': $field,');
  });
  relations.forEach((relationName, relationDetails) {
    final relationType = relationDetails['type'] as String?;

    if (relationType == 'HasMany') {
      buffer.writeln(
          '      \'$relationName\': $relationName.map((e) => e.toJson()).toList(),');
    } else if (relationType == 'BelongsTo') {
      buffer.writeln('      \'$relationName\': $relationName.toJson(),');
    }
  });
  buffer.writeln('    };');
  buffer.writeln('  }\n');

  buffer.writeln('}');
  return buffer.toString();
}

// chama snakeToCamelCase e cria um arquivo com o nome da classe
Future<void> writeClassToFile(
    String directory, String className, String classContent) async {
  final fileName = snakeToCamelCase(className).replaceAll(' ', '') + '.dart';
  final file = File(p.join(directory, fileName));
  await file.writeAsString(classContent);
}

// Recebe os paths e chama chama a função de load do boot.json
// Itera sobre os models e chama a função de geração de classes
Future<void> generateClassesFromJson(
    String inputPath, String outputDirectory) async {
  final bootData = await loadBootJson(inputPath);
  final models = bootData['models'] as Map<String, dynamic>;

  for (var modelName in models.keys) {
    final className = snakeToCamelCase(
        models[modelName]?['displayName']?['singular'] as String);
    if (className != null) {
      final classContent = generateClass(
          className, models[modelName] as Map<String, dynamic>, models);
      await writeClassToFile(outputDirectory, className, classContent);
    }
  }
}
