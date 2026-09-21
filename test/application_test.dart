import 'package:flutter_test/flutter_test.dart';
import 'package:luminix_flutter/luminix_flutter.dart';

class _RecordingProvider extends ServiceProvider {
  _RecordingProvider(super.application, this.name, this.log);

  final String name;
  final List<String> log;

  @override
  void register() => log.add('register:$name');

  @override
  void boot() => log.add('boot:$name');

  @override
  void flush() => log.add('flush:$name');
}

class _AsyncBootProvider extends ServiceProvider {
  _AsyncBootProvider(super.application, this.log);

  final List<String> log;

  @override
  Future<void> boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    log.add('boot:async');
  }
}

class _ThrowingBootProvider extends ServiceProvider {
  _ThrowingBootProvider(super.application);

  @override
  Future<void> boot() async => throw StateError('boot falhou');
}

void main() {
  group('Application.create', () {
    test(
      'registra todos os providers antes de inicializar qualquer um',
      () async {
        final log = <String>[];
        final app = Application()
          ..withProviders([
            (a) => _RecordingProvider(a, 'um', log),
            (a) => _RecordingProvider(a, 'dois', log),
          ]);

        await app.create();

        expect(log, ['register:um', 'register:dois', 'boot:um', 'boot:dois']);
      },
    );

    test('aguarda o boot assíncrono antes de resolver', () async {
      final log = <String>[];
      final app = Application()
        ..withProviders([
          (a) => _AsyncBootProvider(a, log),
          (a) => _RecordingProvider(a, 'depois', log),
        ]);

      await app.create();

      expect(log, ['register:depois', 'boot:async', 'boot:depois']);
    });

    test('propaga a falha de um provider', () {
      final app = Application()
        ..withProviders([(a) => _ThrowingBootProvider(a)]);

      expect(app.create(), throwsStateError);
    });
  });

  group('Application.dispose', () {
    test('libera os providers na ordem inversa do boot', () async {
      final log = <String>[];
      final app = Application()
        ..withProviders([
          (a) => _RecordingProvider(a, 'um', log),
          (a) => _RecordingProvider(a, 'dois', log),
        ]);

      await app.create();
      log.clear();
      app.dispose();

      expect(log, ['flush:dois', 'flush:um']);
    });

    test('não libera duas vezes quando chamado repetidamente', () async {
      final log = <String>[];
      final app = Application()
        ..withProviders([(a) => _RecordingProvider(a, 'um', log)]);

      await app.create();
      app.dispose();
      log.clear();
      app.dispose();

      expect(log, isEmpty);
    });
  });
}
