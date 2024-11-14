# Luminix Flutter Core

luminix_flutter é um pacote Dart que permite gerar automaticamente classes Dart a partir de um arquivo JSON de configuração (`boot.json`). Este arquivo JSON é gerado por APIs Laravel e contém todas as models do projeto. O pacote gera classes Dart com métodos `fromJson` e `toJson` para facilitar a serialização e desserialização de dados.

## Instalação

Adicione o pacote como uma dependência local no seu projeto Flutter. No arquivo `pubspec.yaml` do seu projeto, adicione:

```yaml
dependencies:
  flutter:
    sdk: flutter
  luminix_flutter:
    path: ../luminix_flutter
```

Depois, execute o comando:

```sh
flutter pub get
```

## Uso

### Gerar Classes a partir do JSON

Para gerar classes a partir do arquivo `boot.json`, execute o seguinte comando:

```sh
dart run luminix_flutter:generate_class -i <caminho_para_o_boot.json>
```

Por exemplo:

```sh
dart run luminix_flutter:generate_class -i ../boot.json
```

### Opções Disponíveis

O comando `generate_class` possui as seguintes opções:

- `-i, --input`: Caminho para o arquivo `boot.json` (obrigatório).
- `-o, --output`: Diretório de saída para as classes geradas. O padrão é `lib/app/models`.

Para visualizar a ajuda do comando:

```sh
dart run luminix_flutter:generate_class --help
```

ou

```sh
dart run luminix_flutter:generate_class -h
```

### Exemplo de Uso

Se você deseja especificar um diretório de saída diferente, use a opção `-o`:

```sh
dart run luminix_flutter:generate_class -i ../boot.json -o lib/models
```

## Estrutura do Projeto

O projeto `luminix_flutter` possui a seguinte estrutura:

```
luminix_flutter
├── bin
│   └── flutter_json_generator.dart
├── lib
│   ├── luminix_flutter.dart
│   └── src
│       └── generator.dart
├── CHANGELOG.md
├── README.md
├── analysis_options.yaml
├── pubspec.yaml
└── ...
```

### Arquivo `bin/luminix_flutter.dart`

Este arquivo contém a lógica principal para o comando CLI que processa os argumentos e executa a geração de classes.

### Arquivo `lib/src/generator.dart`

Este arquivo contém as funções responsáveis por carregar o JSON, converter nomes para CamelCase, gerar o conteúdo das classes e escrever essas classes em arquivos Dart.