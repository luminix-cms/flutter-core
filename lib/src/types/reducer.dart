typedef ReducerCallback = dynamic Function(
  dynamic value, [
  List<dynamic>? args,
]);

class Reducer {
  final int priority;
  final ReducerCallback callback;

  Reducer(this.callback, this.priority);
}
