import 'dart:io';
import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:luminix_flutter_core/src/generator.dart';

// Função principal que cria um parser de argumentos e executa a geração de classes
void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('input', abbr: 'i', help: 'Path para o arquivo boot.json')
    ..addOption('output',
        abbr: 'o',
        help:
            'Diretório de saída para as classes geradas. Default: lib/app/models',
        defaultsTo: 'lib/app/models')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Mostra essa ajuda');

  final argResults = parser.parse(arguments);

  if (argResults['help'] as bool) {
    print(parser.usage);
    exit(0);
  }

  final inputPath = argResults['input'];
  final outputDirectory = argResults['output'];

  if (inputPath == null) {
    print(
        'Uso: dart run arandu_flutter_modelmapper:generate_class -i <path_do_boot_json> [-o <path_do_diretorio_de_saida>]');
    print(parser.usage);
    exit(1);
  }

  final resolvedInputPath = p.absolute(inputPath);
  final resolvedOutputDirectory = p.absolute(outputDirectory);

  generateClassesFromJson(resolvedInputPath, resolvedOutputDirectory).then((_) {
    print('Classes geradas com sucesso no path: $resolvedOutputDirectory');
  }).catchError((error) {
    print('Ocorreu um erro ao gerar as classes. $error');
    exit(1);
  });
}
