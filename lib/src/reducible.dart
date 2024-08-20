import 'package:luminix_flutter_core/src/types/reducer.dart';
import 'package:dartx/dartx.dart';

mixin Reducible {
  final reducers = <String, List<Reducer>>{};

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.isMethod) {
      final name = invocation.memberName.toString();
      final args = invocation.positionalArguments;

      if (args.isEmpty) {
        throw Exception('No arguments provided for $name');
      }

      if (!reducers.entries.any((entry) => entry.key == name)) {
        return args.first;
      }

      final macros = reducers[name]!;

      macros.sortedBy((it) => it.priority).fold(args.first,
          (acc, reducer) => reducer.callback(acc, args.skip(1).toList()));
    }

    super.noSuchMethod(invocation); // Will throw.
  }

  reducer({
    required String name,
    required ReducerCallback callback,
    int priority = 10,
  }) {
    // TODO: Check if the reducers name is not a method name

    if (reducers[name] == null) {
      reducers[name] = [];
    }

    reducers[name]!.add(
      Reducer(callback, priority),
    );

    return () => removeReducer(name, callback);
  }

  removeReducer(String name, ReducerCallback callback) {
    final index =
        reducers[name]?.indexWhere((reducer) => reducer.callback == callback);
    if (index == -1 || index == null) {
      return;
    }
    reducers[name]?.removeAt(index);
  }

  List<Reducer> getReducer(String name) {
    if (reducers[name] == null) {
      reducers[name] = [];
    }
    return reducers[name]!;
  }

  bool hasReducer(String name) {
    return reducers[name] != null && reducers[name]!.isNotEmpty;
  }

  clearReducer(String name) {
    reducers[name]?.clear();
  }

  flushReducers() {
    for (var collection in reducers.values) {
      collection.clear();
    }
  }
}
