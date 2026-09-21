import 'package:flutter/foundation.dart';

import '../utils/prefs_file.dart';
import 'models/a11y_record.dart';

typedef A11yStorageFactory = SavedMap Function(String name);

class A11yStore {
  A11yStore({A11yStorageFactory storage = SavedMap.new}) : _storage = storage;

  final A11yStorageFactory _storage;

  static const int schemaVersion = 1;

  static const String deviceKey = 'luminix_a11y_device';

  static String userKey(Object id) => 'luminix_a11y_user_$id';

  Future<A11yRecord?> loadDevice() => load(deviceKey);

  Future<A11yRecord?> loadUser(Object id) => load(userKey(id));

  Future<void> saveDevice(A11yRecord record) => save(deviceKey, record);

  Future<void> saveUser(Object id, A11yRecord record) =>
      save(userKey(id), record);

  Future<void> clearDevice() => clear(deviceKey);

  Future<void> clearUser(Object id) => clear(userKey(id));

  Future<A11yRecord?> load(String key) async {
    try {
      final stored = await _storage(key).load();
      if (stored == null) return null;

      final version = stored['version'];
      if (version is! int || version > schemaVersion) return null;

      return A11yRecord.fromJson(stored);
    } catch (error, stackTrace) {
      _report(error, stackTrace, 'ao ler os ajustes de acessibilidade em $key');
      return null;
    }
  }

  Future<void> save(String key, A11yRecord record) async {
    final stamped = record.copyWith(updatedAt: DateTime.now().toUtc());

    try {
      await _storage(key).save({'version': schemaVersion, ...stamped.toJson()});
    } catch (error, stackTrace) {
      _report(
        error,
        stackTrace,
        'ao gravar os ajustes de acessibilidade em $key',
      );
    }
  }

  Future<void> clear(String key) async {
    try {
      await _storage(key).clear();
    } catch (error, stackTrace) {
      _report(
        error,
        stackTrace,
        'ao apagar os ajustes de acessibilidade em $key',
      );
    }
  }

  void _report(Object error, StackTrace stackTrace, String context) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'luminix_flutter',
        context: ErrorDescription(context),
      ),
    );
  }
}
